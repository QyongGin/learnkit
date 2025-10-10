package com.learnkit.backend.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;


@Entity
@Getter
@NoArgsConstructor // 기본 생성자 생성.
@Table(name = "schedules")
public class Schedule extends BaseTimeEntity{

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY) // 기본 키 값을 DB가 컬럼 기능에 맞게 자동 생성하도록 설정한다.
    private Long id; // 학습 일정 고유 식별자 (PK)

    // fetch: JPA에게 연관된 엔티티(User)를 DB에서 어떤 방식과 시점에 가져올지를 설정하는 옵션. 가져오기 방식.
    // FetchType: fetch 방식의 종류를 모은 클래스. 가져오기 유형. LAZY,EAGER
    // LAZY: fetch의 구체적인 방식을 지연 로딩(Lazy Loading)으로 선택.
    // User 정보가 필요 없다면 JOIN 시키지 않는다. 앱 성능 향상. getUser().getNickName()처럼 필드에 실제로 접근할 시 JOIN 그 전까지는 가짜 객체(프록시)
    @ManyToOne(fetch = FetchType.LAZY) // User와 다대일 관계 설정 N(Schedule) : 1(USer)
    @JoinColumn(name = "user_id")      // DB의 user_id 컬럼과 매핑
    private User user;                 // User 객체를 직접 참조

    @Column(nullable = false)
    private String title;

    @Lob // TEXT 타입과 매핑되며 긴 텍스트가 필요하다면 사용한다.
    private String description;

    @Column(nullable = false)
    private LocalDateTime startTime;

    @Column(nullable = false)
    private LocalDateTime endTime;

    private boolean isCompleted;

    // DTO에서 Entity로 변환 시 사용할 생성자
    public Schedule(String title,String description, LocalDateTime startTime, LocalDateTime endTime) {
        this.title = title;
        this.description = description;
        this.startTime = startTime;
        this.endTime = endTime;
        this.isCompleted = false;
    }

    public void setUser(User user) {
        this.user = user;
    }

    // 갱신
    public void update(String title, String description, LocalDateTime startTime, LocalDateTime endTime, Boolean isCompleted) {
        // PATCH 동작을 위해 null이 아닌 값만 변경
        if (title != null) {
            this.title = title;
        }
        if (description != null) {
            this.description = description;
        }
        if (startTime != null) {
            this.startTime = startTime;
        }
        if (endTime != null) {
            this.endTime = endTime;
        }
        if (isCompleted != null) {
            this.isCompleted = isCompleted;
        }
    }
}



