package com.learnkit.backend.controller;

import com.learnkit.backend.dto.AppLaunchDto;
import com.learnkit.backend.service.AppLaunchService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * 앱 실행 기록 및 사용 패턴 분석 API 컨트롤러
 */
@RestController
@RequiredArgsConstructor
@RequestMapping("/api")
public class AppLaunchController {

    private final AppLaunchService appLaunchService;

    /**
     * 앱 실행 시간 기록
     * 사용자의 앱 실행 시간을 타임스탬프로 기록
     * 사용 패턴 분석 및 리마인더 발송 시간 최적화에 활용
     *
     * @param userId 사용자 ID
     * @return 성공 응답 (201 Created)
     */
    @PostMapping("/users/{userId}/app-launches")
    public ResponseEntity<Void> recordAppLaunch(@PathVariable Long userId) {
        appLaunchService.recordAppLaunch(userId);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    /**
     * 주 사용 시간대 조회
     * 최근 30일간의 앱 실행 패턴을 분석하여 가장 많이 사용하는 시간대 반환
     * 리마인더 발송 시간 추천 기능 제공
     *
     * @param userId 사용자 ID
     * @return 피크 시간대 정보 및 추천 알림 시간
     */
    @GetMapping("/users/{userId}/peak-hours")
    public ResponseEntity<AppLaunchDto.PeakHoursResponse> getPeakHours(@PathVariable Long userId) {
        AppLaunchDto.PeakHoursResponse response = appLaunchService.calculatePeakHours(userId);
        return ResponseEntity.ok(response);
    }
}