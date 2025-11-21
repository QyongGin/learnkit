package com.learnkit.backend.service;

import com.learnkit.backend.domain.Goal;
import com.learnkit.backend.domain.StudySession;
import com.learnkit.backend.domain.User;
import com.learnkit.backend.domain.WeeklyStat;
import com.learnkit.backend.dto.WeeklyStatDto;
import com.learnkit.backend.exception.custom.UserNotFoundException;
import com.learnkit.backend.repository.GoalRepository;
import com.learnkit.backend.repository.StudySessionRepository;
import com.learnkit.backend.repository.UserRepository;
import com.learnkit.backend.repository.WeeklyStatRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 주간 통계 관련 비즈니스 로직
 */
@Service
@RequiredArgsConstructor
@Transactional
public class WeeklyStatService {

    private final WeeklyStatRepository weeklyStatRepository;
    private final StudySessionRepository studySessionRepository;
    private final GoalRepository goalRepository;
    private final UserRepository userRepository;

    /**
     * 주간 정산 요약 정보 조회
     * - 이번 주 학습 시간, 포모도로 수, 세션 수 계산
     * - 목표 달성률 계산
     * - WeeklyStat 엔티티에 달성률 저장
     *
     * @param userId 사용자 ID
     * @return 주간 정산 응답 DTO
     */
    public WeeklyStatDto.WeeklySummaryResponse getWeeklySummary(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException(userId));

        LocalDate now = LocalDate.now();
        int year = now.getYear();
        int month = now.getMonthValue();  // 1~12
        int weekNumber = WeeklyStat.getWeekOfMonth(now);  // 월 기준 주차 (1~5)

        // 이번 주 시작/종료 날짜 계산 (월요일 00:00 ~ 일요일 23:59)
        LocalDate weekStart = now.with(java.time.DayOfWeek.MONDAY);
        LocalDate weekEnd = now.with(java.time.DayOfWeek.SUNDAY);
        LocalDateTime start = weekStart.atStartOfDay();
        LocalDateTime end = weekEnd.atTime(23, 59, 59);

        // 이번 주 학습 세션 데이터 조회
        List<StudySession> sessions = studySessionRepository.findByUserIdAndCreatedAtBetween(userId, start, end);

        // 통계 계산
        int totalMinutes = sessions.stream()
                .mapToInt(StudySession::getDurationMinutes)
                .sum();

        int totalPomoCount = sessions.stream()
                .mapToInt(StudySession::getPomoCount)
                .sum();

        int totalSessions = sessions.size();

        // 목표 달성률 계산 (전체 목표 대비 완료된 목표 비율)
        float achievementRate = calculateAchievementRate(userId);

        // 주간 통계 엔티티 저장 또는 업데이트
        WeeklyStat weeklyStat = weeklyStatRepository
                .findByUserIdAndYearAndMonthAndWeekNumber(userId, year, month, weekNumber)
                .orElse(new WeeklyStat(user, year, month, weekNumber));

        weeklyStat.updateAchievementRate(achievementRate);
        weeklyStatRepository.save(weeklyStat);

        return new WeeklyStatDto.WeeklySummaryResponse(
                year, month, weekNumber, totalMinutes, totalPomoCount,
                totalSessions, achievementRate
        );
    }

    /**
     * 목표 달성률 계산
     * 사용자의 전체 목표 중 완료된 목표의 비율을 계산
     *
     * @param userId 사용자 ID
     * @return 달성률 (0.0 ~ 1.0)
     */
    private float calculateAchievementRate(Long userId) {
        List<Goal> userGoals = goalRepository.findByUserId(userId);

        if (userGoals.isEmpty()) {
            return 0.0f;
        }

        long completedGoals = userGoals.stream()
                .filter(Goal::isCompleted)
                .count();

        return (float) completedGoals / userGoals.size();
    }
}