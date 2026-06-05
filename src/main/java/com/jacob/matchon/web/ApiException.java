package com.jacob.matchon.web;

/** 비즈니스 예외. status 코드와 사용자 메시지를 담는다. */
public class ApiException extends RuntimeException {
	private final int status;

	public ApiException(int status, String message) {
		super(message);
		this.status = status;
	}

	public int getStatus() {
		return status;
	}
}
