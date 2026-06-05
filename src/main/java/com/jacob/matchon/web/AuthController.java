package com.jacob.matchon.web;

import com.jacob.matchon.model.Position;
import com.jacob.matchon.model.User;
import com.jacob.matchon.security.JwtAuthFilter;
import com.jacob.matchon.security.JwtTokenProvider;
import com.jacob.matchon.service.UserService;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Controller;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.client.RestTemplate;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Map;

/**
 * 카카오 OAuth 로그인 → 자체 JWT 발급(쿠키).
 * rest-api-key 미설정 시 dev mock 로그인으로 폴백.
 */
@Controller
@RequiredArgsConstructor
public class AuthController {

	private static final Logger log = LoggerFactory.getLogger(AuthController.class);

	private static final String AUTHORIZE_URL = "https://kauth.kakao.com/oauth/authorize";
	private static final String TOKEN_URL = "https://kauth.kakao.com/oauth/token";
	private static final String USER_INFO_URL = "https://kapi.kakao.com/v2/user/me";

	private final UserService userService;
	private final JwtTokenProvider jwt;
	private final RestTemplate http = new RestTemplate();

	@Value("${app.kakao.rest-api-key:}")
	private String restKey;
	@Value("${app.kakao.redirect-uri:}")
	private String redirectUri;
	@Value("${app.kakao.client-secret:}")
	private String clientSecret;

	@GetMapping("/auth/kakao")
	public String start() {
		if (restKey == null || restKey.isEmpty()) {
			// dev 폴백: 키 미설정 시 mock 로그인 페이지(콜백)로 바로 보냄
			return "redirect:/auth/kakao/callback?mock=1";
		}
		String url = AUTHORIZE_URL
				+ "?response_type=code"
				+ "&client_id=" + enc(restKey)
				+ "&redirect_uri=" + enc(redirectUri);
		return "redirect:" + url;
	}

	@GetMapping("/auth/kakao/callback")
	public String callback(
			@RequestParam(required = false) String code,
			@RequestParam(required = false) String error,
			@RequestParam(required = false) String mock,
			HttpServletResponse res) {

		// dev mock 로그인
		if ((restKey == null || restKey.isEmpty()) && mock != null) {
			return mockLogin(res);
		}
		if (error != null) {
			return "redirect:/login?err=" + enc(error);
		}
		if (code == null || code.isEmpty()) {
			return "redirect:/login?err=no_code";
		}
		try {
			// 1) 인가코드 → 액세스 토큰
			MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
			form.add("grant_type", "authorization_code");
			form.add("client_id", restKey);
			form.add("redirect_uri", redirectUri);
			form.add("code", code);
			if (clientSecret != null && !clientSecret.isEmpty()) {
				form.add("client_secret", clientSecret);
			}
			HttpHeaders th = new HttpHeaders();
			th.setContentType(new MediaType("application", "x-www-form-urlencoded", StandardCharsets.UTF_8));
			ResponseEntity<Map> tokenRes = http.postForEntity(TOKEN_URL, new HttpEntity<>(form, th), Map.class);
			Object at = tokenRes.getBody() == null ? null : tokenRes.getBody().get("access_token");
			if (at == null) {
				return "redirect:/login?err=token_failed";
			}

			// 2) 액세스 토큰 → 프로필
			HttpHeaders ph = new HttpHeaders();
			ph.setBearerAuth(String.valueOf(at));
			ResponseEntity<Map> meRes = http.exchange(USER_INFO_URL, HttpMethod.GET, new HttpEntity<>(ph), Map.class);
			Map body = meRes.getBody();
			if (body == null || body.get("id") == null) {
				return "redirect:/login?err=profile_failed";
			}
			String kakaoId = String.valueOf(body.get("id"));
			String nick = extractNickname(body);

			// 3) 유저 매칭/생성 + 카카오 실명 동기화
			User user = userService.findByKakaoId(kakaoId)
					.orElseGet(() -> userService.createFromKakao(kakaoId, nick));
			userService.syncName(user.getId(), nick);

			issueToken(res, user.getId());
			return "redirect:/";

		} catch (Exception e) {
			log.error("Kakao OAuth callback failed", e);
			return "redirect:/login?err=oauth_failed";
		}
	}

	@GetMapping("/auth/logout")
	public String logout(HttpServletResponse res) {
		Cookie c = new Cookie(JwtAuthFilter.COOKIE_NAME, "");
		c.setPath("/");
		c.setMaxAge(0);
		c.setHttpOnly(true);
		res.addCookie(c);
		return "redirect:/login";
	}

	// --- helpers ---

	private String mockLogin(HttpServletResponse res) {
		String[] names = {"손흥민", "이강인", "김민재", "황희찬", "조규성", "박지성"};
		String kakaoId = "mock_" + Math.abs(names.hashCode() % 100000 + (int) (System.nanoTime() % 100000));
		String nick = names[(int) (System.nanoTime() % names.length)];
		User u = userService.findByKakaoId(kakaoId)
				.orElseGet(() -> userService.createFromKakao(kakaoId, nick));
		issueToken(res, u.getId());
		return "redirect:/";
	}

	private void issueToken(HttpServletResponse res, Long userId) {
		String token = jwt.createToken(userId);
		Cookie c = new Cookie(JwtAuthFilter.COOKIE_NAME, token);
		c.setPath("/");
		c.setHttpOnly(true);
		c.setMaxAge(60 * 60 * 24 * 30); // 30일
		res.addCookie(c);
	}

	@SuppressWarnings("unchecked")
	private String extractNickname(Map body) {
		Object account = body.get("kakao_account");
		if (account instanceof Map<?, ?> acc) {
			Object profile = acc.get("profile");
			if (profile instanceof Map<?, ?> p) {
				Object n = p.get("nickname");
				if (n != null) {
					String s = String.valueOf(n).trim();
					return s.length() > 20 ? s.substring(0, 20) : s;
				}
			}
		}
		return "축구인";
	}

	private static String enc(String s) {
		return URLEncoder.encode(s, StandardCharsets.UTF_8);
	}

	// Position 파라미터 변환은 컨트롤러 외부 매핑에서 사용
	static Position parsePosition(String v) {
		try {
			return v == null || v.isBlank() ? null : Position.valueOf(v);
		} catch (Exception e) {
			return null;
		}
	}
}
