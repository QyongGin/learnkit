package com.learnkit.backend.repository;

import com.learnkit.backend.domain.WeeklyCardBaseline;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * WeeklyCardBaseline 엔티티의 데이터베이스 접근을 담당하는 Repository
 */
@Repository
public interface WeeklyCardBaselineRepository extends JpaRepository<WeeklyCardBaseline, Integer> {

    /**
     * 특정 사용자의 특정 주차 카드 기준선 조회
     */
    Optional<WeeklyCardBaseline> findByUserIdAndYearAndMonthAndWeekNumber(
            Long userId, int year, int month, int weekNumber);

    /**
     * 특정 사용자의 특정 주차 기준선 존재 여부 확인
     */
    boolean existsByUserIdAndYearAndMonthAndWeekNumber(
            Long userId, int year, int month, int weekNumber);
}