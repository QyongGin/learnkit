package com.learnkit.backend.service;

import com.learnkit.backend.domain.Goal;
import com.learnkit.backend.domain.GoalStudySession;
import com.learnkit.backend.domain.User;
import com.learnkit.backend.dto.GoalStudySessionDto;
import com.learnkit.backend.exception.custom.GoalNotFoundException;
import com.learnkit.backend.exception.custom.GoalStudySessionNotFoundException;
import com.learnkit.backend.exception.custom.UserNotFoundException;
import com.learnkit.backend.repository.GoalRepository;
import com.learnkit.backend.repository.GoalStudySessionRepository;
import com.learnkit.backend.repository.UserRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class GoalStudySessionService {

    private final GoalStudySessionRepository goalStudySessionRepository;
    private final UserRepository userRepository;
    private final GoalRepository goalRepository;

    /**
     * 학습 세션 시작
     */
    public GoalStudySessionDto.Response startSession(Long userId, GoalStudySessionDto.StartRequest requestDto) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException(userId));

        // 이미 진행 중인 세션 있는지 확인
        List<GoalStudySession> activeSessions = goalStudySessionRepository.findAllByUserIdAndEndedAtIsNull(userId);
        if (!activeSessions.isEmpty()) {
            throw new IllegalStateException("이미 진행 중인 학습 세션이 있습니다.");
        }

        // Goal 조회 (nullable)
        Goal goal = null;
        if (requestDto.getGoalId() != null) {
            goal = goalRepository.findById(requestDto.getGoalId())
                    .orElseThrow(() -> new GoalNotFoundException(requestDto.getGoalId()));
        }

        GoalStudySession session = new GoalStudySession(user, goal);
        GoalStudySession savedSession = goalStudySessionRepository.save(session);

        return new GoalStudySessionDto.Response(savedSession);
    }

    /**
     * 학습 세션 종료
     */
    public GoalStudySessionDto.Response endSession(Integer sessionId, GoalStudySessionDto.EndRequest requestDto) {
        GoalStudySession session = goalStudySessionRepository.findById(sessionId)
                .orElseThrow(() -> new GoalStudySessionNotFoundException(sessionId));

        if (!session.isInProgress()) {
            throw new IllegalStateException("이미 종료된 세션입니다.");
        }

        session.endSession(
                requestDto.getAchievedAmount(),
                requestDto.getPomoCount(),
                requestDto.getNote());

        // Goal 진행도 업데이트 (goal이 있고, 달성량이 0보다 크면)
        if (session.getGoal() != null && requestDto.getAchievedAmount() > 0) {
            session.getGoal().addProgress(requestDto.getAchievedAmount());
        }

        return new GoalStudySessionDto.Response(session);
    }

    /**
     * 특정 사용자의 모든 세션 조회
     */
    public List<GoalStudySessionDto.Response> findSessionsByUserId(Long userId) {
        List<GoalStudySession> sessions = goalStudySessionRepository.findByUserId(userId);
        return sessions.stream()
                .map(GoalStudySessionDto.Response::new)
                .toList();
    }

    /**
     * 진행 중인 세션 조회
     */
    public GoalStudySessionDto.Response findActiveSession(Long userId) {
        List<GoalStudySession> activeSessions = goalStudySessionRepository.findAllByUserIdAndEndedAtIsNull(userId);

        if (activeSessions.isEmpty()) {
            throw new GoalStudySessionNotFoundException("진행 중인 세션이 없습니다.");
        }

        // 여러 개가 있다면 가장 최근에 시작한 세션 반환
        GoalStudySession session = activeSessions.stream()
                .max((s1, s2) -> s1.getStartedAt().compareTo(s2.getStartedAt()))
                .orElseThrow(() -> new GoalStudySessionNotFoundException("진행 중인 세션이 없습니다."));
        
        return new GoalStudySessionDto.Response(session);
    }

    /**
     * 세션 상세 조회
     */
    public GoalStudySessionDto.Response findSessionById(Integer sessionId) {
        GoalStudySession session = goalStudySessionRepository.findById(sessionId)
                .orElseThrow(() -> new GoalStudySessionNotFoundException(sessionId));
        return new GoalStudySessionDto.Response(session);
    }

    /**
     * 세션 삭제
     */
    public void deleteSession(Integer sessionId) {
        GoalStudySession session = goalStudySessionRepository.findById(sessionId)
                .orElseThrow(() -> new GoalStudySessionNotFoundException(sessionId));
        goalStudySessionRepository.delete(session);
    }

    /**
     * 학습 통계 조회 (특정 기간)
     */
    public GoalStudySessionDto.StatisticsResponse getStatistics(Long userId, LocalDateTime start, LocalDateTime end) {
        List<GoalStudySession> sessions = goalStudySessionRepository.findByUserIdAndStartedAtBetween(userId, start,
                end);

        int totalSessions = sessions.size();
        int totalMinutes = sessions.stream().mapToInt(GoalStudySession::getDurationMinutes).sum();
        int totalPomoCount = sessions.stream().mapToInt(GoalStudySession::getPomoCount).sum();
        int totalAchievedAmount = sessions.stream().mapToInt(GoalStudySession::getAchievedAmount).sum();

        return new GoalStudySessionDto.StatisticsResponse(totalSessions, totalMinutes, totalPomoCount,
                totalAchievedAmount);
    }

    /**
     * 특정 목표에 연결된 학습 세션 조회
     */
    public List<GoalStudySessionDto.Response> findSessionsByGoalId(Integer goalId) {
        List<GoalStudySession> sessions = goalStudySessionRepository.findByGoalId(goalId);
        return sessions.stream()
                .map(GoalStudySessionDto.Response::new)
                .toList();
    }

    /**
     * 진행 중인 세션의 포모도로 카운트 실시간 업데이트
     */
    public GoalStudySessionDto.Response updatePomoCount(Integer sessionId, int pomoCount) {
        GoalStudySession session = goalStudySessionRepository.findById(sessionId)
                .orElseThrow(() -> new GoalStudySessionNotFoundException(sessionId));

        session.updatePomoCount(pomoCount);
        return new GoalStudySessionDto.Response(session);
    }
}