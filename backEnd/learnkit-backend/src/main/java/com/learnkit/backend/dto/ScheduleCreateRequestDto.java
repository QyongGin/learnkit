package com.learnkit.backend.dto;

import com.learnkit.backend.domain.Schedule;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter // Controller에서 요청 데이터를 DTO 객체로 변환할 때 필요하다.
public class ScheduleCreateRequestDto {

    // JSON의 키(key) 목록
    private String title;
    private String description;
    private LocalDateTime startTime;
    private LocalDateTime endTime;

    // DTO 객체를 Domain(Entity) 객체로 변환하는 메소드
    public Schedule toEntity() {
        return new Schedule(
                this.title,
                this.description,
                this.startTime,
                this.endTime
        );
    }
}
