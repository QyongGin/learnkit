package com.learnkit.backend.service;

import com.learnkit.backend.domain.AppLaunch;
import com.learnkit.backend.domain.User;
import com.learnkit.backend.dto.AppLaunchDto;
import com.learnkit.backend.exception.custom.UserNotFoundException;
import com.learnkit.backend.repository.AppLaunchRepository;
import com.learnkit.backend.repository.UserRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 앱 실행 기록 및 사용 패턴 분석 비즈니스 로직
 */
@Service
@RequiredArgsConstructor
@Transactional
public class AppLaunchService {

    private final AppLaunchRepository appLaunchRepository;
    private final UserRepository userRepository;

    /**
     * 앱 실행 시간 기록
     * 사용자가 앱을 실행할 때마다 타임스탬프를 DB에 저장
     * 이 데이터는 사용 패턴 분석에 활용됨
     *
     * @param userId 사용자 ID
     */
    public void recordAppLaunch(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException(userId));

        // AppLaunch 엔티티 생성 시 현재 시간이 자동으로 기록됨
        AppLaunch appLaunch = new AppLaunch(user);
        appLaunchRepository.save(appLaunch);
    }

    /**
     * 주 사용 시간대 계산 (최근 30일 기준)
     * 최근 30일간의 앱 실행 패턴을 분석하여 가장 많이 사용하는 시간대를 찾음
     * 리마인더 발송 시간 추천에 활용 가능
     *
     * @param userId 사용자 ID
     * @return 피크 시간대 정보 및 추천 알림 시간
     */
    public AppLaunchDto.PeakHoursResponse calculatePeakHours(Long userId) {
        // 최근 30일간의 앱 실행 기록 조회
        LocalDateTime thirtyDaysAgo = LocalDateTime.now().minusDays(30); // 오늘 날짜에서 30일 뺀 결과
        List<AppLaunch> recentLaunches = appLaunchRepository.findRecentLaunches(userId, thirtyDaysAgo);

        // 시간대별 실행 횟수 집계 (0~23시)
        // hourCounts: { 9: 5, 14: 3, 20: 10}
        Map<Integer, Long> hourCounts = recentLaunches.stream()
                .collect(Collectors.groupingBy( // 괄호안 기준으로 그룹으로 묶고 결과를 하나로 모음
                        launch -> launch.getLaunchTime().getHour(), // launch의 시간을 기준으로 분류
                        Collectors.counting() // 데이터의 갯수를 셈
                ));

        // 가장 많이 사용하는 시간대 찾기
        int peakHour = hourCounts.entrySet().stream()
                .max(Map.Entry.comparingByValue()) // 횟수(Value)를 기준으로 크기 비교
                .map(Map.Entry::getKey) // 몇 시인지(Key)로 객체 모양을 바꾼다.
                .orElse(19);  // 기본값: 오후 7시 (데이터가 없을 경우)

        int launchCount = hourCounts.getOrDefault(peakHour, 0L).intValue(); // 가장 많이 접속한 시간대 찾고 횟수(Value)를 가져옴

        // 추천 알림 시간: 피크 시간 1시간 전
        // 예: 피크가 20시면 19시에 알림 발송
        LocalDateTime suggestedTime = LocalDateTime.now()
                .withHour(peakHour > 0 ? peakHour - 1 : 23) // 0(24시 자정)보다 크면 피크타임 -1 자정이라면 23시로 설정
                .withMinute(0)
                .withSecond(0);

        return new AppLaunchDto.PeakHoursResponse(peakHour, launchCount, suggestedTime);
    }
}