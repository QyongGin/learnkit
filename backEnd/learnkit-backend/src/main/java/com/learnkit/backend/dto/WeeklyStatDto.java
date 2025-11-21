package com.learnkit.backend.dto;

import lombok.Getter;

/**
 * WeeklyStat 관련 DTO들을 관리하는 클래스
 */
public class WeeklyStatDto {

        /**
         * 주간 정산 응답 DTO
         * GET
         * /api/users/{userId}/weekly-summary
         */
        @Getter
        public static class WeeklySummaryResponse {
            private final int year;
            private final int month;
            private final int weekNumber; // 월 기준 주차 (1~5)
            private final int totalMinutes; // 총 학습 시간 (분)
            private final int totalPomoCount;
            private final int totalSessions;
            private final float achievementRate; // 목표 달성률 (0.0 ~ 1.0)

            /**
             * 주간 정산 응답 생성자
             *
             * @param year 연도
             * @param month 월
             * @param weekNumber 월 기준 주차
             * @param totalMinutes 총 학습 시간
             * @param totalPomoCount 총 포모도로 수
             * @param totalSessions 총 학습 세션 수
             * @param achievementRate 목표 달성률
             */
            public WeeklySummaryResponse(int year, int month, int weekNumber, int totalMinutes, int totalPomoCount,
                                         int totalSessions, float achievementRate) {
                this.year = year;
                this.month = month;
                this.weekNumber = weekNumber;
                this.totalMinutes = totalMinutes;
                this.totalPomoCount = totalPomoCount;
                this.totalSessions = totalSessions;
                this.achievementRate = achievementRate;
            }
        }
    }

