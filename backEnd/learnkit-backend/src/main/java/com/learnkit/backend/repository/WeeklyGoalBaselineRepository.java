package com.learnkit.backend.repository;

import com.learnkit.backend.domain.WeeklyGoalBaseline;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * WeeklyGoalBaseline 엔티티의 데이터베이스 접근을 담당하는 Repository
 */
@Repository
public interface WeeklyGoalBaselineRepository extends JpaRepository<WeeklyGoalBaseline, Integer> {

    /**
     * 특정 사용자의 특정 주차 모든 목표 기준선 조회
     */
    List<WeeklyGoalBaseline> findByUserIdAndYearAndMonthAndWeekNumber(
            Long userId, int year, int month, int weekNumber);

    /**
     * 특정 사용자의 특정 목표의 특정 주차 기준선 조회
     */
    Optional<WeeklyGoalBaseline> findByUserIdAndGoalIdAndYearAndMonthAndWeekNumber(
            Long userId, Integer goalId, int year, int month, int weekNumber);

    /**
     * 특정 사용자의 특정 주차 기준선 존재 여부 확인
     */
    boolean existsByUserIdAndYearAndMonthAndWeekNumber(
            Long userId, int year, int month, int weekNumber);
}