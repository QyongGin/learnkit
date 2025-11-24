package com.learnkit.backend.dto;

import com.learnkit.backend.domain.WordBookStudySession;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * WordBookStudySession(단어장 학습 세션) 관련 DTO들을 관리하는 클래스
 */
public class WordBookStudySessionDto {

    /**
     * 단어장 학습 세션 시작 요청 DTO
     */
    @Getter
    @Setter
    @NoArgsConstructor
    public static class StartRequest {
        private Long wordBookId;
        private int hardCount;
        private int normalCount;
        private int easyCount;
    }

    /**
     * 단어장 학습 세션 종료 요청 DTO
     */
    @Getter
    @Setter
    @NoArgsConstructor
    public static class EndRequest {
        private int hardCount;
        private int normalCount;
        private int easyCount;
    }

    /**
     * 단어장 학습 세션 응답 DTO
     */
    @Getter
    public static class Response {
        private final Integer id;
        private final Long wordBookId;
        private final String wordBookTitle;
        private final LocalDateTime startedAt;
        private final LocalDateTime endedAt;
        private final int startHardCount;
        private final int startNormalCount;
        private final int startEasyCount;
        private final int endHardCount;
        private final int endNormalCount;
        private final int endEasyCount;
        private final int durationMinutes;
        private final boolean inProgress;

        public Response(WordBookStudySession session) {
            this.id = session.getId();
            this.wordBookId = session.getWordBook().getId();
            this.wordBookTitle = session.getWordBook().getTitle();
            this.startedAt = session.getStartedAt();
            this.endedAt = session.getEndedAt();
            this.startHardCount = session.getStartHardCount();
            this.startNormalCount = session.getStartNormalCount();
            this.startEasyCount = session.getStartEasyCount();
            this.endHardCount = session.getEndHardCount();
            this.endNormalCount = session.getEndNormalCount();
            this.endEasyCount = session.getEndEasyCount();
            this.durationMinutes = session.getDurationMinutes();
            this.inProgress = session.isInProgress();
        }
    }

    /**
     * 단어장 학습 통계 응답 DTO
     */
    @Getter
    public static class StatisticsResponse {
        private final int totalSessions;
        private final int totalMinutes;
        private final int hardImprovement; // 어려움 감소량
        private final int easyIncrease; // 쉬움 증가량

        public StatisticsResponse(int totalSessions, int totalMinutes, int hardImprovement, int easyIncrease) {
            this.totalSessions = totalSessions;
            this.totalMinutes = totalMinutes;
            this.hardImprovement = hardImprovement;
            this.easyIncrease = easyIncrease;
        }
    }
}