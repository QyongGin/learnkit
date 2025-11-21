package com.learnkit.backend.repository;

import com.learnkit.backend.domain.Reminder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 리마인더 Repository
 */
@Repository
public interface ReminderRepository extends JpaRepository<Reminder, Integer> {

    /**
     * 특정 사용자의 모든 리마인더 조회
     */
    List<Reminder> findByUserId(Long userId);

    /**
     * 특정 시간 이후의 리마인더 조회 (미래 알림)
     */
    List<Reminder> findByUserIdAndNotificationTimeAfter(Long userId, LocalDateTime time);

    /**
     * 특정 기간 동안 발송될 리마인더 조회
     */
    @Query("SELECT r FROM Reminder r WHERE r.user.id = :userId AND r.notificationTime BETWEEN :start AND :end ORDER BY r.notificationTime ASC")
    List<Reminder> findUpcomingReminders(@Param("userId") Long userId, @Param("start") LocalDateTime start, @Param("end") LocalDateTime end);

    /**
     * 특정 스케줄에 연결된 리마인더 조회
     */
    List<Reminder> findByScheduleId(Long scheduleId);
}