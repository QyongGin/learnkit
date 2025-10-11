package com.learnkit.backend.exception.custom;

/**
 * 카드를 찾지 못할 때 발생하는 예외
 */
public class CardNotFoundException extends RuntimeException {
    // RuntimeException을 상속받아 언체크드 예외로 동작함.
    // 컴파일 시점에 예외 처리를 강제하지 않음.

    /**
     * 카드를 찾지 못했을 때 예외를 생성함.
     *
     * @param cardId 찾지 못한 카드의 ID
     */
    public CardNotFoundException(Long cardId) {
        super("해당 카드를 찾을 수 없습니다. id=" + cardId);
    }
}