package com.learnkit.backend.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * 포모도로 타이머를 사용한 학습 세션 기록
 * 각 세션은 특정 목표(Goal)에 연결되며, 진행도와 학습 시간을 추적함
 */
@Getter
@Entity
@Table(name = "study_sessions")
@NoArgsConstructor
public class StudySession extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "goal_id")
    private Goal goal;  // nullable (목표 없이 학습 가능)

    @Column(nullable = false)
    private LocalDateTime startedAt;    // 시작 시간

    private LocalDateTime endedAt;      // 종료 시간 (NULL = 진행 중)

    @Column(nullable = false)
    private int achievedAmount = 0;     // 이번 세션 달성량

    @Column(nullable = false)
    private int durationMinutes = 0;    // 학습 시간 (분)

    @Column(nullable = false)
    private int pomoCount = 0;          // 완료한 포모도로 수

    @Column(columnDefinition = "TEXT")
    private String note;                // 메모

    // 생성자
    public StudySession(User user, Goal goal) {
        this.user = user;
        this.goal = goal;
        this.startedAt = LocalDateTime.now();
    }


    // 세션 종료
    public void endSession(int achievedAmount, int durationMinutes, int pomoCount, String note) {
        if (!isInProgress()) {
            throw new IllegalStateException("이미 종료된 세션입니다.");
        }

        this.endedAt = LocalDateTime.now();
        this.achievedAmount = achievedAmount;
        this.durationMinutes = durationMinutes;
        this.pomoCount = pomoCount;
        this.note = note;
    }

    /**
     * 포모도로 카운트 실시간 업데이트 (진행 중인 세션에만 사용)
     * 앱 강제 종료 시에도 진행 상황을 보존하기 위해 사용
     * 포모도로 세트 수를 기반으로 경과 시간도 자동 계산 (1세트 = 25분)
     */
    public void updatePomoCount(int pomoCount) {
        if (!isInProgress()) {
            throw new IllegalStateException("종료된 세션은 업데이트할 수 없습니다.");
        }
        this.pomoCount = pomoCount;
        // 포모도로 세트 수 기반으로 경과 시간 자동 계산 (1세트 = 25분)
        this.durationMinutes = pomoCount * 25;
    }

    /**
     * 진행 중인 세션 여부
     */
    public boolean isInProgress() {
        return this.endedAt == null;
    }
}