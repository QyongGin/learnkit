package com.learnkit.backend.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * 'schedules' 테이블의 데이터 구조를 나타내는 Domain 클래스.
 * JPA에서는 'Entity'라고 부르며, 데이터베이스 테이블과 직접 매핑된다.
 */

// 데이터베이스 테이블과 매핑되는 엔티티임을 알려준다.
@Entity

// 클래스 위에 이 어노테이션 하나만 붙이면 컴파일 시점에 모든 필드의 get() 메소드를 자동으로 만들어준다.
@Getter
@Setter

// 인자 없는 기본 생성자를 자동으로 만들어준다. public Schedule(){} 같은 코드.
// 이런 기본 생성자는JPA 같은 프레임워크가 객체 생성 시 내부적으로 꼭 필요하므로 붙여주는게 좋다.
@NoArgsConstructor

// Schedule 클래스를 보고 JAP는 테이블이 schedule이라 추측함. 정정.
@Table(name = "schedules")
public class Schedule {

    @Id // 이 필드가 테이블의 기본 키(Primary Key)임을 알려준다.
    @GeneratedValue(strategy = GenerationType.IDENTITY) // 기본 키 값을 DB가 자동 생성하도록 설정한다.
    private Long id; // 학습 일정 고유 식별자 (PK)

    // user_id는 나중에 User 엔티티와 연관관계를 맺을 때 처리.
    // private Long userId;

    // 학습 일정의 소유자
    private Long userId;

    // 일정의 제목
    private String title;

    @Lob // 상세 설명처럼 긴 텍스트를 위한 어노테이션.
    // 일정 설명
    private String description;

    // 시작 시각 (DB의 TIMESTAMP 타입은 자바의 LocalDateTime과 잘 매핑된다.)
    private LocalDateTime startTime;

    // 종료 시각
    private LocalDateTime endTime;

    // 일정 완료 여부
    private boolean isCompleted;

    // 일정 생성 일시
    private LocalDateTime createdAt;

    // 일정 수정 일시
    private LocalDateTime updatedAt;

    // DTO에서 Entity로 변환 시 사용할 생성자
    public Schedule(String title,String description, LocalDateTime startTime, LocalDateTime endTime) {
        this.title = title;
        this.description = description;
        this.startTime = startTime;
        this.endTime = endTime;
        this.isCompleted = false; // 새로 만들었으니 아직 미완료
    }


    @PrePersist // 엔티티가 save() 호출로 처음 저장되기 전에 실행된다.
    public void onPrePersist() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = this.createdAt;
    }
}



