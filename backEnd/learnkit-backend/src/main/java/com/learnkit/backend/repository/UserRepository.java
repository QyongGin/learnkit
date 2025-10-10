package com.learnkit.backend.repository;

import com.learnkit.backend.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
// <User> 이 repository가 관리할 대상
// 관리할 대상의 ID 필드 타입이 Long
public interface UserRepository extends JpaRepository<User, Long> {

    // 기본적인 CRUD 메소드(save, findById, findAll, deleteById 등)는
    // JpaRepository를 상속받으면 자동 구현된다.

    // 이메일로 사용자 찾기
    // SELECT * FROM users WHERE email = ?
    Optional<User> findByEmail(String email);
}