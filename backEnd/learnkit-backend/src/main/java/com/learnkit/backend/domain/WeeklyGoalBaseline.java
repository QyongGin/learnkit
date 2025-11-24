package com.learnkit.backend.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 주간 목표 기준선
 * 주 시작 시점의 각 목표 진행도를 저장하여 주간 변화 계산에 사용
 */
@Getter
@Entity
@Table(name = "weekly_goal_baselines")
@NoArgsConstructor
public class WeeklyGoalBaseline extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "goal_id", nullable = false)
    private Goal goal;

    @Column(nullable = false)
    private int year;

    @Column(nullable = false)
    private int month;

    @Column(name = "week_number", nullable = false)
    private int weekNumber;

    @Column(name = "start_amount", nullable = false)
    private int startAmount = 0;

    @Column(nullable = false, length = 50)
    private String unit;

    @Column(name = "goal_title", nullable = false)
    private String goalTitle;

    // 생성자
    public WeeklyGoalBaseline(User user, Goal goal, int year, int month, int weekNumber,
                              int startAmount, String unit, String goalTitle) {
        this.user = user;
        this.goal = goal;
        this.year = year;
        this.month = month;
        this.weekNumber = weekNumber;
        this.startAmount = startAmount;
        this.unit = unit;
        this.goalTitle = goalTitle;
    }
}