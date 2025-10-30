package com.learnkit.backend.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * 단어장에 속한 개별 카드(단어)
 */
@Getter
@Entity
@Table(name = "cards")
@NoArgsConstructor
public class Card extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "wordbook_id", nullable = false)
    private WordBook wordBook;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String frontText;  // 앞면 텍스트 (질문/단어)

    @Column(nullable = false, columnDefinition = "TEXT")
    private String backText;   // 뒷면 텍스트 (답/뜻)

    @Column(nullable = false)
    private Long reviewPriority;  // 우선순위 점수 (작을수록 먼저)

    @Column
    private LocalDateTime lastReviewedAt;  // 마지막 복습 시간 (통계용)

    @Column(nullable = false)
    private int viewCount = 0;  // 조회 횟수

    @Enumerated(EnumType.STRING)
    private Difficulty difficulty;  // 난이도 (처음엔 null, 사용자가 선택 후 설정)

    // 난이도 Enum
    public enum Difficulty {
        EASY,
        NORMAL,
        HARD
    }

    /**
     * 카드 생성자 (초기 난이도 포함)
     *
     * @param frontText 앞면 텍스트 (질문/단어)
     * @param backText 뒷면 텍스트 (답/뜻)
     * @param difficulty 초기 난이도
     */
    public Card(String frontText, String backText, Difficulty difficulty) {
        this.frontText = frontText;
        this.backText = backText;
        this.difficulty = difficulty;
        this.reviewPriority = 0L;  // 기본값, 세션 시작 시 재계산
    }

    public void setWordBook(WordBook wordBook) {
        this.wordBook = wordBook;
    }

    /**
     * 카드 내용을 수정함.
     *
     * @param frontText 수정할 앞면 텍스트
     * @param backText 수정할 뒷면 텍스트
     * @param difficulty 수정할 난이도
     */
    public void update(String frontText, String backText, Difficulty difficulty) {
        if (frontText != null) {
            this.frontText = frontText;
        }
        if (backText != null) {
            this.backText = backText;
        }
        if (difficulty != null) {
            this.difficulty = difficulty;
        }
    }

    /**
     * 난이도를 선택하여 카드를 복습함.
     * 우선순위 점수를 업데이트하고, 복습 시간과 조회 수를 기록함.
     *
     * @param difficulty 사용자가 선택한 난이도
     * @param interval 해당 난이도의 interval 점수
     */
    public void reviewWithDifficulty(Difficulty difficulty, long interval) {
        this.difficulty = difficulty;
        this.lastReviewedAt = LocalDateTime.now();
        this.viewCount++;

        // 우선순위 점수 누적 (상대 점수 방식)
        this.reviewPriority += interval;
    }

    /**
     * 학습 세션 시작 시 카드의 우선순위를 리셋함.
     *
     * @param priority 설정할 우선순위 점수
     */
    public void resetReviewPriority(long priority) {
        this.reviewPriority = priority;
    }
}