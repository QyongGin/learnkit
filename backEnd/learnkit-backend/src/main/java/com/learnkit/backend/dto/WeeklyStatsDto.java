package com.learnkit.backend.dto;

import lombok.Getter;

import java.util.List;

/**
 * 주간 통계 통합 DTO
 * 여러 엔티티의 데이터를 모아서 한 번에 반환
 */
public class WeeklyStatsDto {

    /**
     * 주간 통계 응답 DTO
     */
    @Getter
    public static class Response {
        private final WeekInfo weekInfo;
        private final StudyTime studyTime;
        private final CardImprovement cardImprovement;
        private final List<GoalProgress> goalProgress;

        public Response(WeekInfo weekInfo, StudyTime studyTime,
                       CardImprovement cardImprovement, List<GoalProgress> goalProgress) {
            this.weekInfo = weekInfo;
            this.studyTime = studyTime;
            this.cardImprovement = cardImprovement;
            this.goalProgress = goalProgress;
        }
    }

    /**
     * 주차 정보
     */
    @Getter
    public static class WeekInfo {
        private final int year;
        private final int month;
        private final int weekNumber;

        public WeekInfo(int year, int month, int weekNumber) {
            this.year = year;
            this.month = month;
            this.weekNumber = weekNumber;
        }
    }

    /**
     * 학습 시간 통계
     */
    @Getter
    public static class StudyTime {
        private final int pomodoroMinutes;    // 포모도로 학습 시간
        private final int wordBookMinutes;    // 단어장 학습 시간
        private final int totalMinutes;       // 총 학습 시간

        public StudyTime(int pomodoroMinutes, int wordBookMinutes) {
            this.pomodoroMinutes = pomodoroMinutes;
            this.wordBookMinutes = wordBookMinutes;
            this.totalMinutes = pomodoroMinutes + wordBookMinutes;
        }
    }

    /**
     * 카드 개선도
     */
    @Getter
    public static class CardImprovement {
        private final DifficultyCount weekStart;   // 주 시작 시점
        private final DifficultyCount current;     // 현재 시점
        private final DifficultyChange changes;    // 변화량

        public CardImprovement(DifficultyCount weekStart, DifficultyCount current) {
            this.weekStart = weekStart;
            this.current = current;
            this.changes = new DifficultyChange(
                current.getHard() - weekStart.getHard(),
                current.getNormal() - weekStart.getNormal(),
                current.getEasy() - weekStart.getEasy()
            );
        }
    }

    /**
     * 난이도별 카드 수
     */
    @Getter
    public static class DifficultyCount {
        private final int hard;
        private final int normal;
        private final int easy;

        public DifficultyCount(int hard, int normal, int easy) {
            this.hard = hard;
            this.normal = normal;
            this.easy = easy;
        }
    }

    /**
     * 난이도 변화량
     */
    @Getter
    public static class DifficultyChange {
        private final int hard;     // 음수면 감소(개선)
        private final int normal;
        private final int easy;     // 양수면 증가(개선)

        public DifficultyChange(int hard, int normal, int easy) {
            this.hard = hard;
            this.normal = normal;
            this.easy = easy;
        }
    }

    /**
     * 목표별 진행도
     */
    @Getter
    public static class GoalProgress {
        private final Integer goalId;
        private final String goalTitle;
        private final int startAmount;      // 주 시작 진행도
        private final int currentAmount;    // 현재 진행도
        private final int change;           // 변화량
        private final String unit;          // 단위 (장, 문제, 페이지 등)

        public GoalProgress(Integer goalId, String goalTitle, int startAmount,
                           int currentAmount, String unit) {
            this.goalId = goalId;
            this.goalTitle = goalTitle;
            this.startAmount = startAmount;
            this.currentAmount = currentAmount;
            this.change = currentAmount - startAmount;
            this.unit = unit;
        }
    }
}