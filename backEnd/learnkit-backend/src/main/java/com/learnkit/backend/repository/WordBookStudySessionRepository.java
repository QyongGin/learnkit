package com.learnkit.backend.repository;

import com.learnkit.backend.domain.WordBookStudySession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * WordBookStudySession 엔티티의 데이터베이스 접근을 담당하는 Repository
 */
@Repository
public interface WordBookStudySessionRepository extends JpaRepository<WordBookStudySession, Integer> {

    /**
     * 특정 사용자의 모든 단어장 학습 세션을 조회
     */
    List<WordBookStudySession> findByUserId(Long userId);

    /**
     * 특정 사용자의 진행 중인 세션 조회 (endedAt == null)
     */
    Optional<WordBookStudySession> findByUserIdAndEndedAtIsNull(Long userId);

    /**
     * 특정 단어장에 연결된 모든 학습 세션 조회
     */
    List<WordBookStudySession> findByWordBookId(Long wordBookId);

    /**
     * 특정 사용자의 특정 기간 학습 세션 조회 (통계용)
     */
    List<WordBookStudySession> findByUserIdAndStartedAtBetween(Long userId, LocalDateTime start, LocalDateTime end);
}