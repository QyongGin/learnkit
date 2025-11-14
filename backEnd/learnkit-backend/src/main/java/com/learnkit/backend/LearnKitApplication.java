package com.learnkit.backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@EnableJpaAuditing // JPA Auditing 기능 활성화
@SpringBootApplication
public class LearnKitApplication {

	public static void main(String[] args) {
		SpringApplication.run(LearnKitApplication.class, args);
	}

}
