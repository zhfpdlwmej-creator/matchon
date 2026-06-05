package com.jacob.matchon;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * matchon — 축구·풋살 동호회 출석 관리 보조 서비스.
 * 카카오톡을 대체하지 않고, 출석/일정/알림만 편하게 보조한다.
 */
@EnableScheduling
@SpringBootApplication
public class MatchonApplication {

	public static void main(String[] args) {
		SpringApplication.run(MatchonApplication.class, args);
	}
}
