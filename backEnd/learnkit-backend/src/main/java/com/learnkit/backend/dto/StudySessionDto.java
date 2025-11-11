package com.learnkit.backend.dto;

import com.learnkit.backend.domain.StudySession;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * StudySession(학습 세션) 관련 DTO들을 관리하는 클래스
 */
public class StudySessionDto {

    /**
     * 학습 세션 시작 요청 DTO
     * POST
     * /api/users/{userId}/study-sessions
     */
    @Getter
    @Setter
    @NoArgsConstructor
    public static class StartRequest {
        private Long goalId; // 목표 ID (nullable)
    }

    /**
     * 학습 세션 종료 요청 DTO
     * PATCH
     * /api/study-sessions/{sessionId}/end
     */
    @Getter
    @Setter
    @NoArgsConstructor
    public static class EndRequest{
        private Integer achievedAmount; // 달성량
        private Integer durationMinutes; // 학습 시간
        private Integer pomoCount; // 완료한 포모도로 횟수
        private String note; // 메모 (세계사 30% 완료.)
    }

    /**
     * 학습 세션 응답 DTO
     */
    @Getter
    public static class Response {
        private final Long id;
        private final Long goalId;
        private final String goalTitle;          // 목표 제목(편의성)
        private final LocalDateTime startedAt;
        private final LocalDateTime endedAt;
        private final int achievedAmount;
        private final int durationMinutes;
        private final int pomoCount;
        private final String note;
        private final boolean inProgress;        // 진행 중 여부

        public Response(StudySession session) {
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
     * GET
     * /api/users/{userID}/study-sessions/statistics
     */
    @Getter
    public static class StatisticsResponse {
        private final int totalSessions; // 총 세션(기록) 수
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
