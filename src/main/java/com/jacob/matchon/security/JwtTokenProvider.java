package com.jacob.matchon.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

/** JWT 발급/검증 (jjwt 0.12.x). subject = userId. */
@Component
public class JwtTokenProvider {

	private final SecretKey key;
	private final long accessExpMs;

	public JwtTokenProvider(
			@Value("${app.jwt.secret}") String secret,
			@Value("${app.jwt.access-exp-min:43200}") long accessExpMin) {
		this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
		this.accessExpMs = accessExpMin * 60_000L;
	}

	/** userId + kakaoId 로 액세스 토큰 발급. kakaoId 를 함께 담아 id 재사용(DB 초기화) 시 토큰 무효화 */
	public String createToken(Long userId, String kakaoId) {
		Date now = new Date();
		return Jwts.builder()
				.subject(String.valueOf(userId))
				.claim("kid", kakaoId)
				.issuedAt(now)
				.expiration(new Date(now.getTime() + accessExpMs))
				.signWith(key)
				.compact();
	}

	private Claims parse(String token) {
		return Jwts.parser()
				.verifyWith(key)
				.build()
				.parseSignedClaims(token)
				.getPayload();
	}

	/** 토큰 → userId. 유효하지 않으면 null */
	public Long parseUserId(String token) {
		try {
			return Long.valueOf(parse(token).getSubject());
		} catch (Exception e) {
			return null;
		}
	}

	/** 토큰에 담긴 kakaoId(kid). 없거나 유효하지 않으면 null */
	public String parseKakaoId(String token) {
		try {
			return parse(token).get("kid", String.class);
		} catch (Exception e) {
			return null;
		}
	}
}
