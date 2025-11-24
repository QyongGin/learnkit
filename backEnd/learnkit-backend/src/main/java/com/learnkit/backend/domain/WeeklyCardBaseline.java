package com.learnkit.backend.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 주간 카드 기준선
 * 주 시작 시점의 난이도 분포를 저장하여 주간 변화 계산에 사용
 */
@Getter
@Entity
@Table(name = "weekly_card_baselines")
@NoArgsConstructor
public class WeeklyCardBaseline extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private int year;

    @Column(nullable = false)
    private int month;

    @Column(name = "week_number", nullable = false)
    private int weekNumber;

    @Column(name = "total_card_count", nullable = false)
    private int totalCardCount = 0;

    @Column(name = "hard_count", nullable = false)
    private int hardCount = 0;

    @Column(name = "normal_count", nullable = false)
    private int normalCount = 0;

    @Column(name = "easy_count", nullable = false)
    private int easyCount = 0;

    // 생성자
    public WeeklyCardBaseline(User user, int year, int month, int weekNumber,
                              int totalCardCount, int hardCount, int normalCount, int easyCount) {
        this.user = user;
        this.year = year;
        this.month = month;
        this.weekNumber = weekNumber;
        this.totalCardCount = totalCardCount;
        this.hardCount = hardCount;
        this.normalCount = normalCount;
        this.easyCount = easyCount;
    }
}