package com.learnkit.backend.repository;

import com.learnkit.backend.domain.Schedule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository // 인터페이스가 데이터 접근 계층(Repository)의 컴포넌트임을 스프링에게 알린다.

// <Schedule> 이 repository가 관리할 대상, 엔티티가 Schedule임을 알려준다.
// Long 관리할 대상의 ID 필드 타입이 Long임을 알린다.
public interface ScheduleRepository extends JpaRepository<Schedule, Long> {

    // 기본적인 CRUD 메소드(save, findById, findAll, deleteById 등)는
    // JpaRepository를 상속받으면 자동 구현된다.

    // 그러므로 남은 이곳에 '월별 일정 조회' 같은 커스텀 메소드를 추가하게 된다.

    // JpaRepository는 findById나 findAll 같은 기본 메소드만 제공한다.
    // userId로 모든 일정 찾기 메소드를 직접 정의한다.

    // 'findBy' + '필드이름' 규칙에 따라 메서드 이름을 지으면
    // Spring Data JPA가 알아서 SQL 쿼리를 자동으로 만든다.
    // SELECT * FROM schedules WHERE user_id = ?
    List<Schedule> findAllByUserId(Long userId);
}
