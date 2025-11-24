package com.learnkit.backend.service;

import com.learnkit.backend.domain.User;
import com.learnkit.backend.domain.WordBook;
import com.learnkit.backend.domain.WordBookStudySession;
import com.learnkit.backend.dto.WordBookStudySessionDto;
import com.learnkit.backend.exception.custom.UserNotFoundException;
import com.learnkit.backend.exception.custom.WordBookNotFoundException;
import com.learnkit.backend.exception.custom.WordBookStudySessionNotFoundException;
import com.learnkit.backend.repository.UserRepository;
import com.learnkit.backend.repository.WordBookRepository;
import com.learnkit.backend.repository.WordBookStudySessionRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Transactional
public class WordBookStudySessionService {

    private final WordBookStudySessionRepository wordBookStudySessionRepository;
    private final UserRepository userRepository;
    private final WordBookRepository wordBookRepository;

    /**
     * 단어장 학습 세션 시작
     */
    public WordBookStudySessionDto.Response startSession(Long userId, WordBookStudySessionDto.StartRequest requestDto) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException(userId));

        // 이미 진행 중인 세션 있는지 확인
        Optional<WordBookStudySession> activeSession = wordBookStudySessionRepository.findByUserIdAndEndedAtIsNull(userId);
        if (activeSession.isPresent()) {
            throw new IllegalStateException("이미 진행 중인 단어장 학습 세션이 있습니다.");
        }

        WordBook wordBook = wordBookRepository.findById(requestDto.getWordBookId())
                .orElseThrow(() -> new WordBookNotFoundException(requestDto.getWordBookId()));

        WordBookStudySession session = new WordBookStudySession(
                user,
                wordBook,
                requestDto.getHardCount(),
                requestDto.getNormalCount(),
                requestDto.getEasyCount()
        );
        WordBookStudySession savedSession = wordBookStudySessionRepository.save(session);

        return new WordBookStudySessionDto.Response(savedSession);
    }

    /**
     * 단어장 학습 세션 종료
     */
    public WordBookStudySessionDto.Response endSession(Integer sessionId, WordBookStudySessionDto.EndRequest requestDto) {
        WordBookStudySession session = wordBookStudySessionRepository.findById(sessionId)
                .orElseThrow(() -> new WordBookStudySessionNotFoundException(sessionId));

        if (!session.isInProgress()) {
            throw new IllegalStateException("이미 종료된 세션입니다.");
        }

        session.endSession(
                requestDto.getHardCount(),
                requestDto.getNormalCount(),
                requestDto.getEasyCount()
        );

        return new WordBookStudySessionDto.Response(session);
    }

    /**
     * 특정 사용자의 모든 세션 조회
     */
    public List<WordBookStudySessionDto.Response> findSessionsByUserId(Long userId) {
        List<WordBookStudySession> sessions = wordBookStudySessionRepository.findByUserId(userId);
        return sessions.stream()
                .map(WordBookStudySessionDto.Response::new)
                .toList();
    }

    /**
     * 진행 중인 세션 조회
     */
    public WordBookStudySessionDto.Response findActiveSession(Long userId) {
        WordBookStudySession session = wordBookStudySessionRepository.findByUserIdAndEndedAtIsNull(userId)
                .orElseThrow(() -> new WordBookStudySessionNotFoundException("진행 중인 세션이 없습니다."));
        return new WordBookStudySessionDto.Response(session);
    }

    /**
     * 세션 상세 조회
     */
    public WordBookStudySessionDto.Response findSessionById(Integer sessionId) {
        WordBookStudySession session = wordBookStudySessionRepository.findById(sessionId)
                .orElseThrow(() -> new WordBookStudySessionNotFoundException(sessionId));
        return new WordBookStudySessionDto.Response(session);
    }

    /**
     * 세션 삭제
     */
    public void deleteSession(Integer sessionId) {
        WordBookStudySession session = wordBookStudySessionRepository.findById(sessionId)
                .orElseThrow(() -> new WordBookStudySessionNotFoundException(sessionId));
        wordBookStudySessionRepository.delete(session);
    }

    /**
     * 학습 통계 조회 (특정 기간)
     */
    public WordBookStudySessionDto.StatisticsResponse getStatistics(Long userId, LocalDateTime start, LocalDateTime end) {
        List<WordBookStudySession> sessions = wordBookStudySessionRepository.findByUserIdAndStartedAtBetween(userId, start, end);

        int totalSessions = sessions.size();
        int totalMinutes = sessions.stream().mapToInt(WordBookStudySession::getDurationMinutes).sum();

        // 어려움 감소량 (start - end)
        int hardImprovement = sessions.stream()
                .mapToInt(s -> s.getStartHardCount() - s.getEndHardCount())
                .sum();

        // 쉬움 증가량 (end - start)
        int easyIncrease = sessions.stream()
                .mapToInt(s -> s.getEndEasyCount() - s.getStartEasyCount())
                .sum();

        return new WordBookStudySessionDto.StatisticsResponse(totalSessions, totalMinutes, hardImprovement, easyIncrease);
    }

    /**
     * 특정 단어장에 연결된 학습 세션 조회
     */
    public List<WordBookStudySessionDto.Response> findSessionsByWordBookId(Long wordBookId) {
        List<WordBookStudySession> sessions = wordBookStudySessionRepository.findByWordBookId(wordBookId);
        return sessions.stream()
                .map(WordBookStudySessionDto.Response::new)
                .toList();
    }
}