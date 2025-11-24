package com.learnkit.backend.controller;

import com.learnkit.backend.dto.GoalStudySessionDto;
import com.learnkit.backend.service.GoalStudySessionService;
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
public class GoalStudySessionController {

    private final GoalStudySessionService goalStudySessionService;

    /**
     * 학습 세션 시작
     */
    @PostMapping("/users/{userId}/goal-study-sessions")
    public ResponseEntity<GoalStudySessionDto.Response> startSession(
            @PathVariable Long userId,
            @RequestBody GoalStudySessionDto.StartRequest requestDto) {
        GoalStudySessionDto.Response response = goalStudySessionService.startSession(userId, requestDto);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * 학습 세션 종료
     */
    @PatchMapping("/goal-study-sessions/{sessionId}/end")
    public ResponseEntity<GoalStudySessionDto.Response> endSession(
            @PathVariable Integer sessionId,
            @RequestBody GoalStudySessionDto.EndRequest requestDto) {
        GoalStudySessionDto.Response response = goalStudySessionService.endSession(sessionId, requestDto);
        return ResponseEntity.ok(response);
    }

    /**
     * 특정 사용자의 모든 학습 세션 조회
     */
    @GetMapping("/users/{userId}/goal-study-sessions")
    public ResponseEntity<List<GoalStudySessionDto.Response>> getSessionsByUser(@PathVariable Long userId) {
        List<GoalStudySessionDto.Response> sessions = goalStudySessionService.findSessionsByUserId(userId);
        return ResponseEntity.ok(sessions);
    }

    /**
     * 진행 중인 세션 조회
     */
    @GetMapping("/users/{userId}/goal-study-sessions/active")
    public ResponseEntity<GoalStudySessionDto.Response> getActiveSession(@PathVariable Long userId) {
        GoalStudySessionDto.Response session = goalStudySessionService.findActiveSession(userId);
        return ResponseEntity.ok(session);
    }

    /**
     * 세션 상세 조회
     */
    @GetMapping("/goal-study-sessions/{sessionId}")
    public ResponseEntity<GoalStudySessionDto.Response> getSession(@PathVariable Integer sessionId) {
        GoalStudySessionDto.Response session = goalStudySessionService.findSessionById(sessionId);
        return ResponseEntity.ok(session);
    }

    /**
     * 세션 삭제
     */
    @DeleteMapping("/goal-study-sessions/{sessionId}")
    public ResponseEntity<Void> deleteSession(@PathVariable Integer sessionId) {
        goalStudySessionService.deleteSession(sessionId);
        return ResponseEntity.noContent().build();
    }

    /**
     * 학습 통계 조회 (특정 기간)
     */
    @GetMapping("/users/{userId}/goal-study-sessions/statistics")
    public ResponseEntity<GoalStudySessionDto.StatisticsResponse> getStatistics(
            @PathVariable Long userId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime start,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime end) {
        GoalStudySessionDto.StatisticsResponse statistics = goalStudySessionService.getStatistics(userId, start, end);
        return ResponseEntity.ok(statistics);
    }

    /**
     * 특정 목표에 연결된 학습 세션 조회
     */
    @GetMapping("/goal-study-sessions")
    public ResponseEntity<List<GoalStudySessionDto.Response>> getSessionsByGoal(
            @RequestParam Integer goalId) {
        List<GoalStudySessionDto.Response> sessions = goalStudySessionService.findSessionsByGoalId(goalId);
        return ResponseEntity.ok(sessions);
    }

    /**
     * 진행 중인 세션의 포모도로 카운트 실시간 업데이트
     */
    @PatchMapping("/goal-study-sessions/{sessionId}/pomo-count")
    public ResponseEntity<GoalStudySessionDto.Response> updatePomoCount(
            @PathVariable Integer sessionId,
            @RequestParam int pomoCount) {
        GoalStudySessionDto.Response response = goalStudySessionService.updatePomoCount(sessionId, pomoCount);
        return ResponseEntity.ok(response);
    }
}