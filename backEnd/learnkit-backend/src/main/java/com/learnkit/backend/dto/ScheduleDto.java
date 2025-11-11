package com.learnkit.backend.dto;

import com.learnkit.backend.domain.Schedule;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.time.LocalDateTime;

/**
 * Schedule(일정) 관련 DTO들을 관리하는 클래스
 * 여러 클래스를 품은 하나의 큰 클래스
 */
public class ScheduleDto {

    /**
     * [요청용] 일정 생성을 위한 DTO
     */
    @Getter
    @Setter
    @NoArgsConstructor // Jackson이 JSON을 객체로 변환할 때 필요한 기본 생성자를 자동으로 생성
    public static class CreateRequest {
        private String title;
        private String description;
        private LocalDateTime startTime;
        private LocalDateTime endTime;

        public Schedule toEntity() {
            return new Schedule(
                    this.title,
                    this.description,
                    this.startTime,
                    this.endTime
            );
        }
    }

    /**
     * [요청용] 일정 수정을 위한 DTO
     */
    @Getter
    @Setter
    @NoArgsConstructor
    public static class UpdateRequest {
        private String title;
        private String description;
        private LocalDateTime startTime;
        private LocalDateTime endTime;
        private Boolean isCompleted;
    }

    /**
     * [응답용] 응답을 위한 DTO
     */
    @Getter
    public static class Response {
        private final Long id;
        private final String title;
        private final String description;
        private final LocalDateTime startTime;
        private final LocalDateTime endTime;
        private final boolean isCompleted;

        public Response(Schedule schedule) {
            this.id = schedule.getId();
            this.title = schedule.getTitle();
            this.description = schedule.getDescription();
            this.startTime = schedule.getStartTime();
            this.endTime = schedule.getEndTime();
            this.isCompleted = schedule.isCompleted();
        }
    }
}