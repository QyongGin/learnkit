package com.learnkit.backend.dto;

import com.learnkit.backend.domain.Schedule;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
public class ScheduleResponseDto {

    private final Long id;
    private final Long userId;
    private final String title;
    private final String description;
    private final LocalDateTime startTime;
    private final LocalDateTime endTime;
    private final boolean isCompleted;
    private final LocalDateTime createdAt;
    private final LocalDateTime updatedAt;

    public ScheduleResponseDto(Schedule schedule) {
        this.id = schedule.getId();
        this.userId = schedule.getUserId();
        this.title = schedule.getTitle();
        this.description = schedule.getDescription();
        this.startTime = schedule.getStartTime();
        this.endTime = schedule.getEndTime();
        this.isCompleted = schedule.isCompleted();
        this.createdAt = schedule.getCreatedAt();
        this.updatedAt = schedule.getUpdatedAt();
    }
}
