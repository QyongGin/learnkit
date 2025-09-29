package com.learnkit.backend.service;


import com.learnkit.backend.domain.Schedule;
import com.learnkit.backend.dto.ScheduleCreateRequestDto;
import com.learnkit.backend.dto.ScheduleUpdateRequestDto;
import com.learnkit.backend.repository.ScheduleRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service // 비즈니스 로직을 담당하는 Service 컴포넌트임을 스프링에게 알린다.
@RequiredArgsConstructor // final 필드에 대한 생성자를 자동으로 만들어주는 롬복 어노테이션.

public class ScheduleService {

    // service는 로직을 처리하고 repository에게 저장할 데이터를 준다.
    // 그러니 '저장'을 수행할 repository를 불러온다.
    // 이렇게 다른 부품을 가져와서 사용하는 것을 의존성 주입(Dependency Injection, DI)이라 한다.
    private final ScheduleRepository scheduleRepository;

    // 이제 이곳에 '일정 생성, 조회' 등의 메소드를 만든다.
    public Schedule createSchedule(ScheduleCreateRequestDto requestDto) {
        // 1. DTO를 Domain 객체(Schedule)로 변환한다.
        Schedule newSchedule = requestDto.toEntity();

        // 새로 생성되는 모든 일정의 주인(user_id)을 1번 유저(더미 유저)로 설정한다.
        newSchedule.setUserId(1L);

        // 2. Repository를 통해 데이터베이스에 저장하고 저장된 객체를 반환한다.
        // 2-1. save는 id가 null이라면 새로운 데이터라 판단하고 insert 쿼리 실행 후 id 값을 객체에 채워서 반환.
        // 2-2. id가 null이 아니라면 그에 맞는 컬럼에 update 쿼리 실행.
        return scheduleRepository.save(newSchedule);
    }

    // 조회
    public List<Schedule> findSchedulesByUserId(Long userId) {

        // Repository에게 userId를 주고 Id에 맞는 유저의 모든 스케줄을 가져오라 요청한다.
        return scheduleRepository.findAllByUserId(userId);
    }

    public Schedule findScheduleById(Long scheduleId) {
        return scheduleRepository.findById(scheduleId)
                // 존재하지 않다면 () 안의 람다식을 실행하고 던진다(Throw). 스프링은 클라이언트에게 500 에러를 보내게 된다.
                // "IllegalArgumentException"은 자바의 표준 예외로 '메소드에 부적절한 인자가 전달됐다'는 의미
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 일정입니다. Id: " + scheduleId));
    }

    // 이 메소드 안에서 일어나는 모든 DB 작업이 하나의 트랜잭션으로 묶인다.
    // 메서드가 끝나고 처음에 가져온 schedule 객체의 내용이 바뀌었다면 자동감지(Dirty Checking)하여
    // 바뀐 부분을 UPDATE 쿼리로 날린다. 따라서 직접 .save를 할 필요가 없다.
    @Transactional
    public Schedule updateSchedule(Long scheduleId, ScheduleUpdateRequestDto requestDto) {
        // 1. 수정할 일정을 DB에서 찾아온다. 없으면 예외 발생.
        Schedule schedule = scheduleRepository.findById(scheduleId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 일정입니다. Id: " + scheduleId ));
        // 2. DTO에 값이 있는 필드만 기존 일정의 내용을 변경한다.
        if (requestDto.getTitle() != null) {
            schedule.setTitle(requestDto.getTitle());
        }
        if (requestDto.getDescription() != null) {
            schedule.setDescription(requestDto.getDescription());
        }
        if (requestDto.getStartTime() != null) {
            schedule.setStartTime(requestDto.getStartTime());
        }
        if (requestDto.getEndTime() != null) {
            schedule.setEndTime(requestDto.getEndTime());
        }
        if (requestDto.getIsCompleted() != null) {
            schedule.setCompleted(requestDto.getIsCompleted());
        }

        return schedule;
    }

    public void deleteSchedule(Long scheduleId) {
        // 1. 삭제할 일정이 존재하는지 확인하고 없으면 예외.
        Schedule schedule = scheduleRepository.findById(scheduleId)
                .orElseThrow(() -> new IllegalArgumentException("삭제할 일정이 없습니다. Id: " + scheduleId));

        // 2. Repository를 통해 DB에서 해당 일정 삭제.
        scheduleRepository.delete(schedule);
    }
}
