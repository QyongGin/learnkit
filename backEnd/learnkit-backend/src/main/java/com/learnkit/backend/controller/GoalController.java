package com.learnkit.backend.controller;

import com.learnkit.backend.dto.GoalDto;
import com.learnkit.backend.service.GoalService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor // GoalService 등 필드 자동 초기화
@RequestMapping("/api")
public class GoalController {

    private final GoalService goalService;

    /**
     * 새로운 목표를 생성함
     *
     * @param userId 사용자 ID
     * @param requestDto 목표 생성 정보
     * @return 생성된 목표 정보
     */
    @PostMapping("/users/{userId}/goals")
    public ResponseEntity<GoalDto.Response> createGoal(@PathVariable Long userId, @RequestBody GoalDto.CreateRequest requestDto) {
        GoalDto.Response response = goalService.createGoal(userId,requestDto);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * 특정 사용자의 모든 목표를 조회함
     *
     * @param userId 사용자 ID
     * @return 목표 목록
     */
    @GetMapping("/users/{userId}/goals")
    public ResponseEntity<List<GoalDto.Response>> getGoalByUser(@PathVariable Long userId) {
        List<GoalDto.Response> goals = goalService.findGoalsByUserId(userId);
        return ResponseEntity.ok(goals);
    }

    /**
     * 특정 사용자의 진행 중인 목표만 조회
     *
     * @param userId 사용자 ID
     * @return 진행 중인 목표 목록
     */
    @GetMapping("/users/{userId}/goals/active")
    public ResponseEntity<List<GoalDto.Response>> getActiveGoalsByUser(@PathVariable Long userId) {
        List<GoalDto.Response> activeGoals = goalService.findActiveGoalsByUserId(userId);
        return ResponseEntity.ok(activeGoals);
    }

    /**
     * 특정 목표의 상세 정보를 조회함
     *
     * @param goalId 목표 ID
     * @return 목표 상세 정보
     */
    @GetMapping("/goals/{goalId}")
    public ResponseEntity<GoalDto.Response> getGoal(@PathVariable Integer goalId) {
        GoalDto.Response goal = goalService.findGoalById(goalId);
        return ResponseEntity.ok(goal);
    }

    /**
     * 목표 정보를 수정
     *
     * @param goalId 목표 ID
     * @param requestDto 수정할 정보
     * @return 수정된 목표 정보
     */
    @PatchMapping("/goals/{goalId}")
    public ResponseEntity<GoalDto.Response> updateGoal(@PathVariable Integer goalId, @RequestBody GoalDto.UpdateRequest requestDto) {
        GoalDto.Response updatedGoal = goalService.updateGoal(goalId, requestDto);
        return ResponseEntity.ok(updatedGoal);
    }

    /**
     * 목표의 진행도를 추가함 (학습 세션 완료 후 호출)
     *
     * @param goalId 목표 ID
     * @param requestDto 추가할 진행도
     * @return 업데이트된 목표 정보
     */
    @PatchMapping("/goals/{goalId}/progress")
    public ResponseEntity<GoalDto.Response> addProgress(@PathVariable Integer goalId, @RequestBody GoalDto.AddProgressRequest requestDto) {
        GoalDto.Response updatedGoal = goalService.addProgress(goalId, requestDto);
        return ResponseEntity.ok(updatedGoal);
    }

    /**
     * 목표를 삭제함
     *
     * @param goalId 목표 ID
     * @return 삭제 완료 응답
     */
    @DeleteMapping("/goals/{goalId}")
    public ResponseEntity<Void> deleteGoal(@PathVariable Integer goalId) {
        goalService.deleteGoal(goalId);
        return ResponseEntity.noContent().build();
    }
}
