package com.learnkit.backend.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/**
 * 주간 통계 엔티티
 * 사용자의 주간 학습 성과 및 목표 달성률 저장
 */
@Entity
@Getter
@NoArgsConstructor // DB에서 데이터를 나르기 위한 빈 객체 생성기.
@Table(name = "weekly_stats")
public class WeeklyStat extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private int year;  // 연도 (예: 2025)

    @Column(nullable = false)
    private int month;  // 월 (1~12)

    @Column(name = "week_number", nullable = false)
    private int weekNumber;  // 월 기준 주차 (1~5)

    @Column(name = "achievement_rate")
    private Float achievementRate;  // 목표 달성률 (0.0 ~ 1.0)

    // 생성자
    public WeeklyStat(User user, int year, int month, int weekNumber) {
        this.user = user;
        this.year = year;
        this.month = month;
        this.weekNumber = weekNumber;
        this.achievementRate = 0.0f;
    }

    // 달성률 업데이트
    public void updateAchievementRate(float rate) {
        this.achievementRate = rate;
    }

    // 월 기준 주차 계산 헬퍼 메서드 (1~5)
    // 헬퍼 메서드: 메인 메서드가 너무 복잡해지지 않게 단순한 반복적 작업이나, 특정 계산 로직을 따로 떼서 만든 보조 메서드.
    // date.get(): 괄호 안 규칙에 맞는 값을 꺼낸다.
    // java.time.temporal: 날짜, 시간 객체 조작, 계산, 조회하는 패키지.
    // WeekFields.ISO.weekOfMonth(): 주 규칙(WeekFields)을 ISO(ISO표준)으로 사용하고 이 규칙을 가지고 해당 월의 몇 주차인지 계산
    public static int getWeekOfMonth(LocalDate date) {
        return date.get(java.time.temporal.WeekFields.ISO.weekOfMonth());
    }
}