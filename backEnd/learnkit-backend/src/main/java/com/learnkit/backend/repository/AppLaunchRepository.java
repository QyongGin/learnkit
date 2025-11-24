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
     * 최근 N일간의 앱 실행 기록 조회 (시간대 분석용)
     * @param userId 사용자 ID
     * @param since 조회 시작 시점
     * @return 지정 시점 이후의 앱 실행 기록 목록 (최신순 정렬)
     */
     // ":" 쿼리문의 빈칸을 만듦. "since" 빈칸에 들어갈 변수의 이름. :since 안에 매개변수로 받은 since가 들어감
    @Query("SELECT a FROM AppLaunch a WHERE a.user.id = :userId AND a.launchTime >= :since ORDER BY a.launchTime DESC")
    List<AppLaunch> findRecentLaunches(@Param("userId") Long userId, @Param("since") LocalDateTime since);
}