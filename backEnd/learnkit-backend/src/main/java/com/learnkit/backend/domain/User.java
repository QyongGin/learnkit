package com.learnkit.backend.domain;


import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@NoArgsConstructor
@Table(name="users")
public class User extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY) // 기본 키 값을 DB가 컬럼 기능에 맞게 자동 생성하도록 설정한다.
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String password;

    @Column(nullable = false)
    private String nickname;

    @Lob
    private String profileImageUrl;

    // createdAt, updatedAt 필드는 BaseTimeEntity로부터 상속받아 자동 처리됨.

    public void updateProfile(String newNickname, String newProfileImageUrl) {
        if (newNickname != null) {
            this.nickname = newNickname;
    }
        if (newProfileImageUrl != null) {
            this.profileImageUrl = newProfileImageUrl;
        }
    }

    // encodedPassword: 이미 암호화된 비밀번호
    // Service 계층에서 PasswordEncoder로 암호화한 후 전달받는다.
    public void changePassword(String encodedPassword) {
        this.password = encodedPassword;
    }
}
