package com.learnkit.backend.service;

import com.learnkit.backend.domain.User;
import com.learnkit.backend.dto.UserDto;
import com.learnkit.backend.exception.custom.UserNotFoundException;
import com.learnkit.backend.repository.UserRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service // 비즈니스 로직을 담당하는 Service 컴포넌트임을 스프링에게 알린다.
@RequiredArgsConstructor // final 필드에 대한 생성자를 자동으로 만들어주는 롬복 어노테이션.
@Transactional // 감시하던 user 객체의 변화를 감지(Dirty Checking)하고 update 쿼리 실행.
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    // ID로 사용자 조회
    public UserDto.Response findUserById(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException(userId));
        return new UserDto.Response(user);
    }

    // 이메일로 사용자 조회
    public UserDto.Response findUserByEmail(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UserNotFoundException(email));
        return new UserDto.Response(user);
    }

    // 프로필 수정
    public UserDto.Response updateProfile(Long userId, UserDto.UpdateProfileRequest requestDto) {
        // 1. DB에서 영속 상태의 엔티티를 찾아옵니다.
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException(userId));

        // 2. 엔티티의 updateProfile 메서드를 호출하여 변경합니다.
        user.updateProfile(
                requestDto.getNickname(),
                requestDto.getProfileImageUrl()
        );

        // 3. @Transactional에 의해 메서드가 끝나면 변경된 내용이 자동으로 DB에 반영됩니다(UPDATE 쿼리).
        //    별도의 save() 호출이 필요 없습니다.

        // 4. 변경된 엔티티를 다시 DTO로 변환하여 컨트롤러에 반환합니다.
        return new UserDto.Response(user);
    }

    // 비밀번호 변경
    public void changePassword(Long userId, UserDto.ChangePasswordRequest requestDto) {
        // 1. DB에서 사용자를 찾아옵니다.
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException(userId));

        // 2. 현재 비밀번호가 일치하는지 확인합니다.
        // requestDto.getCurrentPassword() 사용자가 입력한 현재 비밀번호와 user.getPassword() DB에 저장된 비밀번호 비교
        if (!passwordEncoder.matches(requestDto.getCurrentPassword(), user.getPassword())) {
            throw new IllegalArgumentException("현재 비밀번호가 일치하지 않습니다.");
        }

        // 3. 새 비밀번호를 암호화합니다.
        String encodedNewPassword = passwordEncoder.encode(requestDto.getNewPassword());

        // 4. 엔티티의 changePassword 메서드를 호출하여 변경합니다.
        user.changePassword(encodedNewPassword);

        // 5. @Transactional에 의해 자동으로 DB에 반영됩니다.
    }
}