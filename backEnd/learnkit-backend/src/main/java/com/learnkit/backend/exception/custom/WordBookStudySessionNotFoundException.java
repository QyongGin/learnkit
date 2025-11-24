package com.learnkit.backend.exception.custom;

public class WordBookStudySessionNotFoundException extends RuntimeException {
    public WordBookStudySessionNotFoundException(Integer sessionId) {
        super("단어장 학습 세션을 찾을 수 없습니다. ID: " + sessionId);
    }

    public WordBookStudySessionNotFoundException(String message) {
        super(message);
    }
}