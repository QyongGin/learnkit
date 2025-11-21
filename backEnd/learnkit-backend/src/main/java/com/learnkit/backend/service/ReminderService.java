package com.learnkit.backend.service;

import com.learnkit.backend.domain.Reminder;
import com.learnkit.backend.domain.Schedule;
import com.learnkit.backend.domain.User;
import com.learnkit.backend.dto.ReminderDto;
import com.learnkit.backend.exception.custom.UserNotFoundException;
import com.learnkit.backend.repository.ReminderRepository;
import com.learnkit.backend.repository.ScheduleRepository;
import com.learnkit.backend.repository.UserRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 리마인더 관련 비즈니스 로직
 */
@Service
@RequiredArgsConstructor
@Transactional
public class ReminderService {

    private final ReminderRepository reminderRepository;
    private final UserRepository userRepository;
    private final ScheduleRepository scheduleRepository;

    /**
     * 리마인더 생성
     */
    public ReminderDto.Response createReminder(Long userId, ReminderDto.CreateRequest requestDto) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException(userId));

        Schedule schedule = null;
        if (requestDto.getScheduleId() != null) {
            schedule = scheduleRepository.findById(requestDto.getScheduleId())
                    .orElse(null);
        }

        Reminder reminder = new Reminder(user, schedule, requestDto.getMessage(), requestDto.getNotificationTime());
        Reminder savedReminder = reminderRepository.save(reminder);

        return new ReminderDto.Response(savedReminder);
    }

    /**
     * 특정 사용자의 리마인더 조회
     */
    public List<ReminderDto.Response> getUserReminders(Long userId) {
        List<Reminder> reminders = reminderRepository.findByUserId(userId);
        return reminders.stream()
                .map(ReminderDto.Response::new)
                .toList();
    }

    /**
     * 다가오는 리마인더 조회 (다음 7일 이내)
     */
    public List<ReminderDto.Response> getUpcomingReminders(Long userId) {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime sevenDaysLater = now.plusDays(7);

        List<Reminder> reminders = reminderRepository.findUpcomingReminders(userId, now, sevenDaysLater);
        return reminders.stream()
                .map(ReminderDto.Response::new)
                .toList();
    }

    /**
     * 리마인더 수정
     * PATCH 요청이므로 null이 아닌 필드만 업데이트
     */
    public ReminderDto.Response updateReminder(Integer reminderId, ReminderDto.UpdateRequest requestDto) {
        Reminder reminder = reminderRepository.findById(reminderId)
                .orElseThrow(() -> new IllegalArgumentException("리마인더를 찾을 수 없습니다: " + reminderId));

        // null이 아닌 필드만 업데이트 (Dirty Checking)
        if (requestDto.getMessage() != null) {
            reminder.updateMessage(requestDto.getMessage());
        }
        if (requestDto.getNotificationTime() != null) {
            reminder.updateNotificationTime(requestDto.getNotificationTime());
        }

        return new ReminderDto.Response(reminder);
    }

    /**
     * 리마인더 삭제
     */
    public void deleteReminder(Integer reminderId) {
        if (!reminderRepository.existsById(reminderId)) {
            throw new IllegalArgumentException("리마인더를 찾을 수 없습니다: " + reminderId);
        }
        reminderRepository.deleteById(reminderId);
    }
}