package com.learnkit.backend.controller;

import com.learnkit.backend.dto.WeeklyStatsDto;
import com.learnkit.backend.service.WeeklyStatsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * 주간 통계 컨트롤러
 * 여러 엔티티의 데이터를 통합하여 주간 통계 제공
 */
@RestController
@RequiredArgsConstructor
@RequestMapping("/api")
public class WeeklyStatsController {

    private final WeeklyStatsService weeklyStatsService;

    /**
     * 주간 통계 조회
     *
     * 포함 내용:
     * - 학습 시간 (포모도로 + 단어장)
     * - 카드 개선도 (주 시작 vs 현재)
     * - 목표별 진행도 (주 시작 vs 현재)
     */
    @GetMapping("/users/{userId}/weekly-stats")
    public ResponseEntity<WeeklyStatsDto.Response> getWeeklyStats(@PathVariable Long userId) {
        WeeklyStatsDto.Response stats = weeklyStatsService.getWeeklyStats(userId);
        return ResponseEntity.ok(stats);
    }

    /**
     * 주간 기준선 생성
     *
     * 이번 주 첫 실행 시 호출하여 기준선 생성
     * (AppLaunch, 첫 학습 시작 등에서 호출)
     */
    @PostMapping("/users/{userId}/weekly-stats/baseline")
    public ResponseEntity<Void> createWeeklyBaseline(@PathVariable Long userId) {
        weeklyStatsService.createWeeklyBaselinesIfNeeded(userId);
        return ResponseEntity.ok().build();
    }
}