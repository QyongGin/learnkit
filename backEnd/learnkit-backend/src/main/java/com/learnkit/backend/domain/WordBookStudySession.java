package com.learnkit.backend.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;

/**
 * 단어장 학습 세션 기록
 * 시작~종료 시간과 난이도 변화를 추적함
 */
@Getter
@Entity
@Table(name = "wordbook_study_sessions")
@NoArgsConstructor
public class WordBookStudySession extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "wordbook_id", nullable = false)
    private WordBook wordBook;

    @Column(nullable = false)
    private LocalDateTime startedAt;

    private LocalDateTime endedAt;

    // 시작 시점 난이도 분포
    @Column(nullable = false)
    private int startHardCount = 0;

    @Column(nullable = false)
    private int startNormalCount = 0;

    @Column(nullable = false)
    private int startEasyCount = 0;

    // 종료 시점 난이도 분포
    @Column(nullable = false)
    private int endHardCount = 0;

    @Column(nullable = false)
    private int endNormalCount = 0;

    @Column(nullable = false)
    private int endEasyCount = 0;

    // 생성자
    public WordBookStudySession(User user, WordBook wordBook, int hardCount, int normalCount, int easyCount) {
        this.user = user;
        this.wordBook = wordBook;
        this.startedAt = LocalDateTime.now();
        this.startHardCount = hardCount;
        this.startNormalCount = normalCount;
        this.startEasyCount = easyCount;
    }

    // 세션 종료
    public void endSession(int hardCount, int normalCount, int easyCount) {
        if (!isInProgress()) {
            throw new IllegalStateException("이미 종료된 세션입니다.");
        }

        this.endedAt = LocalDateTime.now();
        this.endHardCount = hardCount;
        this.endNormalCount = normalCount;
        this.endEasyCount = easyCount;
    }

    /**
     * 진행 중인 세션 여부
     */
    public boolean isInProgress() {
        return this.endedAt == null;
    }

    /**
     * 학습 시간 계산 (분)
     */
    public int getDurationMinutes() {
        if (this.endedAt == null) {
            return 0;
        }
        return (int) ChronoUnit.MINUTES.between(this.startedAt, this.endedAt);
    }
}