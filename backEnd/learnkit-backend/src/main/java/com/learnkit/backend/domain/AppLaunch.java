package com.learnkit.backend.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * 앱 실행 기록 엔티티
 * 사용자의 앱 사용 패턴 분석을 위한 데이터 수집
 */
@Entity
@Getter
@NoArgsConstructor
@Table(name = "app_launches")
public class AppLaunch {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "launch_time", nullable = false)
    private LocalDateTime launchTime;

    // 생성자
    public AppLaunch(User user) {
        this.user = user;
        this.launchTime = LocalDateTime.now(); // 앱 실행 시 생성하여 앱 시작 시간을 저장.
    }
}