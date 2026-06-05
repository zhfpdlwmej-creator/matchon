package com.jacob.matchon.web;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ModelAttribute;

/** 모든 JSP 화면에 카카오 JS 키를 공통 주입 (카카오 공유 SDK 용). */
@ControllerAdvice
public class GlobalModelAttributes {

	@Value("${app.kakao.javascript-key:}")
	private String kakaoJsKey;

	@ModelAttribute("kakaoJsKey")
	public String kakaoJsKey() {
		return kakaoJsKey == null ? "" : kakaoJsKey;
	}
}
