package com.learnkit.backend.exception.custom;

/**
 * 일정을 찾지 못할 때 발생하는 예외
 */
public class ScheduleNotFoundException extends RuntimeException {
    // RuntimeException을 상속받아 언체크드 예외로 동작함.
    // 컴파일 시점에 예외 처리를 강제하지 않음.

    /**
     * 일정을 찾지 못했을 때 예외를 생성함.
     *
     * @param scheduleId 찾지 못한 일정의 ID
     */
    public ScheduleNotFoundException (Long scheduleId) {
        super("해당 일정을 찾을 수 없습니다. id=" + scheduleId);
    }
}
