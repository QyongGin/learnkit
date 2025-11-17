package com.learnkit.backend.service;

import com.learnkit.backend.domain.Goal;
import com.learnkit.backend.domain.StudySession;
import com.learnkit.backend.domain.User;
import com.learnkit.backend.dto.StudySessionDto;
import com.learnkit.backend.exception.custom.GoalNotFoundException;
import com.learnkit.backend.exception.custom.StudySessionNotFoundException;
import com.learnkit.backend.exception.custom.UserNotFoundException;
import com.learnkit.backend.repository.GoalRepository;
import com.learnkit.backend.repository.StudySessionRepository;
import com.learnkit.backend.repository.UserRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor // final 필드 생성자 자동 생성
@Transactional
public class StudySessionService {

    private final StudySessionRepository studySessionRepository;
    private final UserRepository userRepository;
    private final GoalRepository goalRepository;

    /**
     * 학습 세션 시작
     */
    public StudySessionDto.Response startSession(Long userId, StudySessionDto.StartRequest requestDto) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException(userId));

        // 이미 진행 중인 세션 있는지 확인
        Optional<StudySession> activeSession = studySessionRepository.findByUserIdAndEndedAtIsNull(userId); // endedAt은 종료된 시간. null이라면 진행 중
        if (activeSession.isPresent()) { // isPresent(): true->Optional 안에 값이 있음, 진행 중인 세션 존재 false->비어있음
            throw new IllegalStateException("이미 진행 중인 학습 세션이 있습니다.");
        }

        // Goal 조회 (nullable)
        Goal goal = null;
        if (requestDto.getGoalId() != null) {
            goal = goalRepository.findById(requestDto.getGoalId())
                    .orElseThrow(() -> new GoalNotFoundException(requestDto.getGoalId()));
        }

        StudySession session = new StudySession(user, goal);
        StudySession savedSession = studySessionRepository.save(session); // 누가, 무슨 목표를, 시작 시간

        return new StudySessionDto.Response(savedSession);
    }

    /**
     * 학습 세션 종료
     */
    public StudySessionDto.Response endSession(Long sessionId, StudySessionDto.EndRequest requestDto) {
        StudySession session = studySessionRepository.findById(sessionId)
                .orElseThrow(() -> new StudySessionNotFoundException(sessionId));

        if (!session.isInProgress()) {
            throw new IllegalStateException("이미 종료된 세션입니다.");
        }

        session.endSession(
                requestDto.getAchievedAmount(), // 달성량
                requestDto.getDurationMinutes(), // 학습 시간(분)
                requestDto.getPomoCount(), // 포모도로 달성 횟수
                requestDto.getNote() // 메모
        );

        // Goal 진행도 업데이트 (goal이 있고, 달성량이 0보다 크면)
        if (session.getGoal() != null && requestDto.getAchievedAmount() > 0) {
            // Goal 객체 가져온 후, Goal의 메서드 호출
            session.getGoal().addProgress(requestDto.getAchievedAmount());
        }

        return new StudySessionDto.Response(session);
    }

    /**
     * 특정 사용자의 모든 세션 조회
     */
    public List<StudySessionDto.Response> findSessionsByUserId(Long userId) {
        List<StudySession> sessions = studySessionRepository.findByUserId(userId);
        return sessions.stream()
                .map(StudySessionDto.Response::new)
                .toList();
    }

    /**
     * 진행 중인 세션 조회
     * 추후 사용자의 불가피한 이유로 강제 종료 시 session을 다시 불러오도록 설정 예정
     */
    public StudySessionDto.Response findActiveSession(Long userId) {
        StudySession session = studySessionRepository.findByUserIdAndEndedAtIsNull(userId)
                .orElseThrow(() -> new StudySessionNotFoundException("진행 중인 세션이 없습니다."));
        return new StudySessionDto.Response(session);
    }

    /**
     * 세션 상세 조회
     */
    public StudySessionDto.Response findSessionById(Long sessionId) {
        StudySession session = studySessionRepository.findById(sessionId)
                .orElseThrow(() -> new StudySessionNotFoundException(sessionId));
        return new StudySessionDto.Response(session);
    }

    /**
     * 세션 삭제
     */
    public void deleteSession(Long sessionId) {
        StudySession session = studySessionRepository.findById(sessionId)
                .orElseThrow(() -> new StudySessionNotFoundException(sessionId));
        studySessionRepository.delete(session);
    }

    /**
     * 학습 통계 조회 (특정 기간)
     */
    public StudySessionDto.StatisticsResponse getStatistics(Long userId, LocalDateTime start, LocalDateTime end) {
        List<StudySession> sessions = studySessionRepository.findByUserIdAndCreatedAtBetween(userId, start, end);

        int totalSessions = sessions.size(); // session 개수
        int totalMinutes = sessions.stream().mapToInt(StudySession::getDurationMinutes).sum(); // 총 시간
        int totalPomoCount = sessions.stream().mapToInt(StudySession::getPomoCount).sum(); // 총 포모도로 횟수
        int totalAchievedAmount = sessions.stream().mapToInt(StudySession::getAchievedAmount).sum(); // 총 달성량

        return new StudySessionDto.StatisticsResponse(totalSessions, totalMinutes, totalPomoCount, totalAchievedAmount);
    }

    /**
     * 특정 목표에 연결된 학습 세션 조회
     */
    public List<StudySessionDto.Response> findSessionsByGoalId(Integer goalId) {
        List<StudySession> sessions = studySessionRepository.findByGoalId(goalId);
        return sessions.stream()
                .map(StudySessionDto.Response::new)
                .toList();
    }

    /**
     * 진행 중인 세션의 포모도로 카운트 실시간 업데이트
     * 앱 강제 종료 시에도 진행 상황을 보존하기 위해 매 포모도로 완료 시마다 호출
     * 포모도로 세트 수를 기반으로 경과 시간도 자동 계산됨 (1세트 = 25분)
     */
    public StudySessionDto.Response updatePomoCount(Long sessionId, int pomoCount) {
        StudySession session = studySessionRepository.findById(sessionId)
                .orElseThrow(() -> new StudySessionNotFoundException(sessionId));

        session.updatePomoCount(pomoCount);  // 경과 시간도 자동 계산됨
        return new StudySessionDto.Response(session);
    }
}
