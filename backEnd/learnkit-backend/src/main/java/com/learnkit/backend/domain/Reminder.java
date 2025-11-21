package com.learnkit.backend.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * 리마인더 엔티티
 * 사용자에게 발송할 알림 정보 저장
 */
@Entity
@Getter
@NoArgsConstructor // DB에서 데이터를 나르기 위한 빈 객체 생성용
@Table(name = "reminders")
public class Reminder extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "schedule_id")
    private Schedule schedule;  // 연결된 스케줄

    @Column(nullable = false)
    private String message;  // 알림 메시지

    @Column(name = "notification_time", nullable = false)
    private LocalDateTime notificationTime;  // 알림 발송 시간

    // 생성자
    public Reminder(User user, String message, LocalDateTime notificationTime) {
        this.user = user;
        this.message = message;
        this.notificationTime = notificationTime;
    }

    // 스케줄 연결 생성자 - 할 일 등록 시 알림 발송
    public Reminder(User user, Schedule schedule, String message, LocalDateTime notificationTime) {
        this.user = user;
        this.schedule = schedule;
        this.message = message;
        this.notificationTime = notificationTime;
    }

    // 메시지 업데이트
    public void updateMessage(String newMessage) {
        this.message = newMessage;
    }

    // 알림 시간 업데이트
    public void updateNotificationTime(LocalDateTime newTime) {
        this.notificationTime = newTime;
    }
}