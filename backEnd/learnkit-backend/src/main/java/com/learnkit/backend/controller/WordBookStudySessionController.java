package com.learnkit.backend.controller;

import com.learnkit.backend.dto.WordBookStudySessionDto;
import com.learnkit.backend.service.WordBookStudySessionService;
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
public class WordBookStudySessionController {

    private final WordBookStudySessionService wordBookStudySessionService;

    /**
     * 단어장 학습 세션 시작
     */
    @PostMapping("/users/{userId}/wordbook-study-sessions")
    public ResponseEntity<WordBookStudySessionDto.Response> startSession(
            @PathVariable Long userId,
            @RequestBody WordBookStudySessionDto.StartRequest requestDto) {
        WordBookStudySessionDto.Response response = wordBookStudySessionService.startSession(userId, requestDto);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * 단어장 학습 세션 종료
     */
    @PatchMapping("/wordbook-study-sessions/{sessionId}/end")
    public ResponseEntity<WordBookStudySessionDto.Response> endSession(
            @PathVariable Integer sessionId,
            @RequestBody WordBookStudySessionDto.EndRequest requestDto) {
        WordBookStudySessionDto.Response response = wordBookStudySessionService.endSession(sessionId, requestDto);
        return ResponseEntity.ok(response);
    }

    /**
     * 특정 사용자의 모든 단어장 학습 세션 조회
     */
    @GetMapping("/users/{userId}/wordbook-study-sessions")
    public ResponseEntity<List<WordBookStudySessionDto.Response>> getSessionsByUser(@PathVariable Long userId) {
        List<WordBookStudySessionDto.Response> sessions = wordBookStudySessionService.findSessionsByUserId(userId);
        return ResponseEntity.ok(sessions);
    }

    /**
     * 진행 중인 세션 조회
     */
    @GetMapping("/users/{userId}/wordbook-study-sessions/active")
    public ResponseEntity<WordBookStudySessionDto.Response> getActiveSession(@PathVariable Long userId) {
        WordBookStudySessionDto.Response session = wordBookStudySessionService.findActiveSession(userId);
        return ResponseEntity.ok(session);
    }

    /**
     * 세션 상세 조회
     */
    @GetMapping("/wordbook-study-sessions/{sessionId}")
    public ResponseEntity<WordBookStudySessionDto.Response> getSession(@PathVariable Integer sessionId) {
        WordBookStudySessionDto.Response session = wordBookStudySessionService.findSessionById(sessionId);
        return ResponseEntity.ok(session);
    }

    /**
     * 세션 삭제
     */
    @DeleteMapping("/wordbook-study-sessions/{sessionId}")
    public ResponseEntity<Void> deleteSession(@PathVariable Integer sessionId) {
        wordBookStudySessionService.deleteSession(sessionId);
        return ResponseEntity.noContent().build();
    }

    /**
     * 단어장 학습 통계 조회 (특정 기간)
     */
    @GetMapping("/users/{userId}/wordbook-study-sessions/statistics")
    public ResponseEntity<WordBookStudySessionDto.StatisticsResponse> getStatistics(
            @PathVariable Long userId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime start,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime end) {
        WordBookStudySessionDto.StatisticsResponse statistics = wordBookStudySessionService.getStatistics(userId, start, end);
        return ResponseEntity.ok(statistics);
    }

    /**
     * 특정 단어장에 연결된 학습 세션 조회
     */
    @GetMapping("/wordbook-study-sessions")
    public ResponseEntity<List<WordBookStudySessionDto.Response>> getSessionsByWordBook(
            @RequestParam Long wordBookId) {
        List<WordBookStudySessionDto.Response> sessions = wordBookStudySessionService.findSessionsByWordBookId(wordBookId);
        return ResponseEntity.ok(sessions);
    }
}