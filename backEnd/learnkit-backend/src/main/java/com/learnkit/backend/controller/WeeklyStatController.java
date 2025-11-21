package com.learnkit.backend.controller;

import com.learnkit.backend.dto.WeeklyStatDto;
import com.learnkit.backend.service.WeeklyStatService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 주간 통계 관련 API 컨트롤러
 */
@RestController
@RequiredArgsConstructor
@RequestMapping("/api")
public class WeeklyStatController {

    private final WeeklyStatService weeklyStatService;

    /**
     * 주간 학습 정산 요약 조회
     * - 총 학습 시간 (분)
     * - 총 포모도로 수
     * - 총 학습 세션 수
     * - 목표 달성률
     *
     * @param userId 사용자 ID
     * @return 주간 정산 정보
     */
    @GetMapping("/users/{userId}/weekly-summary")
    public ResponseEntity<WeeklyStatDto.WeeklySummaryResponse> getWeeklySummary(@PathVariable Long userId) {
        WeeklyStatDto.WeeklySummaryResponse response = weeklyStatService.getWeeklySummary(userId);
        return ResponseEntity.ok(response);
    }
}