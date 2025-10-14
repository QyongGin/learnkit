import 'card.dart';

/// 단어장 모델
class WordBook {
  final int id;
  final String title;
  final int easyIntervalMinutes;
  final int normalIntervalMinutes;
  final int hardIntervalMinutes;

  // 통계 정보 (카드 난이도별 개수)
  final CardStatistics? statistics;

  WordBook({
    required this.id,
    required this.title,
    this.easyIntervalMinutes = 20,
    this.normalIntervalMinutes = 10,
    this.hardIntervalMinutes = 3,
    this.statistics,
  });

  factory WordBook.fromJson(Map<String, dynamic> json) {
    return WordBook(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      easyIntervalMinutes: json['easyIntervalMinutes'] ?? 20,
      normalIntervalMinutes: json['normalIntervalMinutes'] ?? 10,
      hardIntervalMinutes: json['hardIntervalMinutes'] ?? 3,
      statistics: json['statistics'] != null
          ? CardStatistics.fromJson(json['statistics'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'easyIntervalMinutes': easyIntervalMinutes,
      'normalIntervalMinutes': normalIntervalMinutes,
      'hardIntervalMinutes': hardIntervalMinutes,
    };
  }

  /// 통계 정보가 있는 WordBook 복사본 생성
  WordBook copyWithStatistics(CardStatistics statistics) {
    return WordBook(
      id: id,
      title: title,
      easyIntervalMinutes: easyIntervalMinutes,
      normalIntervalMinutes: normalIntervalMinutes,
      hardIntervalMinutes: hardIntervalMinutes,
      statistics: statistics,
    );
  }
}
