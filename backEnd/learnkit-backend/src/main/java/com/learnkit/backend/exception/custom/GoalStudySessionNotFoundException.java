package com.learnkit.backend.exception.custom;

public class GoalStudySessionNotFoundException extends RuntimeException {
    public GoalStudySessionNotFoundException(Integer sessionId) {
        super("학습 세션을 찾을 수 없습니다. ID: " + sessionId);
    }

    public GoalStudySessionNotFoundException(String message) {
        super(message);
    }
}