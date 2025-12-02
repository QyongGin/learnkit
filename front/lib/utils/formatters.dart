import '../models/card.dart';

/// 날짜 관련 유틸리티 함수
class AppDateUtils {
  AppDateUtils._();

  /// DateTime을 'yyyy.MM.dd' 형식으로 변환
  static String formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  /// 날짜 범위를 문자열로 변환
  /// 예: "2025.01.01 ~ 2025.12.31"
  static String formatDateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '';
    if (start != null && end != null) {
      return '${formatDate(start)} ~ ${formatDate(end)}';
    } else if (start != null) {
      return '${formatDate(start)} ~';
    } else {
      return '~ ${formatDate(end!)}';
    }
  }

  /// 시간을 'HH:mm' 형식으로 변환
  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// 초를 'MM:SS' 형식으로 변환 (타이머용)
  static String formatSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Duration을 'HH:mm:ss' 형식으로 변환
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// DateTime을 시간 없이 날짜만으로 정규화
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

/// 난이도 관련 유틸리티 함수
class DifficultyUtils {
  DifficultyUtils._();

  /// 난이도를 숫자값으로 변환 (정렬용)
  static int toValue(CardDifficulty? difficulty) {
    switch (difficulty) {
      case CardDifficulty.HARD:
        return 3;
      case CardDifficulty.NORMAL:
        return 2;
      case CardDifficulty.EASY:
        return 1;
      default:
        return 0;
    }
  }

  /// 난이도를 한글 라벨로 변환
  static String toLabel(CardDifficulty? difficulty) {
    switch (difficulty) {
      case CardDifficulty.EASY:
        return '쉬움';
      case CardDifficulty.NORMAL:
        return '보통';
      case CardDifficulty.HARD:
        return '어려움';
      default:
        return '-';
    }
  }
}

/// 숫자 관련 유틸리티 함수  
class NumberUtils {
  NumberUtils._();

  /// 퍼센트 계산 (0으로 나누기 방지)
  static double calculatePercentage(int current, int total) {
    if (total == 0) return 0;
    return (current / total * 100).clamp(0, 100);
  }

  /// 퍼센트를 문자열로 변환 (소수점 제거)
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(0)}%';
  }
}
