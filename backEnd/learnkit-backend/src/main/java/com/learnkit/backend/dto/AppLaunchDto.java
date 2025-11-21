package com.learnkit.backend.dto;

import lombok.Getter;

import java.time.LocalDateTime;

/**
 * AppLaunch 관련 DTO들을 관리하는 클래스
 */
public class AppLaunchDto {

    /**
     * 주 사용 시간대 분석 응답 DTO
     * GET /api/users/{userId}/peak-hours
     */
    @Getter
    public static class PeakHoursResponse {
        private final int peakHour;                         // 가장 많이 사용하는 시간 (0~23)
        private final int launchCount;                      // 해당 시간대 앱 실행 횟수
        private final LocalDateTime suggestedReminderTime;  // 추천 알림 시간 (피크 시간 1시간 전)

        public PeakHoursResponse(int peakHour, int launchCount, LocalDateTime suggestedReminderTime) {
            this.peakHour = peakHour;
            this.launchCount = launchCount;
            this.suggestedReminderTime = suggestedReminderTime;
        }
    }
}