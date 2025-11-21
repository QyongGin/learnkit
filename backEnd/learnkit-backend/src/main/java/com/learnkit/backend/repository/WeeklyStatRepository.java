package com.learnkit.backend.repository;

import com.learnkit.backend.domain.WeeklyStat;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * 주간 통계 Repository
 */
@Repository
public interface WeeklyStatRepository extends JpaRepository<WeeklyStat, Integer> {

    /**
     * 특정 사용자의 모든 주간 통계 조회
     */
    List<WeeklyStat> findByUserId(Long userId);

    /**
     * 특정 사용자의 특정 주차 통계 조회 (연도 + 월 + 주차)
     */
    Optional<WeeklyStat> findByUserIdAndYearAndMonthAndWeekNumber(Long userId, int year, int month, int weekNumber);

    /**
     * 특정 사용자의 특정 연도 통계 조회
     */
    List<WeeklyStat> findByUserIdAndYear(Long userId, int year);

    /**
     * 특정 사용자의 특정 연도+월 통계 조회
     */
    List<WeeklyStat> findByUserIdAndYearAndMonth(Long userId, int year, int month);
}