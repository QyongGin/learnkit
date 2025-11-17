package com.learnkit.backend.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter
@Entity
@Table(name = "goals")
@NoArgsConstructor // 파라미터가 없는 기본 생성자. JPA가 DB에서 데이터를 가져오기 위한 빈 박스 생성.
public class Goal extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY) // N:1 관계, 지연로딩 방식
    @JoinColumn(name = "user_id", nullable = false) // 컬럼 매핑
    private User user;

    @Column(nullable = false)
    private String title;

    private LocalDate startDate;

    private LocalDate endDate;

    @Column(nullable = false)
    private int totalTargetAmount;

    @Column(nullable = false, length = 50) // 더 줄일만함
    private String targetUnit;

    @Column(nullable = false)
    private int currentProgress = 0;

    @Column(nullable = false)
    private boolean isCompleted = false;

    private LocalDateTime completedAt;

    // 생성자
    public Goal(String title, LocalDate startDate, LocalDate endDate, int totalTargetAmount, String targetUnit) {
        this.title = title;
        this.startDate = startDate;
        this.endDate = endDate;
        this.totalTargetAmount = totalTargetAmount;
        this.targetUnit = targetUnit;
    }

    public void setUser(User user) {
        this.user = user;
    }

    // 진행도 업데이트
    public void addProgress(int amount) {
        this.currentProgress += amount; // 학습 종료 후 사용자가 입력

        // 이번 학습으로 목표치 달성 시
        if (this.currentProgress >= this.totalTargetAmount && !this.isCompleted) {
            this.isCompleted = true;
            this.completedAt = LocalDateTime.now();
        }
    }

    // 학습 목표 수정
    public void update(String title, LocalDate startDate, LocalDate endDate, Integer totalTargetAmount, String targetUnit){

        // 입력한 필드만 수정
        if (title != null) this.title = title;
        if (startDate != null) this.startDate = startDate;
        if (endDate != null) this.endDate = endDate;
        if (totalTargetAmount != null) this.totalTargetAmount = totalTargetAmount;
        if (targetUnit != null) this.targetUnit = targetUnit;

    }

}
