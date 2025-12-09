package com.learnkit.backend.service;

import com.learnkit.backend.domain.*;
import com.learnkit.backend.dto.WeeklyStatsDto;
import com.learnkit.backend.repository.*;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.TemporalAdjusters;
import java.time.temporal.WeekFields;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 주간 통계 서비스
 * 여러 엔티티의 데이터를 모아서 주간 통계를 생성
 */
@Service
@RequiredArgsConstructor
@Transactional
public class WeeklyStatsService {

    private final GoalStudySessionRepository goalStudySessionRepository;
    private final WordBookStudySessionRepository wordBookStudySessionRepository;
    private final WeeklyCardBaselineRepository weeklyCardBaselineRepository;
    private final WeeklyGoalBaselineRepository weeklyGoalBaselineRepository;
    private final CardRepository cardRepository;
    private final GoalRepository goalRepository;
    private final UserRepository userRepository;

    /**
     * 주간 통계 조회
     * 이번 주 학습 데이터를 모아서 반환
     */
    public WeeklyStatsDto.Response getWeeklyStats(Long userId) {
        LocalDate today = LocalDate.now();

        // 주차 정보 계산
        int year = today.getYear();
        int month = today.getMonthValue();
        int weekNumber = getWeekOfMonth(today);

        // 이번 주 시작/종료 시간 계산 (월요일 00:00 ~ 일요일 23:59)
        LocalDateTime weekStart = today.with(TemporalAdjusters.previousOrSame(java.time.DayOfWeek.MONDAY))
                .atStartOfDay();
        LocalDateTime weekEnd = today.with(TemporalAdjusters.nextOrSame(java.time.DayOfWeek.SUNDAY))
                .atTime(23, 59, 59);

        // 1. 주차 정보
        WeeklyStatsDto.WeekInfo weekInfo = new WeeklyStatsDto.WeekInfo(year, month, weekNumber);

        // 2. 학습 시간 통계
        WeeklyStatsDto.StudyTime studyTime = getStudyTime(userId, weekStart, weekEnd);

        // 3. 카드 개선도
        WeeklyStatsDto.CardImprovement cardImprovement = getCardImprovement(userId, year, month, weekNumber);

        // 4. 목표별 진행도
        List<WeeklyStatsDto.GoalProgress> goalProgress = getGoalProgress(userId, year, month, weekNumber);

        return new WeeklyStatsDto.Response(weekInfo, studyTime, cardImprovement, goalProgress);
    }

    /**
     * 학습 시간 통계 계산
     * 포모도로 학습 시간 + 단어장 학습 시간
     */
    private WeeklyStatsDto.StudyTime getStudyTime(Long userId, LocalDateTime weekStart, LocalDateTime weekEnd) {
        // 포모도로 학습 시간 (포모 개수 * 25분)
        List<GoalStudySession> goalSessions = goalStudySessionRepository
                .findByUserIdAndStartedAtBetween(userId, weekStart, weekEnd);
        int pomodoroMinutes = goalSessions.stream()
                .mapToInt(GoalStudySession::getDurationMinutes)
                .sum();

        // 단어장 학습 시간 (실제 소요 시간)
        List<WordBookStudySession> wordBookSessions = wordBookStudySessionRepository
                .findByUserIdAndStartedAtBetween(userId, weekStart, weekEnd);
        int wordBookMinutes = wordBookSessions.stream()
                .mapToInt(WordBookStudySession::getDurationMinutes)
                .sum();

        return new WeeklyStatsDto.StudyTime(pomodoroMinutes, wordBookMinutes);
    }

    /**
     * 카드 개선도 계산
     * 주 시작 vs 현재 난이도 분포 비교
     */
    private WeeklyStatsDto.CardImprovement getCardImprovement(Long userId, int year, int month, int weekNumber) {
        // 주 시작 시점 기준선 조회
        WeeklyCardBaseline baseline = weeklyCardBaselineRepository
                .findByUserIdAndYearAndMonthAndWeekNumber(userId, year, month, weekNumber)
                .orElse(null);

        WeeklyStatsDto.DifficultyCount weekStart;
        if (baseline != null) {
            weekStart = new WeeklyStatsDto.DifficultyCount(
                    baseline.getHardCount(),
                    baseline.getNormalCount(),
                    baseline.getEasyCount()
            );
        } else {
            // 기준선 없으면 0으로 처리
            weekStart = new WeeklyStatsDto.DifficultyCount(0, 0, 0);
        }

        // 현재 난이도 분포 집계
        List<Card> userCards = cardRepository.findByWordBookUserId(userId);
        Map<Card.Difficulty, Long> currentCounts = userCards.stream()
                .filter(card -> card.getDifficulty() != null)
                .collect(Collectors.groupingBy(Card::getDifficulty, Collectors.counting()));

        WeeklyStatsDto.DifficultyCount current = new WeeklyStatsDto.DifficultyCount(
                currentCounts.getOrDefault(Card.Difficulty.HARD, 0L).intValue(),
                currentCounts.getOrDefault(Card.Difficulty.NORMAL, 0L).intValue(),
                currentCounts.getOrDefault(Card.Difficulty.EASY, 0L).intValue()
        );

        return new WeeklyStatsDto.CardImprovement(weekStart, current);
    }

