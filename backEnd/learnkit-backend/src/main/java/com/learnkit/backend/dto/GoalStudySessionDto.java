package com.learnkit.backend.dto;

import com.learnkit.backend.domain.GoalStudySession;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * GoalStudySession(목표 학습 세션) 관련 DTO들을 관리하는 클래스
 */
public class GoalStudySessionDto {

    /**
     * 학습 세션 시작 요청 DTO
     */
    @Getter
    @Setter
    @NoArgsConstructor
    public static class StartRequest {
        private Integer goalId; // 목표 ID (nullable)
    }

    /**
     * 학습 세션 종료 요청 DTO
     */
    @Getter
    @Setter
    @NoArgsConstructor
    public static class EndRequest {
        private Integer achievedAmount; // 달성량
        private Integer pomoCount; // 완료한 포모도로 횟수
        private String note; // 메모
    }

    /**
     * 학습 세션 응답 DTO
     */
    @Getter
    public static class Response {
        private final Integer id;
        private final Integer goalId;
        private final String goalTitle;
        private final LocalDateTime startedAt;
        private final LocalDateTime endedAt;
        private final int achievedAmount;
        private final int durationMinutes; // pomoCount * 25
        private final int pomoCount;
        private final String note;
        private final boolean inProgress;

        public Response(GoalStudySession session) {
            this.id = session.getId();
            this.goalId = session.getGoal() != null ? session.getGoal().getId() : null;
            this.goalTitle = session.getGoal() != null ? session.getGoal().getTitle() : null;
            this.startedAt = session.getStartedAt();
            this.endedAt = session.getEndedAt();
            this.achievedAmount = session.getAchievedAmount();
            this.durationMinutes = session.getDurationMinutes();
            this.pomoCount = session.getPomoCount();
            this.note = session.getNote();
            this.inProgress = session.isInProgress();
        }
    }

    /**
     * 학습 통계 응답 DTO
     */
    @Getter
    public static class StatisticsResponse {
        private final int totalSessions;
        private final int totalMinutes;
        private final int totalPomoCount;
        private final int totalAchievedAmount;

        public StatisticsResponse(int totalSessions, int totalMinutes, int totalPomoCount, int totalAchievedAmount) {
            this.totalSessions = totalSessions;
            this.totalMinutes = totalMinutes;
            this.totalPomoCount = totalPomoCount;
            this.totalAchievedAmount = totalAchievedAmount;
        }
    }
}