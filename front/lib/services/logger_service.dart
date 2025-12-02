import 'package:logger/logger.dart';

/// 앱 전역 로거 서비스
///
/// [logger] 패키지를 래핑하여 일관된 로깅 인터페이스 제공
/// - 개발 환경: 모든 로그 출력
/// - 프로덕션: warning 이상만 출력
///
/// 사용법:
/// ```dart
/// Log.d('디버그 메시지');
/// Log.i('정보 메시지');
/// Log.w('경고 메시지');
/// Log.e('에러 메시지', error, stackTrace);
/// ```
class Log {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0, // 호출 스택 표시 안함
      errorMethodCount: 5, // 에러 시 스택 5개 표시
      lineLength: 80, // 줄 길이
      colors: true, // 컬러 출력
      printEmojis: true, // 이모지 표시
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart, // 시간 표시
    ),
    level: Level.debug, // 디버그 레벨부터 출력
  );

  /// 디버그 로그 (개발용)
  static void d(String message) {
    _logger.d(message);
  }

  /// 정보 로그 (일반 정보)
  static void i(String message) {
    _logger.i(message);
  }

  /// 경고 로그 (주의 필요)
  static void w(String message) {
    _logger.w(message);
  }

  /// 에러 로그 (오류 발생)
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
