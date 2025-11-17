package com.learnkit.backend.dto;


import com.learnkit.backend.domain.Goal;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Goal(목표) 관련 DTO들을 관리하는 클래스
 */
public class GoalDto {

    /**
     * 목표 생성 요청 DTO
     * POST /api/users/{userId}/goals
     */
    @Getter
    @Setter
    @NoArgsConstructor
    public static class CreateRequest {
        private String title;
        private LocalDate startDate; // nullable = true
        private LocalDate endDate; // nullable = true
        private Integer totalTargetAmount;
        private String targetUnit;

        public Goal toEntity() {
            return new Goal(this.title, this.startDate, this.endDate, this.totalTargetAmount, this.targetUnit);
        }
    }

    /**
     * 목표 수정 요청 DTO
     * PATCH /api/goals/{goalId}
     */
    @Getter
    @Setter
    @NoArgsConstructor
    public static class UpdateRequest {
        private String title;
        private LocalDate startDate;
        private LocalDate endDate;
        private Integer totalTargetAmount;
        private String targetUnit;
    }

    /**
     * 진행도 추가 요청 DTO
     * PATCH /api/goals/{goalId}/progress
     */
    @Getter
    @Setter
    @NoArgsConstructor
    public static class AddProgressRequest{
        private Integer amount;
    }

    /**
     * 목표 응답 DTO
     * 목표의 기본 정보 + 진행 상태 포함
     */
    @Getter
    public static class Response {
        private final Integer id;
        private final String title;
        private final LocalDate startDate;
        private final LocalDate endDate;
        private final int totalTargetAmount;
        private final String targetUnit;
        private final int currentProgress;
        private final boolean isCompleted;
        private final LocalDateTime completedAt;
        // 최소 권한 원칙
        // API 응답은 클라이언트가 반드시 필요한 데이터만.
        // Entity의 모든 필드를 노출하면 보안 위험 + 성능 저하

        public Response(Goal goal) {
            this.id = goal.getId();
            this.title = goal.getTitle();
            this.startDate = goal.getStartDate();
            this.endDate = goal.getEndDate();
            this.totalTargetAmount = goal.getTotalTargetAmount();
            this.targetUnit = goal.getTargetUnit();
            this.currentProgress = goal.getCurrentProgress();
            this.isCompleted = goal.isCompleted();
            this.completedAt = goal.getCompletedAt();
        }

    }
}
