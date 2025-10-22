package com.learnkit.backend.dto;

import com.learnkit.backend.domain.Card;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Card(카드/단어) 관련 DTO들을 관리하는 클래스
 */
public class CardDto {

    /**
     * 카드 생성 요청 DTO
     * <p>POST /api/wordbooks/{wordbookId}/cards</p>
     */
    @Getter
    @Setter
    @NoArgsConstructor
    public static class CreateRequest {
        private String frontText;  // 앞면 (질문/단어)
        private String backText;   // 뒷면 (답/뜻)
        private Card.Difficulty difficulty;  // 초기 난이도 (선택사항, null 가능)

        public Card toEntity() {
            if (difficulty != null) {
                return new Card(this.frontText, this.backText, this.difficulty);
            }
            return new Card(this.frontText, this.backText);
        }
    }

    /**
     * 카드 내용 수정 요청 DTO
     * <p>PATCH /api/cards/{cardId}</p>
     */
    @Getter
    @Setter
    @NoArgsConstructor
    public static class UpdateRequest {
        private String frontText;
        private String backText;
        private Card.Difficulty difficulty;  // 난이도 수정 (선택사항, null 가능)
    }

    /**
     * 카드 난이도 선택(복습) 요청 DTO
     * <p>PATCH /api/cards/{cardId}/review</p>
     */
    @Getter
    @Setter
    @NoArgsConstructor
    public static class ReviewRequest {
        private Card.Difficulty difficulty;  // EASY, NORMAL, HARD
    }

    /**
     * 카드 응답 DTO (학습용)
     * <p>
     * 실제로 프론트엔드가 필요한 정보만 노출.
     * 수정/삭제를 위한 id는 포함하되, 내부 구조(wordbookId 등)는 숨김.
     * </p>
     */
    @Getter
    public static class Response {
        private final Long id;              // 수정/삭제 시 필요
        private final String frontText;     // 질문/단어
        private final String backText;      // 답/뜻
        private final LocalDateTime nextReviewAt;  // 다음 복습 시간 (UI 표시용)
        private final Card.Difficulty difficulty;  // 현재 난이도 (UI 표시용)

        public Response(Card card) {
            this.id = card.getId();
            this.frontText = card.getFrontText();
            this.backText = card.getBackText();
            this.nextReviewAt = card.getNextReviewAt();
            this.difficulty = card.getDifficulty();
        }
    }

    /**
     * 카드 상세 응답 DTO (통계/관리용)
     * <p>
     * 관리자 페이지나 통계 화면에서 사용.
     * 학습 기록, 조회 수 등 상세 정보 포함.
     * </p>
     */
    @Getter
    public static class DetailResponse {
        private final Long id;
        private final String frontText;
        private final String backText;
        private final LocalDateTime nextReviewAt;
        private final LocalDateTime lastReviewedAt;  // 마지막 복습 시간
        private final int viewCount;                 // 조회 횟수
        private final Card.Difficulty difficulty;
        private final LocalDateTime createdAt;       // 생성 시간
        private final LocalDateTime updatedAt;       // 수정 시간

        public DetailResponse(Card card) {
            this.id = card.getId();
            this.frontText = card.getFrontText();
            this.backText = card.getBackText();
            this.nextReviewAt = card.getNextReviewAt();
            this.lastReviewedAt = card.getLastReviewedAt();
            this.viewCount = card.getViewCount();
            this.difficulty = card.getDifficulty();
            this.createdAt = card.getCreatedAt();
            this.updatedAt = card.getUpdatedAt();
        }
    }

    /**
     * 난이도별 카드 통계 응답 DTO (홈 화면용)
     * <p>
     * 사용자의 전체 카드를 난이도별로 집계한 통계를 제공.
     * </p>
     */
    @Getter
    public static class StatisticsResponse {
        private final long easyCount;       // 쉬움
        private final long normalCount;     // 보통
        private final long hardCount;       // 어려움
        private final long totalCount;      // 전체 카드 수

        public StatisticsResponse(long easyCount, long normalCount, long hardCount) {
            this.easyCount = easyCount;
            this.normalCount = normalCount;
            this.hardCount = hardCount;
            this.totalCount = easyCount + normalCount + hardCount;
        }
    }

    /**
     * 단어장별 카드 통계 DTO (단어장 목록용)
     * <p>
     * 단어장 ID, 이름과 함께 해당 단어장의 카드 통계를 제공.
     * </p>
     */
    @Getter
    public static class WordBookStatistics {
        private final Long wordBookId;
        private final String wordBookName;
        private final long easyCount;
        private final long normalCount;
        private final long hardCount;
        private final long totalCount;

        public WordBookStatistics(Long wordBookId, String wordBookName, long easyCount, long normalCount, long hardCount) {
            this.wordBookId = wordBookId;
            this.wordBookName = wordBookName;
            this.easyCount = easyCount;
            this.normalCount = normalCount;
            this.hardCount = hardCount;
            this.totalCount = easyCount + normalCount + hardCount;
        }
    }

    /**
     * 사용자의 모든 단어장 카드 통계 배치 응답 DTO
     * <p>
     * 한 번의 API 호출로 모든 단어장의 통계를 조회.
     * N+1 문제 해결용.
     * </p>
     */
    @Getter
    public static class BatchStatisticsResponse {
        private final List<WordBookStatistics> wordbooks;

        public BatchStatisticsResponse(List<WordBookStatistics> wordbooks) {
            this.wordbooks = wordbooks;
        }
    }
}