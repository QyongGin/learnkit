package com.learnkit.backend.service;


import com.learnkit.backend.domain.Schedule;
import com.learnkit.backend.domain.User;
import com.learnkit.backend.dto.ScheduleDto;
import com.learnkit.backend.exception.custom.ScheduleNotFoundException;
import com.learnkit.backend.exception.custom.UserNotFoundException;
import com.learnkit.backend.repository.ScheduleRepository;
import com.learnkit.backend.repository.UserRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;

@Service // 비즈니스 로직을 담당하는 Service 컴포넌트임을 스프링에게 알린다.
@RequiredArgsConstructor // final 필드에 대한 생성자를 자동으로 만들어주는 롬복 어노테이션.
@Transactional  // 감시하던 schedule 객체의 변화를 감지(Dirty Checking)하고 update 쿼리 실행.
public class ScheduleService {

    // 컴파일 시 @RequiredArgsConstructor를 통해 롬북이 자동으로 생성자를 생성
    // Spring이 객체를 주입 -> 필드에 실제 객체 할당
    private final ScheduleRepository scheduleRepository;
    private final UserRepository userRepository;


    // 일정 생성
    public ScheduleDto.Response createSchedule(Long userId, ScheduleDto.CreateRequest requestDto) {
        // 사용자 정보 조회
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException(userId));

        // DTO를 Entity로 변환하고, 사용자 정보 설정
        Schedule schedule = requestDto.toEntity();
        schedule.setUser(user); // schedule이 속한 user 설정

        // DB에 저장, @LastModifiedDate에 의하여 BaseTimeEntity의 updatedAt도 저장
        Schedule savedSchedule = scheduleRepository.save(schedule);

        // Entity를 Response DTO로 변환하여 반환
        return new ScheduleDto.Response(savedSchedule);
    }

    // 모든 일정 조회
    public List<ScheduleDto.Response> findSchedulesByUserId(Long userId) {
        List<Schedule> schedules = scheduleRepository.findAllByUserId(userId);
        return schedules.stream()
                .map(ScheduleDto.Response::new)
                .toList();
    }

    // 일정 상세 조회
    public ScheduleDto.Response findScheduleById(Long scheduleId) {
        Schedule schedule = scheduleRepository.findById(scheduleId)
                // 해당하는 일정이 없다면 람다식으로 예외를 만든 후 호출한 곳으로 예외를 던진다.
                .orElseThrow(() -> new ScheduleNotFoundException(scheduleId)); // 커스텀 예외
        return new ScheduleDto.Response(schedule);
    }

    // 일정 수정
    public ScheduleDto.Response updateSchedule(Long scheduleId, ScheduleDto.UpdateRequest requestDto) {
        // DB에서 영속 상태의 엔티티를 찾아옵니다.
        Schedule schedule = scheduleRepository.findById(scheduleId)
                .orElseThrow(() -> new ScheduleNotFoundException(scheduleId));

        // Entity는 Dto를 알 필요가 없으니 직접 분해해서 값을 보내준다.
        // DTO를 알게되면 의존하게 되어 다른 프로젝트에서 재사용이 불가능하고 테스트에 DTO가 꼭 필요해져서 어려워진다.
        schedule.update(
                requestDto.getTitle(),
                requestDto.getDescription(),
                requestDto.getStartTime(),
                requestDto.getEndTime(),
                requestDto.getIsCompleted()
        );

        //  @Transactional에 의해 메서드가 끝나면 변경된 내용이 자동으로 DB에 반영됩니다(UPDATE 쿼리).
        //  별도의 save() 호출이 필요 없습니다.

        // 변경된 엔티티를 다시 DTO로 변환하여 컨트롤러에 반환합니다.
        return new ScheduleDto.Response(schedule);
    }

    // 일정 삭제
    public void deleteSchedule(Long scheduleId) {
        Schedule schedule = scheduleRepository.findById(scheduleId)
                .orElseThrow(() -> new ScheduleNotFoundException(scheduleId));
        scheduleRepository.delete(schedule);
    }
}
