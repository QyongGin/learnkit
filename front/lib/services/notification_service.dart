// 로컬 푸시 알림 라이브러리
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// 타임존 처리
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
// Flutter 기본 위젯
import 'package:flutter/foundation.dart';

/// 로컬 푸시 알림 서비스
/// - 앱 종료 후에도 알림 전송 가능 (백그라운드 상태에서)
/// - iOS: 앱 강제 종료 시 알림 취소됨
/// - Android: 앱 종료 후에도 정상 작동
class NotificationService {
  // FlutterLocalNotificationsPlugin 싱글톤 인스턴스
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // 서비스 초기화 여부
  static bool _initialized = false;

  /// 알림 서비스 초기화
  ///
  /// 앱 시작 시 main.dart에서 호출
  /// - Android 알림 채널 설정
  /// - iOS 알림 권한 요청
  /// - 타임존 초기화
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 타임존 데이터 초기화 (스케줄 알림용)
      tz.initializeTimeZones();
      // 로컬 타임존 설정 (Asia/Seoul)
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

      // Android 초기화 설정
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS 초기화 설정
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true, // 알림 표시 권한 요청
        requestBadgePermission: true, // 뱃지 권한 요청
        requestSoundPermission: true, // 사운드 권한 요청
      );

      // 플랫폼별 초기화 설정 통합
      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // 알림 플러그인 초기화
      await _notifications.initialize(
        settings,
        // 알림 탭 시 실행될 콜백 (현재는 미사용)
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Android 13+ 알림 권한 요청
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      _initialized = true;
      debugPrint('✅ 알림 서비스 초기화 완료');
    } catch (e) {
      debugPrint('❌ 알림 서비스 초기화 실패: $e');
    }
  }

  /// 알림 탭 시 실행되는 콜백
  ///
  /// 사용자가 알림을 탭했을 때 앱을 특정 화면으로 이동시킬 수 있음
  /// 현재는 로그만 출력
  static void _onNotificationTap(NotificationResponse response) {
    debugPrint('알림 탭됨: ${response.payload}');
    // TODO: 알림 탭 시 특정 화면으로 네비게이션 추가 가능
  }

  /// 모든 예약된 알림 취소
  ///
  /// 용도:
  /// - 자동 알림 토글 OFF 시
  /// - 새로운 알림 스케줄 설정 전
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('🔕 모든 알림 취소됨');
  }

  /// 매일 반복 알림 예약 (특정 시간)
  ///
  /// 매개변수:
  /// - hour: 알림 시간 (0-23)
  /// - minute: 알림 분 (0-59)
  /// - message: 알림 메시지
  ///
  /// 예: scheduleDailyNotification(19, 0, "공부할 시간이에요!")
  ///     → 매일 오후 7시에 알림
  static Future<void> scheduleDailyNotification({
    required int hour,
    required int minute,
    required String message,
  }) async {
    // 오늘 날짜 기준으로 알림 시간 생성
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // 이미 시간이 지났다면 내일로 설정
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Android 알림 상세 설정
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'daily_reminder', // 채널 ID
      '학습 알림', // 채널 이름
      channelDescription: '매일 학습 시간 알림', // 채널 설명
      importance: Importance.high, // 중요도 (헤드업 알림)
      priority: Priority.high, // 우선순위
      icon: '@mipmap/ic_launcher', // 알림 아이콘
    );

    // iOS 알림 상세 설정
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true, // 포그라운드에서도 알림 표시
      presentBadge: true, // 뱃지 표시
      presentSound: true, // 사운드 재생
    );

    // 플랫폼별 설정 통합
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 매일 반복 알림 예약 (ID: 0)
    await _notifications.zonedSchedule(
      0, // 알림 ID (고유값)
      'LearnKit', // 알림 제목
      message, // 알림 내용
      scheduledDate, // 첫 알림 시간
      details, // 알림 설정
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // exact: 정확한 시간에 알림
      // allowWhileIdle: 절전 모드에서도 알림
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 시간 기준 매일 반복
    );

    debugPrint(
        '🔔 매일 알림 예약: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} - "$message"');
  }


  /// 즉시 알림 전송 (테스트용)
  ///
  /// 매개변수:
  /// - title: 알림 제목
  /// - body: 알림 내용
  static Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'immediate_notification',
      '즉시 알림',
      channelDescription: '즉시 전송되는 테스트 알림',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999, // 테스트용 고유 ID
      title,
      body,
      details,
    );

    debugPrint('🔔 즉시 알림 전송: $title - $body');
  }
}
