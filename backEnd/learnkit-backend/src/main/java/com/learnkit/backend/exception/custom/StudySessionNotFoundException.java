package com.learnkit.backend.exception.custom;

public class StudySessionNotFoundException extends RuntimeException {
    public StudySessionNotFoundException(Long sessionId) {
        super("StudySession not found with id: " + sessionId);
    }

    public StudySessionNotFoundException(String message) {
        super(message);
    }
}