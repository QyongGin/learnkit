package com.learnkit.backend.repository;

import com.learnkit.backend.domain.GoalStudySession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * GoalStudySession 엔티티의 데이터베이스 접근을 담당하는 Repository
 */
@Repository
public interface GoalStudySessionRepository extends JpaRepository<GoalStudySession, Integer> {

    /**
     * 특정 사용자의 모든 학습 세션을 조회
     */
    List<GoalStudySession> findByUserId(Long userId);

    /**
     * 특정 사용자의 진행 중인 세션 조회 (endedAt == null)
     */
    Optional<GoalStudySession> findByUserIdAndEndedAtIsNull(Long userId);

    /**
     * 특정 목표에 연결된 모든 학습 세션 조회
     */
    List<GoalStudySession> findByGoalId(Integer goalId);

    /**
     * 특정 사용자의 특정 기간 학습 세션 조회 (통계용)
     * startedAt 기준으로 조회
     */
    List<GoalStudySession> findByUserIdAndStartedAtBetween(Long userId, LocalDateTime start, LocalDateTime end);
}