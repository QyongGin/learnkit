package com.learnkit.backend.controller;


import com.learnkit.backend.domain.Schedule;
import com.learnkit.backend.dto.ScheduleCreateRequestDto;
import com.learnkit.backend.dto.ScheduleResponseDto;
import com.learnkit.backend.dto.ScheduleUpdateRequestDto;
import com.learnkit.backend.service.ScheduleService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController // REST API 컨트롤러임을 나타낸다.
@RequestMapping("/api") // 모든 메소드는 /api/users/{userId}/schedules 라는 공통 주소를 갖는다.
@RequiredArgsConstructor // final 필드에 대한 생성자 생성
public class ScheduleController {

    private final ScheduleService scheduleService; // 로직을 수행할 Service 가져오기

    @PostMapping("/users/{userId}/schedules") // HTTP POST 요청을 이 메소드와 매핑한다.
    public ResponseEntity<ScheduleResponseDto> createSchedule(@RequestBody ScheduleCreateRequestDto requestDto) {
        // @RequestBody: 클라이언트가 보낸 JSON 형태의 요청 데이터를 Dto 객체로 자동 변환해서 넣어달라 스프링에게 요청한다.
        // 1. Service를 호출하여 비즈니스 로직을 수행하고, 생성된 Schedule 객체를 받는다.
        Schedule createdSchedule = scheduleService.createSchedule(requestDto);

        // 2. Service로부터 받은 Domain 객체를 응답용 DTO로 변환한다.
        // ResponseEntity.ok()는 HTTP 상태 코드 200 (성공)을 의미한다.
        ScheduleResponseDto responseDto = new ScheduleResponseDto(createdSchedule);

        // 3. DTO를 담아서 클라이언트에게 반환한다.
        return ResponseEntity.ok(responseDto);
    }

    @GetMapping("/users/{userId}/schedules")
    public ResponseEntity<List<ScheduleResponseDto>> getSchedulesByUserId(@PathVariable Long userId) {
        // @PathVariable: 이름 그대로 경로의 변수 값을 가져오는 스프링 어노테이션.
        List<Schedule> schedules = scheduleService.findSchedulesByUserId(userId);
        // Service에서 받은 Domain 객체 리스트를 DTO 리스트로 변환
        List<ScheduleResponseDto> responseDtos = schedules.stream()
                .map(ScheduleResponseDto::new) // .map(schedule -> new ScheduleResponseDto(schedule)) 와 동일
                .toList();
        return ResponseEntity.ok(responseDtos);
    }

    @GetMapping("/schedules/{scheduleId}") // 처음에 사용자의 일정 목록을 보여주기 때문에 클라이언트는 스케줄 ID를 안다.
    public ResponseEntity<ScheduleResponseDto> getScheduleById(@PathVariable Long scheduleId) {
        Schedule schedule = scheduleService.findScheduleById(scheduleId);
        // Service에서 받은 Domain 객체를 응답용 DTO로 변환
        return ResponseEntity.ok(new ScheduleResponseDto(schedule));
    }


    @PatchMapping("/schedules/{scheduleId}")
    public ResponseEntity<ScheduleResponseDto> updateSchedule(@PathVariable Long scheduleId,
                                                              @RequestBody ScheduleUpdateRequestDto requestDto) {

        Schedule updatedSchedule = scheduleService.updateSchedule(scheduleId, requestDto);
        return ResponseEntity.ok(new ScheduleResponseDto(updatedSchedule));
    }

    @DeleteMapping("/schedules/{scheduleId}")
    public ResponseEntity<Void> deleteSchedule(@PathVariable Long scheduleId) {
        scheduleService.deleteSchedule(scheduleId);

        // 삭제 후에는 보낼만한 내용이 없기에 내용 없음을 의미하는 204 No Content 상태를 응답한다.
        return ResponseEntity.noContent().build();
    }

}
