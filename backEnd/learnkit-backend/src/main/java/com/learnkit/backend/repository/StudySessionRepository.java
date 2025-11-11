package com.learnkit.backend.repository;


import com.learnkit.backend.domain.StudySession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * StudySession 엔티티의 데이터베이스 접근을 담당하는 Repository
 */
@Repository
public interface StudySessionRepository extends JpaRepository<StudySession, Long> {

    /**
     * 특정 사용자의 모든 학습 세션을 조회
     *
     * @param userId 사용자 ID
     * @return 학습 세션 목록
     */
    List<StudySession> findByUserId(Long userId);

    /**
     * 특정 사용자의 진행 중인 세션 조회 (endedAt == null)
     *
     * @param userId 사용자 ID
     * @return 진행 중인 세션 (Optional)
     */
    Optional<StudySession> findByUserIdAndEndedAtIsNull(Long userId);

    /**
     * 특정 목표에 연결된 모든 학습 세션 조회
     *
     * @param goalId 목표 ID
     * @return 학습 세션 목록
     */
    List<StudySession> findByGoalId(Long goalId);

    /**
     * 특정 사용자의 특정 기간 학습 세션 조회 (통계용)
     *
     * @param userId 사용자 ID
     * @param start 시작 시간
     * @param end 종료 시간
     * @return 학습 세션 목록
     */
    List<StudySession> findByUserIdAndCreatedAtBetween(Long userId, LocalDateTime start, LocalDateTime end);

}
