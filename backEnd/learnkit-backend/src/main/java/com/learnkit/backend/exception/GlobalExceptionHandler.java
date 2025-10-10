package com.learnkit.backend.exception;

import com.learnkit.backend.exception.custom.ScheduleNotFoundException;
import com.learnkit.backend.exception.custom.UserNotFoundException;
import com.learnkit.backend.exception.custom.WordBookNotFoundException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import java.time.LocalDateTime;


// 역할:
// - 전역 예외 처리기: 애플리케이션 전체에서 발생하는 예외를 한 곳에서 처리
// - 일관된 오류 응답: 모든 예외에 대해 동일한 형태의 응답 제공

// 과정:
// 1. 예외 발생: 어떤 컨트롤러에서 Schedule...Exception이 던져진다.
// 2. 예외 감지: @ExceptionHandler가 해당 예외를 감지한다.
// 3. 응답 생성: ErrorResponse 객체 생성 후 HTTP 응답으로 변환
// 4. 클라이언트 전달: 404 상태코드와 함께 JSON 응답 전송

/**
 * 애플리케이션 전체에서 발생하는 예외를 처리
 */
@RestControllerAdvice // 전체 컨트롤러에서 발생하는 예외를 잡아서 처리하는 클래스임을 Spring에게 알린다.
public class GlobalExceptionHandler {

    /**
     * 일정을 찾지 못할 때 발생하는 예외를 처리
     */
    @ExceptionHandler(ScheduleNotFoundException.class) // ScheduleNot...예외가 발생하면 이 메서드가 실행된다.
    public ResponseEntity<ErrorResponse> handleScheduleNotFound(ScheduleNotFoundException e) {

        ErrorResponse errorResponse = new ErrorResponse(
                HttpStatus.NOT_FOUND.value(),   // 404 상태코드
                e.getMessage(),                 // 예외에서 가져온 메시지
                LocalDateTime.now().toString()  // 현재 시간을 문자열로 변환
        );

        // HTTP 404 상태코드와 함께 ErrorResponse를 JSON으로 반환
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
    }

    /**
     * 사용자를 찾지 못할 때 발생하는 예외를 처리
     */
    @ExceptionHandler(UserNotFoundException.class) // UserNot...예외가 발생하면 이 메서드가 실행된다.
    public ResponseEntity<ErrorResponse> handleUserNotFound(UserNotFoundException e) {

        ErrorResponse errorResponse = new ErrorResponse(
                HttpStatus.NOT_FOUND.value(),   // 404 상태코드
                e.getMessage(),                 // 예외에서 가져온 메시지
                LocalDateTime.now().toString()  // 현재 시간을 문자열로 변환
        );

        // HTTP 404 상태코드와 함께 ErrorResponse를 JSON으로 반환
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
    }

    /**
     * 단어장을 찾지 못할 때 발생하는 예외를 처리
     */
    @ExceptionHandler(WordBookNotFoundException.class) // WordBookNot...예외가 발생하면 이 메서드가 실행된다.
    public ResponseEntity<ErrorResponse> handleWordBookNotFound(WordBookNotFoundException e) {

        ErrorResponse errorResponse = new ErrorResponse(
                HttpStatus.NOT_FOUND.value(),   // 404 상태코드
                e.getMessage(),                 // 예외에서 가져온 메시지
                LocalDateTime.now().toString()  // 현재 시간을 문자열로 변환
        );

        // HTTP 404 상태코드와 함께 ErrorResponse를 JSON으로 반환
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
    }
}
