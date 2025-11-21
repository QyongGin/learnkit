package com.learnkit.backend.dto;

import com.learnkit.backend.domain.Reminder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * Reminder 관련 DTO들을 관리하는 클래스
 */
public class ReminderDto {

    /**
     * 리마인더 생성 요청 DTO
     * POST /api/users/{userId}/reminders
     */
    @Getter
    @Setter
    @NoArgsConstructor
    public static class CreateRequest {
        private Long scheduleId;  // 연결할 스케줄 ID
        private String message;
        private LocalDateTime notificationTime;
    }

    /**
     * 리마인더 수정 요청 DTO
     * PATCH /api/users/{userId}/reminders/{reminderId}
     */
    @Getter
    @Setter
    @NoArgsConstructor
    public static class UpdateRequest {
        private String message;                 // 수정할 메시지 (null이면 수정 안 함)
        private LocalDateTime notificationTime; // 수정할 알림 시간 (null이면 수정 안 함)
    }

    /**
     * 리마인더 응답 DTO
     */
    @Getter
    public static class Response {
        private final Integer id;
        private final Long scheduleId;
        private final String message;
        private final LocalDateTime notificationTime;
        private final LocalDateTime createdAt;

        public Response(Reminder reminder) {
            this.id = reminder.getId();
            this.scheduleId = reminder.getSchedule() != null ? reminder.getSchedule().getId() : null;
            this.message = reminder.getMessage();
            this.notificationTime = reminder.getNotificationTime();
            this.createdAt = reminder.getCreatedAt();
        }
    }

}