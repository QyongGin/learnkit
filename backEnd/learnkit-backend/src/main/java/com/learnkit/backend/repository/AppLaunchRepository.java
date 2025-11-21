package com.learnkit.backend.repository;

import com.learnkit.backend.domain.AppLaunch;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 앱 실행 기록 Repository
 */
@Repository
public interface AppLaunchRepository extends JpaRepository<AppLaunch, Integer> {

    /**
     * 특정 사용자의 앱 실행 기록 조회
     */
    List<AppLaunch> findByUserId(Long userId);

    /**
     * 특정 기간 동안의 앱 실행 기록 조회
     */
    List<AppLaunch> findByUserIdAndLaunchTimeBetween(Long userId, LocalDateTime start, LocalDateTime end);

    /**
     * 최근 N일간의 앱 실행 기록 조회 (시간대 분석용)
     */
    @Query("SELECT a FROM AppLaunch a WHERE a.user.id = :userId AND a.launchTime >= :since ORDER BY a.launchTime DESC")
    List<AppLaunch> findRecentLaunches(@Param("userId") Long userId, @Param("since") LocalDateTime since);
}