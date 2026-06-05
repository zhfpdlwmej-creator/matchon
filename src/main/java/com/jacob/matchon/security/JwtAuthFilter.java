package com.jacob.matchon.security;

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

	public JwtAuthFilter(JwtTokenProvider jwt) {
		this.jwt = jwt;
	}

	@Override
	protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
			throws ServletException, IOException {
		String token = resolveToken(req);
		if (token != null) {
			Long userId = jwt.parseUserId(token);
			if (userId != null && SecurityContextHolder.getContext().getAuthentication() == null) {
				var auth = new UsernamePasswordAuthenticationToken(
						userId, null, AuthorityUtils.createAuthorityList("ROLE_USER"));
				SecurityContextHolder.getContext().setAuthentication(auth);
				req.setAttribute("uid", userId);
			}
		}
		chain.doFilter(req, res);
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
