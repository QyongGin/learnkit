package com.learnkit.backend.controller;


import com.learnkit.backend.dto.ScheduleDto;
import com.learnkit.backend.service.ScheduleService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;



// 클라이언트가 HTTP 요청을 보내면 Spring 서버가 @RestController가 붙은 UserController에서 이 요청을 처리할 메서드를 찾는다.
// 메서드는 Dto 객체를 생성해서 반환한다. @RestController 덕분에 Spring은 Dto 객체를 HTML로 바꾸지 않고 JSON 데이터로 자동 변환하여 클라이언트에게 응답한다.

@RestController // REST API 컨트롤러임을 Spring에게 알려서 메서드가 반환하는건 클라이언트에게 전달할 데이터라고 알린다.
@RequestMapping("/api") // 모든 메소드는 /api 라는 공통 주소를 갖는다.
@RequiredArgsConstructor // final 필드에 대한 생성자 생성
public class ScheduleController {

    private final ScheduleService scheduleService; // 로직을 수행할 Service 가져오기

    @PostMapping("/users/{userId}/schedules")
    public ResponseEntity<ScheduleDto.Response> createSchedule(@PathVariable Long userId, @RequestBody ScheduleDto.CreateRequest requestDto) {
        ScheduleDto.Response responseDto = scheduleService.createSchedule(userId,requestDto);
        return ResponseEntity.status(HttpStatus.CREATED).body(responseDto); // ResponseEntity: HTTP 응답 전체를 담는 덩어리(Entity)
    }

    @GetMapping("/users/{userId}/schedules")
    public ResponseEntity<List<ScheduleDto.Response>> getSchedulesByUserId(@PathVariable Long userId) {
        List<ScheduleDto.Response> responseDtos = scheduleService.findSchedulesByUserId(userId);
        return ResponseEntity.ok(responseDtos);
    }

    // 일정 상세 조회
    @GetMapping("/schedules/{scheduleId}")
    public ResponseEntity<ScheduleDto.Response> getScheduleById(@PathVariable Long scheduleId) {
        ScheduleDto.Response responseDto = scheduleService.findScheduleById(scheduleId);
        return ResponseEntity.ok(responseDto);
    }

    // 일정 갱신
    @PatchMapping("/schedules/{scheduleId}")
    public ResponseEntity<ScheduleDto.Response> updateSchedule(@PathVariable Long scheduleId,
                                                              @RequestBody ScheduleDto.UpdateRequest requestDto) {
        ScheduleDto.Response responseDto = scheduleService.updateSchedule(scheduleId, requestDto);
        return ResponseEntity.ok(responseDto);
    }

    // 일정 삭제
    @DeleteMapping("/schedules/{scheduleId}")
    public ResponseEntity<Void> deleteSchedule(@PathVariable Long scheduleId) {
        scheduleService.deleteSchedule(scheduleId);
        // 삭제 후에는 보낼만한 내용이 없기에 내용 없음을 의미하는 204 No Content 상태를 응답한다.
        return ResponseEntity.noContent().build();
    }

}
