package com.learnkit.backend.exception.custom;

/**
 * 잘못된 요청이 발생했을 때 던지는 예외
 */
public class InvalidRequestException extends RuntimeException {
    // RuntimeException을 상속받아 언체크드 예외로 동작함.
    // 컴파일 시점에 예외 처리를 강제하지 않음.

    /**
     * 잘못된 요청이 발생했을 때 예외를 생성함.
     *
     * @param message 예외 메시지
     */
    public InvalidRequestException(String message) {
        super(message);
    }
}
