package com.jacob.matchon.security;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

/** SecurityContext 에서 현재 로그인 userId 를 꺼내는 헬퍼. */
public final class CurrentUser {

	private CurrentUser() {}

	/** 로그인 userId, 비로그인 null */
	public static Long id() {
		Authentication auth = SecurityContextHolder.getContext().getAuthentication();
		if (auth != null && auth.getPrincipal() instanceof Long uid) {
			return uid;
		}
		return null;
	}

	/** 로그인 필수 — 아니면 예외 */
	public static Long required() {
		Long id = id();
		if (id == null) {
			throw new com.jacob.matchon.web.ApiException(401, "로그인이 필요합니다.");
		}
		return id;
	}
}
