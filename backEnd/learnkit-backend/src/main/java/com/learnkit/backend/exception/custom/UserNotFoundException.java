package com.learnkit.backend.exception.custom;

/**
 * 사용자를 찾지 못할 때 발생하는 예외
 */
public class UserNotFoundException extends RuntimeException {
    // RuntimeException을 상속받아 언체크드 예외로 동작함.
    // 컴파일 시점에 예외 처리를 강제하지 않음.

    /**
     * 사용자를 찾지 못했을 때 예외를 생성함.
     *
     * @param userId 찾지 못한 사용자의 ID
     */
    public UserNotFoundException(Long userId) {
        super("해당 사용자를 찾을 수 없습니다. id=" + userId);
    }

    /**
     * 이메일로 사용자를 찾지 못했을 때 예외를 생성함.
     *
     * @param email 찾지 못한 사용자의 이메일
     */
    public UserNotFoundException(String email) {
        super("해당 사용자를 찾을 수 없습니다. email=" + email);
    }
}