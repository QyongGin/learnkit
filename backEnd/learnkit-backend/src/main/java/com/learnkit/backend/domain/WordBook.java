package com.learnkit.backend.domain;


import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;


/**
 * 하나의 주제로 여러 단어(카드)가 모인 단어장
 */
@Getter
@Entity
@Table(name="wordbooks")
@NoArgsConstructor
public class WordBook extends BaseTimeEntity{

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;

    @Column(nullable = false)
    private String title;

    @Column(length = 500)
    private String description;  // 단어장 설명 (선택사항)

    // 빈도 비율 (EASY를 1번 볼 때 각 난이도를 몇 번 보는지)
    @Column(nullable = false)
    private int hardFrequencyRatio = 6;    // 기본: EASY의 6배

    @Column(nullable = false)
    private int normalFrequencyRatio = 3;  // 기본: EASY의 3배

    @Column(nullable = false)
    private int easyFrequencyRatio = 1;    // 기본: 기준값

    // 제약 조건 상수
    private static final int MIN_HARD_RATIO = 3;
    private static final int MIN_NORMAL_RATIO = 2;
    private static final int MIN_EASY_RATIO = 1;
    private static final int MAX_RATIO = 20;

    // baseScore 계산용 배율
    private static final int BASE_SCORE_MULTIPLIER = 1000;

    /**
     * 단어장 생성자
     */
    public WordBook(String title) {
        this.title = title;
        // 기본값은 필드 선언에서 설정됨 (6:3:1)
    }

    /**
     * 단어장 생성자 (설명 포함)
     */
    public WordBook(String title, String description) {
        this.title = title;
        this.description = description;
        // 기본값은 필드 선언에서 설정됨 (6:3:1)
    }

    /**
     * 빈도 비율 설정 생성자
     */
    public WordBook(String title, int hardFrequencyRatio, int normalFrequencyRatio, int easyFrequencyRatio) {
        this.title = title;
        validateAndSetFrequencyRatios(hardFrequencyRatio, normalFrequencyRatio, easyFrequencyRatio);
    }

    /**
     * 빈도 비율 설정 생성자 (설명 포함)
     */
    public WordBook(String title, String description, int hardFrequencyRatio, int normalFrequencyRatio, int easyFrequencyRatio) {
        this.title = title;
        this.description = description;
        validateAndSetFrequencyRatios(hardFrequencyRatio, normalFrequencyRatio, easyFrequencyRatio);
    }

    public void setUser(User user){
        this.user = user;
    }

    /**
     * 단어장 정보 업데이트
     */
    public void update(String title, String description, Integer hardFrequencyRatio, Integer normalFrequencyRatio, Integer easyFrequencyRatio) {
        if (title != null) {
            this.title = title;
        }
        if (description != null) {
            this.description = description;
        }
        if (hardFrequencyRatio != null && normalFrequencyRatio != null && easyFrequencyRatio != null) {
            validateAndSetFrequencyRatios(hardFrequencyRatio, normalFrequencyRatio, easyFrequencyRatio);
        }
    }

    /**
     * 빈도 비율 검증 및 설정
     * 규칙: hard > normal > easy (엄격한 부등호)
     *
     * @throws IllegalArgumentException 비율이 유효하지 않은 경우
     */
    private void validateAndSetFrequencyRatios(int hard, int normal, int easy) {
        // 1. 최소값 검증
        if (hard < MIN_HARD_RATIO) {
            throw new IllegalArgumentException("어려움 빈도는 최소 " + MIN_HARD_RATIO + "배 이상이어야 합니다.");
        }
        if (normal < MIN_NORMAL_RATIO) {
            throw new IllegalArgumentException("보통 빈도는 최소 " + MIN_NORMAL_RATIO + "배 이상이어야 합니다.");
        }
        if (easy < MIN_EASY_RATIO) {
            throw new IllegalArgumentException("쉬움 빈도는 최소 " + MIN_EASY_RATIO + "배 이상이어야 합니다.");
        }

        // 2. 최대값 검증
        if (hard > MAX_RATIO || normal > MAX_RATIO || easy > MAX_RATIO) {
            throw new IllegalArgumentException("빈도는 최대 " + MAX_RATIO + "배까지 설정할 수 있습니다.");
        }

        // 3. 순서 검증 (엄격한 부등호: HARD > NORMAL > EASY)
        if (hard <= normal || normal <= easy) {
            throw new IllegalArgumentException(
                "빈도는 어려움 > 보통 > 쉬움 순서여야 합니다. " +
                "(현재: " + hard + ":" + normal + ":" + easy + ")"
            );
        }

        // 4. 저장
        this.hardFrequencyRatio = hard;
        this.normalFrequencyRatio = normal;
        this.easyFrequencyRatio = easy;
    }

    /**
     * 총 카드 수 기반 baseScore 계산
     */
    public long calculateBaseScore(int totalCards) {
        return (long) totalCards * BASE_SCORE_MULTIPLIER;
    }

    /**
     * HARD 난이도의 interval 계산
     */
    public long calculateHardInterval(long baseScore) {
        return baseScore / hardFrequencyRatio;
    }

    /**
     * NORMAL 난이도의 interval 계산
     */
    public long calculateNormalInterval(long baseScore) {
        return baseScore / normalFrequencyRatio;
    }

    /**
     * EASY 난이도의 interval 계산
     */
    public long calculateEasyInterval(long baseScore) {
        return baseScore / easyFrequencyRatio;
    }
}
