package com.learnkit.backend.dto;

import com.learnkit.backend.domain.User;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * User(사용자) 관련 DTO들을 관리하는 클래스
 */
public class UserDto {

    /**
     * [응답용] 사용자 정보 응답을 위한 DTO
     */
    @Getter
    public static class Response {
        private final Long id;
        private final String email;
        private final String nickname;
        private final String profileImageUrl;

        public Response(User user) {
            this.id = user.getId();
            this.email = user.getEmail();
            this.nickname = user.getNickname();
            this.profileImageUrl = user.getProfileImageUrl();
        }
    }

    /**
     * [요청용] 프로필 수정을 위한 DTO
     */
    @Getter
    @Setter
    @NoArgsConstructor
    public static class UpdateProfileRequest {
        private String nickname;
        private String profileImageUrl;
    }

    /**
     * [요청용] 비밀번호 변경을 위한 DTO
     */
    @Getter
    @Setter
    @NoArgsConstructor
    public static class ChangePasswordRequest {
        private String currentPassword;  // 현재 비밀번호 (검증용)
        private String newPassword;       // 새 비밀번호
    }
}