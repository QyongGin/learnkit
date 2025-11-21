package com.learnkit.backend.controller;

import com.learnkit.backend.dto.ReminderDto;
import com.learnkit.backend.service.ReminderService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 리마인더 관련 API 컨트롤러
 */
@RestController
@RequiredArgsConstructor
@RequestMapping("/api")
public class ReminderController {

    private final ReminderService reminderService;

    /**
     * 리마인더 생성
     *
     * @param userId 사용자 ID
     * @param requestDto 리마인더 정보 (메시지, 알림 시간)
     * @return 생성된 리마인더 정보
     */
    @PostMapping("/users/{userId}/reminders")
    public ResponseEntity<ReminderDto.Response> createReminder(
            @PathVariable Long userId,
            @RequestBody ReminderDto.CreateRequest requestDto) {
        ReminderDto.Response response = reminderService.createReminder(userId, requestDto);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * 사용자의 모든 리마인더 조회
     *
     * @param userId 사용자 ID
     * @return 리마인더 목록
     */
    @GetMapping("/users/{userId}/reminders")
    public ResponseEntity<List<ReminderDto.Response>> getUserReminders(@PathVariable Long userId) {
        List<ReminderDto.Response> reminders = reminderService.getUserReminders(userId);
        return ResponseEntity.ok(reminders);
    }

    /**
     * 다가오는 리마인더 조회 (다음 7일 이내)
     *
     * @param userId 사용자 ID
     * @return 예정된 리마인더 목록
     */
    @GetMapping("/users/{userId}/reminders/upcoming")
    public ResponseEntity<List<ReminderDto.Response>> getUpcomingReminders(@PathVariable Long userId) {
        List<ReminderDto.Response> reminders = reminderService.getUpcomingReminders(userId);
        return ResponseEntity.ok(reminders);
    }

    /**
     * 리마인더 수정
     * PATCH 요청으로 메시지나 알림 시간 수정
     *
     * @param reminderId 리마인더 ID
     * @param requestDto 수정할 정보 (null이 아닌 필드만 수정됨)
     * @return 수정된 리마인더 정보
     */
    @PatchMapping("/reminders/{reminderId}")
    public ResponseEntity<ReminderDto.Response> updateReminder(
            @PathVariable Integer reminderId,
            @RequestBody ReminderDto.UpdateRequest requestDto) {
        ReminderDto.Response response = reminderService.updateReminder(reminderId, requestDto);
        return ResponseEntity.ok(response);
    }

    /**
     * 리마인더 삭제
     *
     * @param reminderId 리마인더 ID
     * @return 성공 응답 (204 No Content)
     */
    @DeleteMapping("/reminders/{reminderId}")
    public ResponseEntity<Void> deleteReminder(@PathVariable Integer reminderId) {
        reminderService.deleteReminder(reminderId);
        return ResponseEntity.noContent().build();
    }
}