    /**
     * 목표별 진행도 계산
     * 주 시작 vs 현재 진행도 비교
     */
    private List<WeeklyStatsDto.GoalProgress> getGoalProgress(Long userId, int year, int month, int weekNumber) {
        // 주 시작 시점 기준선들 조회
        List<WeeklyGoalBaseline> baselines = weeklyGoalBaselineRepository
                .findByUserIdAndYearAndMonthAndWeekNumber(userId, year, month, weekNumber);

        // 현재 목표들 조회
        List<Goal> currentGoals = goalRepository.findByUserId(userId);

        List<WeeklyStatsDto.GoalProgress> progressList = new ArrayList<>();

        for (WeeklyGoalBaseline baseline : baselines) {
            // 현재 목표 찾기
            Goal currentGoal = currentGoals.stream()
                    .filter(g -> g.getId().equals(baseline.getGoal().getId()))
                    .findFirst()
                    .orElse(null);

            if (currentGoal != null) {
                progressList.add(new WeeklyStatsDto.GoalProgress(
                        currentGoal.getId(),
                        currentGoal.getTitle(),
                        baseline.getStartAmount(),
                        currentGoal.getCurrentProgress(),
                        currentGoal.getTargetUnit()
                ));
            }
        }

        return progressList;
    }

    /**
     * 월 기준 주차 계산
     * 1일~7일 = 1주차, 8일~14일 = 2주차 ...
     */
    private int getWeekOfMonth(LocalDate date) {
        WeekFields weekFields = WeekFields.of(Locale.getDefault());
        return date.get(weekFields.weekOfMonth());
    }

    /**
     * 이번 주 첫 실행 시 기준선 생성
     * AppLaunch 등에서 호출
     */
    public void createWeeklyBaselinesIfNeeded(Long userId) {
        LocalDate today = LocalDate.now();
        int year = today.getYear();
        int month = today.getMonthValue();
        int weekNumber = getWeekOfMonth(today);

        // 이미 이번 주 기준선이 있는지 확인
        boolean cardBaselineExists = weeklyCardBaselineRepository
                .existsByUserIdAndYearAndMonthAndWeekNumber(userId, year, month, weekNumber);

        if (!cardBaselineExists) {
            createCardBaseline(userId, year, month, weekNumber);
            createGoalBaselines(userId, year, month, weekNumber);
        }
    }

    /**
     * 카드 기준선 생성
     */
    private void createCardBaseline(Long userId, int year, int month, int weekNumber) {
        User user = userRepository.findById(userId).orElse(null);
        if (user == null) return;

        // 현재 카드 난이도 분포 집계
        List<Card> userCards = cardRepository.findByWordBookUserId(userId);
        Map<Card.Difficulty, Long> counts = userCards.stream()
                .filter(card -> card.getDifficulty() != null)
                .collect(Collectors.groupingBy(Card::getDifficulty, Collectors.counting()));

        int hardCount = counts.getOrDefault(Card.Difficulty.HARD, 0L).intValue();
        int normalCount = counts.getOrDefault(Card.Difficulty.NORMAL, 0L).intValue();
        int easyCount = counts.getOrDefault(Card.Difficulty.EASY, 0L).intValue();

        WeeklyCardBaseline baseline = new WeeklyCardBaseline(
                user, year, month, weekNumber,
                userCards.size(), hardCount, normalCount, easyCount
        );
        weeklyCardBaselineRepository.save(baseline);
    }

    /**
     * 목표 기준선들 생성
     */
    private void createGoalBaselines(Long userId, int year, int month, int weekNumber) {
        User user = userRepository.findById(userId).orElse(null);
        if (user == null) return;

        List<Goal> goals = goalRepository.findByUserId(userId);

        for (Goal goal : goals) {
            WeeklyGoalBaseline baseline = new WeeklyGoalBaseline(
                    user, goal, year, month, weekNumber,
                    goal.getCurrentProgress(),
                    goal.getTargetUnit(),
                    goal.getTitle()
            );
            weeklyGoalBaselineRepository.save(baseline);
        }
    }
}