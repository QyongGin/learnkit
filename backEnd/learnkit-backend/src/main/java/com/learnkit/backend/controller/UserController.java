package com.learnkit.backend.controller;

import com.learnkit.backend.dto.UserDto;
import com.learnkit.backend.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

// 클라이언트가 HTTP 요청을 보내면 Spring 서버가 @RestController가 붙은 UserController에서 이 요청을 처리할 메서드를 찾는다.
// 메서드는 Dto 객체를 생성해서 반환한다. @RestController 덕분에 Spring은 Dto 객체를 HTML로 바꾸지 않고 JSON 데이터로 자동 변환하여 클라이언트에게 응답한다.

@RestController // REST API 컨트롤러임을 Spring에게 알려서 메서드가 반환하는건 클라이언트에게 전달할 데이터라고 알린다.
@RequestMapping("/api") // 모든 메소드는 /api 라는 공통 주소를 갖는다.
@RequiredArgsConstructor // final 필드에 대한 생성자 생성
public class UserController {

    private final UserService userService; // 로직을 수행할 Service 가져오기

    // 사용자 조회 (ID로)
    @GetMapping("/users/{userId}")
    public ResponseEntity<UserDto.Response> getUserById(@PathVariable Long userId) {
        UserDto.Response responseDto = userService.findUserById(userId);
        return ResponseEntity.ok(responseDto);
    }

    // 사용자 조회 (이메일로) - 쿼리 파라미터 사용
    // @RequestParam은 URL의 쿼리파라미터(물음표 뒤의 값)를 매서드 파라미터로 받아오는 어노테이션
    // 예: GET /api/users/search?email=user@example.com
    @GetMapping("/users/search")
    public ResponseEntity<UserDto.Response> getUserByEmail(@RequestParam String email) {
        UserDto.Response responseDto = userService.findUserByEmail(email);
        return ResponseEntity.ok(responseDto);
    }

    // 프로필 수정
    @PatchMapping("/users/{userId}/profile")
    public ResponseEntity<UserDto.Response> updateProfile(
            @PathVariable Long userId,
            @RequestBody UserDto.UpdateProfileRequest requestDto) {
        UserDto.Response responseDto = userService.updateProfile(userId, requestDto);
        return ResponseEntity.ok(responseDto);
    }

    /**
     * 프로필 이미지 업데이트 (Supabase 업로드 후 호출)
     *
     * @param userId 사용자 ID
     * @param requestDto Supabase에서 받은 이미지 URL
     * @return 업데이트된 사용자 정보
     */
    @PatchMapping("/users/{userId}/profile-image")
    public ResponseEntity<UserDto.Response> updateProfileImage(
            @PathVariable Long userId,
            @RequestBody UserDto.UpdateProfileImageRequest requestDto) {
        UserDto.Response responseDto = userService.updateProfileImage(userId, requestDto);
        return ResponseEntity.ok(responseDto);
    }

    // 비밀번호 변경
    @PatchMapping("/users/{userId}/password")
    public ResponseEntity<Void> changePassword(
            @PathVariable Long userId,
            @RequestBody UserDto.ChangePasswordRequest requestDto) {
        userService.changePassword(userId, requestDto);
        // 비밀번호 변경 성공 시 204 No Content 응답
        return ResponseEntity.noContent().build();
    }
}