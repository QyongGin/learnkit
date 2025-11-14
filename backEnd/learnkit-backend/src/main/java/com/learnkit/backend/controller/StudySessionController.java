package com.learnkit.backend.controller;

import com.learnkit.backend.dto.StudySessionDto;
import com.learnkit.backend.service.StudySessionService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api")
public class StudySessionController {

    private final StudySessionService studySessionService;

    /**
     * 학습 세션 시작
     */
    @PostMapping("/users/{userId}/study-sessions")
    public ResponseEntity<StudySessionDto.Response> startSession(
            @PathVariable Long userId,
            @RequestBody StudySessionDto.StartRequest requestDto) {
        StudySessionDto.Response response = studySessionService.startSession(userId, requestDto);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * 학습 세션 종료
     */
    @PatchMapping("/study-sessions/{sessionId}/end")
    public ResponseEntity<StudySessionDto.Response> endSession(
            @PathVariable Long sessionId,
            @RequestBody StudySessionDto.EndRequest requestDto) {
        StudySessionDto.Response response = studySessionService.endSession(sessionId, requestDto);
        return ResponseEntity.ok(response);
    }

    /**
     * 특정 사용자의 모든 학습 세션 조회
     */
    @GetMapping("/users/{userId}/study-sessions")
    public ResponseEntity<List<StudySessionDto.Response>> getSessionsByUser(@PathVariable Long userId) {
        List<StudySessionDto.Response> sessions = studySessionService.findSessionsByUserId(userId);
        return ResponseEntity.ok(sessions);
    }

    /**
     * 진행 중인 세션 조회
     */
    @GetMapping("/users/{userId}/study-sessions/active")
    public ResponseEntity<StudySessionDto.Response> getActiveSession(@PathVariable Long userId) {
        StudySessionDto.Response session = studySessionService.findActiveSession(userId);
        return ResponseEntity.ok(session);
    }

    /**
     * 세션 상세 조회
     */
    @GetMapping("/study-sessions/{sessionId}")
    public ResponseEntity<StudySessionDto.Response> getSession(@PathVariable Long sessionId) {
        StudySessionDto.Response session = studySessionService.findSessionById(sessionId);
        return ResponseEntity.ok(session);
    }

    /**
     * 세션 삭제
     */
    @DeleteMapping("/study-sessions/{sessionId}")
    public ResponseEntity<Void> deleteSession(@PathVariable Long sessionId) {
        studySessionService.deleteSession(sessionId);
        return ResponseEntity.noContent().build();
    }

    /**
     * 학습 통계 조회 (특정 기간)
     */
    @GetMapping("/users/{userId}/study-sessions/statistics")
    public ResponseEntity<StudySessionDto.StatisticsResponse> getStatistics(
            @PathVariable Long userId,
            // RequestParam에서 URL의 ?start= 파라미터를 받아옴 ?start=2025-01-01T00:00:00
            // @DateTimeFormat URL 파라미터 2025-01-01...을 변환시킨다.
            // ISO.DATE_TIME 포맷은 ISO 8601 날짜 형식으로 YYYY-MM-DDTHH:mm:ss 형식이다.
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime start,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime end) {
        StudySessionDto.StatisticsResponse statistics = studySessionService.getStatistics(userId, start, end);
        return ResponseEntity.ok(statistics);
    }

    /**
     * 특정 목표에 연결된 학습 세션 조회
     */
    @GetMapping("/study-sessions")
    public ResponseEntity<List<StudySessionDto.Response>> getSessionsByGoal(
            @RequestParam Long goalId) {
        List<StudySessionDto.Response> sessions = studySessionService.findSessionsByGoalId(goalId);
        return ResponseEntity.ok(sessions);
    }

    /**
     * 진행 중인 세션의 포모도로 카운트 실시간 업데이트
     * 포모도로 세트 수를 기반으로 경과 시간도 자동 계산됨 (1세트 = 25분)
     */
    @PatchMapping("/study-sessions/{sessionId}/pomo-count")
    public ResponseEntity<StudySessionDto.Response> updatePomoCount(
            @PathVariable Long sessionId,
            @RequestParam int pomoCount) {
        StudySessionDto.Response response = studySessionService.updatePomoCount(sessionId, pomoCount);
        return ResponseEntity.ok(response);
    }
}