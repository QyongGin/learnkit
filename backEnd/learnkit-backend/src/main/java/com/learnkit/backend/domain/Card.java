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
    private LocalDateTime nextReviewAt;  // 다음 복습 시간

    @Column
    private LocalDateTime lastReviewedAt;  // 마지막 복습 시간 (nullable)

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
     * 카드 생성자
     *
     * @param frontText 앞면 텍스트 (질문/단어)
     * @param backText 뒷면 텍스트 (답/뜻)
     */
    public Card(String frontText, String backText) {
        this.frontText = frontText;
        this.backText = backText;
        this.nextReviewAt = LocalDateTime.now();  // 생성 직후 바로 복습 가능
        // difficulty는 null로 시작 (사용자가 첫 복습 시 선택)
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
        this.nextReviewAt = LocalDateTime.now();
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
     * 복습 시간을 기록하고, 조회 수를 증가시키며, 다음 복습 시간을 계산함.
     *
     * @param difficulty 사용자가 선택한 난이도
     */
    public void reviewWithDifficulty(Difficulty difficulty) {
        this.difficulty = difficulty;
        this.lastReviewedAt = LocalDateTime.now();
        this.viewCount++;

        // 난이도에 따라 다음 복습 시간 계산
        int intervalMinutes = switch (difficulty) {
            case EASY -> wordBook.getEasyIntervalMinutes();
            case NORMAL -> wordBook.getNormalIntervalMinutes();
            case HARD -> wordBook.getHardIntervalMinutes();
        };

        this.nextReviewAt = LocalDateTime.now().plusMinutes(intervalMinutes);
    }
}