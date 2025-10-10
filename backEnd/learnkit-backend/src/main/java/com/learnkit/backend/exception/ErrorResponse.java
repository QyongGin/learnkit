package com.learnkit.backend.exception;

import lombok.AllArgsConstructor; // 모든 필드를 매개변수로 하는 생성자 자동 생성
import lombok.Getter;

//
//

// 동작 과정
// 1. 예외 발생 -> ScheduleNotFoundException 던져짐
// 2. GlobalExceptionHandler가 예외를 잡아서 처리한다.
// 3. ErrorResponse를 생성하고 상태코드, 메시지, 시간을 담는다.
// 4. 클라이언트에게 ErrorResponse의 필드와 같은 JSON 형태로 전달한다.

/**
 * API 오류 응답의 표준 형식을 정의한다.
 */
@Getter
@AllArgsConstructor
public class ErrorResponse {

    // 클라이언트가 일관된 형태로 오류 정보를 받게 한다.
    private int status;         // HTTP 상태 코드 (404: Not Found, 500: Internal Server Error)
    private String message;     // 오류 메시지 (예 : "해당 일정이 없습니다.")
    private String timestamp;   // ISO 8601 형식의 오류 발생 시간
}
