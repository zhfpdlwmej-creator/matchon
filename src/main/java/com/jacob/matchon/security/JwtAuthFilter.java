package com.jacob.matchon.security;

import com.jacob.matchon.repo.UserRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.AuthorityUtils;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * 매 요청마다 ACCESS_TOKEN 쿠키(또는 Authorization: Bearer)를 읽어
 * 유효하면 SecurityContext 에 userId 를 principal 로 인증을 채운다.
 */
public class JwtAuthFilter extends OncePerRequestFilter {

	public static final String COOKIE_NAME = "ACCESS_TOKEN";

	private final JwtTokenProvider jwt;
	private final UserRepository userRepo;

	public JwtAuthFilter(JwtTokenProvider jwt, UserRepository userRepo) {
		this.jwt = jwt;
		this.userRepo = userRepo;
	}

	@Override
	protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
			throws ServletException, IOException {
		String token = resolveToken(req);
		if (token != null) {
			Long userId = jwt.parseUserId(token);
			if (userId != null && SecurityContextHolder.getContext().getAuthentication() == null) {
				if (userRepo.existsById(userId)) {
					var auth = new UsernamePasswordAuthenticationToken(
							userId, null, AuthorityUtils.createAuthorityList("ROLE_USER"));
					SecurityContextHolder.getContext().setAuthentication(auth);
					req.setAttribute("uid", userId);
				} else {
					// 토큰은 유효하지만 유저가 없음(DB 초기화 등) → 쿠키 제거하고 비로그인 처리
					expireCookie(res);
				}
			}
		}
		chain.doFilter(req, res);
	}

	private void expireCookie(HttpServletResponse res) {
		Cookie c = new Cookie(COOKIE_NAME, "");
		c.setPath("/");
		c.setMaxAge(0);
		c.setHttpOnly(true);
		res.addCookie(c);
	}

	private String resolveToken(HttpServletRequest req) {
		if (req.getCookies() != null) {
			for (Cookie c : req.getCookies()) {
				if (COOKIE_NAME.equals(c.getName())) {
					return c.getValue();
				}
			}
		}
		String h = req.getHeader("Authorization");
		if (h != null && h.startsWith("Bearer ")) {
			return h.substring(7);
		}
		return null;
	}
}
