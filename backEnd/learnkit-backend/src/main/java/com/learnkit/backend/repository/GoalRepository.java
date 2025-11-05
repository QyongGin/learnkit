package com.learnkit.backend.repository;

import com.learnkit.backend.domain.Goal;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface GoalRepository extends JpaRepository<Goal, Long> {

    /**
     * 특정 사용자의 모든 목표를 조회
     *
     * @param userId 사용자 ID
     * @return 목표 목록
     */
    List<Goal> findByUserId(Long userId);

    /**
     * 특정 사용자의 진행 중인 목표만 조회
     *
     * @param userId 사용자 ID
     * @param isCompleted 완료 여부 (false = 진행 중 true = 완료)
     * @return 필터링된 목표 목록
     */
    List<Goal> findByUserIdAndIsCompleted(Long userId, boolean isCompleted);
}
