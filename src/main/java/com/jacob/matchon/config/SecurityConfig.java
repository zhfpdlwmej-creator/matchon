package com.jacob.matchon.config;

import com.jacob.matchon.repo.UserRepository;
import com.jacob.matchon.security.JwtAuthFilter;
import com.jacob.matchon.security.JwtTokenProvider;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityCustomizer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

/**
 * JWT 기반 무상태(stateless) 인증.
 * - 정적 리소스/로그인/카카오 콜백은 공개
 * - 그 외는 JwtAuthFilter 가 채운 인증으로 접근 제어(컨트롤러 단에서 CurrentUser 로 재확인)
 * - JSP 폼은 거의 없고 REST 위주라 CSRF 비활성(JWT 쿠키는 SameSite=Lax 로 보호)
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

	private final JwtTokenProvider jwt;
	private final UserRepository userRepo;

	public SecurityConfig(JwtTokenProvider jwt, UserRepository userRepo) {
		this.jwt = jwt;
		this.userRepo = userRepo;
	}

	/** 정적 리소스는 보안 필터 체인에서 제외 → no-store 헤더 없이 브라우저 캐싱 허용(속도) */
	@Bean
	public WebSecurityCustomizer webSecurityCustomizer() {
		return web -> web.ignoring().requestMatchers(
				"/css/**", "/js/**", "/img/**", "/icons/**",
				"/favicon.ico", "/manifest.webmanifest", "/sw.js");
	}

	@Bean
	public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
		http
				.csrf(c -> c.disable())
				.formLogin(f -> f.disable())
				.httpBasic(h -> h.disable())
				.logout(l -> l.disable())
				.sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
				.authorizeHttpRequests(a -> a
						.requestMatchers(
								"/", "/login", "/welcome",
								"/auth/**",
								"/css/**", "/js/**", "/img/**",
								"/favicon.ico", "/error",
								"/api/me")
						.permitAll()
						.anyRequest().permitAll())  // 세부 인가는 컨트롤러에서 CurrentUser 로 처리
				.addFilterBefore(new JwtAuthFilter(jwt, userRepo), UsernamePasswordAuthenticationFilter.class)
				.headers(h -> h.frameOptions(f -> f.sameOrigin()));
		return http.build();
	}
}
