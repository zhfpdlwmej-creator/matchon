package com.jacob.matchon.web;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.Map;

/** /api/** 의 예외를 JSON 으로 변환. */
@RestControllerAdvice(basePackages = "com.jacob.matchon.web")
public class ApiExceptionHandler {

	@ExceptionHandler(ApiException.class)
	public ResponseEntity<Map<String, Object>> handleApi(ApiException e) {
		return ResponseEntity.status(e.getStatus())
				.body(Map.of("ok", false, "message", e.getMessage()));
	}

	@ExceptionHandler(IllegalArgumentException.class)
	public ResponseEntity<Map<String, Object>> handleIllegal(IllegalArgumentException e) {
		return ResponseEntity.badRequest()
				.body(Map.of("ok", false, "message", e.getMessage()));
	}

	@ExceptionHandler(Exception.class)
	public ResponseEntity<Map<String, Object>> handleEtc(Exception e) {
		return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
				.body(Map.of("ok", false, "message", "서버 오류가 발생했습니다."));
	}
}
