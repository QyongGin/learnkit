package com.learnkit.backend.service;

import com.learnkit.backend.domain.Goal;
import com.learnkit.backend.domain.User;
import com.learnkit.backend.dto.GoalDto;
import com.learnkit.backend.exception.custom.GoalNotFoundException;
import com.learnkit.backend.exception.custom.UserNotFoundException;
import com.learnkit.backend.repository.GoalRepository;
import com.learnkit.backend.repository.UserRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Goal 비즈니스 로직을 담당하는 Service
 */
@Service
@RequiredArgsConstructor
@Transactional
public class GoalService {

    private final GoalRepository goalRepository;
    private final UserRepository userRepository;

    /**
     * 새로운 목표를 생성
     *
     * @param userId 사용자 Id
     * @param requestDto 목표 생성 정보
     *
     * @return 생성된 목표 정보
     */
    public GoalDto.Response createGoal(Long userId, GoalDto.CreateRequest requestDto) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException(userId));

        Goal goal = requestDto.toEntity();
        goal.setUser(user);

        Goal savedGoal = goalRepository.save(goal);
        return new GoalDto.Response(savedGoal);
    }

    /**
     * 특정 사용자의 모든 목표를 조회함
     *
     * @param userId 사용자 ID
     * @return 목표 목록
     */
    public List<GoalDto.Response> findGoalsByUserId(Long userId) {
         List<Goal> goals = goalRepository.findByUserId(userId);
            return goals.stream().map(GoalDto.Response::new).toList();
    }

    /**
     * 특정 사용자의 진행 중인 목표만 조회 (뽀모도로 선택용)
     *
     * @param userId 사용자 ID
     * @return 진행 중인 목표 목록
     */
    public List<GoalDto.Response> findActiveGoalsByUserId(Long userId) {
        List<Goal> activeGoals = goalRepository.findByUserIdAndIsCompleted(userId, false);
            return activeGoals.stream().map(GoalDto.Response::new).toList();
    }

    /**
     * 특정 목표의 상세 정보를 조회함
     *
     * @param goalId 목표 ID
     * @return 목표 상세 정보
     */
    public GoalDto.Response findGoalById(Long goalId) {
        Goal goal = goalRepository.findById(goalId)
                .orElseThrow(() -> new GoalNotFoundException(goalId));
        return new GoalDto.Response(goal);
    }

    /**
     * 목표 정보를 수정함
     *
     * @param goalId 목표 ID
     * @param requestDto 수정할 정보
     * @return 수정된 목표 정보
     */
    public GoalDto.Response updateGoal(Long goalId, GoalDto.UpdateRequest requestDto) {
        Goal goal = goalRepository.findById(goalId)
                .orElseThrow(() -> new GoalNotFoundException(goalId));

        goal.update(requestDto.getTitle(), requestDto.getStartDate(), requestDto.getEndDate(),
                requestDto.getTotalTargetAmount(), requestDto.getTargetUnit());

        return new GoalDto.Response(goal);
    }

    /**
     * 목표의 진행도 추가
     *
     * @param goalId 목표 ID
     * @param requestDto 추가할 진행도
     * @return 업데이트된 목표 정보
     */
    public GoalDto.Response addProgress(Long goalId, GoalDto.AddProgressRequest requestDto) {
        Goal goal = goalRepository.findById(goalId)
                .orElseThrow(() -> new GoalNotFoundException(goalId));

        goal.addProgress(requestDto.getAmount());

        return new GoalDto.Response(goal);
    }

    /**
     * 목표 삭제
     *
     * @param goalId 목표 ID
     */
    public void deleteGoal(Long goalId) {
        Goal goal = goalRepository.findById(goalId)
                .orElseThrow(() -> new GoalNotFoundException(goalId));
        goalRepository.delete(goal);
    }

}
