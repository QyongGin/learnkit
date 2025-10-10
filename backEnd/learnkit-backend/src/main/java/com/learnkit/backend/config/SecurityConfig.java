package com.learnkit.backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;

@Configuration // 이 클래스가 Spring 설정 클래스임을 알린다.
@EnableWebSecurity // Spring Security를 활성화한다.
public class SecurityConfig {

    // PasswordEncoder를 Spring Bean으로 등록
    // @Bean: 이 메서드가 반환하는 객체를 Spring이 관리하는 빈으로 등록한다.
    // BCryptPasswordEncoder: 비밀번호를 안전하게 암호화하는 알고리즘
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    // Spring Security 설정
    // SecurityFilterChain: Spring Security의 보안 필터 체인을 설정
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                // CSRF 보호 비활성화 (REST API에서는 보통 비활성화)
                .csrf(csrf -> csrf.disable())

                // 모든 요청에 대해 인증 없이 접근 허용 (개발 단계)
                // 실제 운영 환경에서는 보안 설정을 강화해야 함
                .authorizeHttpRequests(auth -> auth
                        .anyRequest().permitAll()
                );

        return http.build();
    }
}