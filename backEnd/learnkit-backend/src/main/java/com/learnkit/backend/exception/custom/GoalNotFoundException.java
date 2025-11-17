package com.learnkit.backend.exception.custom;

public class GoalNotFoundException extends RuntimeException{
    public GoalNotFoundException(Integer goalId) {
        super("Goal not found with id: " + goalId);
    }
}
