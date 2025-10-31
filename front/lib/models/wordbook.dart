import 'card.dart';

/// 단어장 모델
class WordBook {
  final int id;
  final String title;
  final String? description;      // 단어장 설명 (선택사항)
  final int easyFrequencyRatio;   // 쉬움 빈도 비율 (기본: 1배)
  final int normalFrequencyRatio; // 보통 빈도 비율 (기본: 3배)
  final int hardFrequencyRatio;   // 어려움 빈도 비율 (기본: 6배)

  // 통계 정보 (카드 난이도별 개수)
  final CardStatistics? statistics;

  WordBook({
    required this.id,
    required this.title,
    this.description,
    this.easyFrequencyRatio = 1,
    this.normalFrequencyRatio = 3,
    this.hardFrequencyRatio = 6,
    this.statistics,
  });

  factory WordBook.fromJson(Map<String, dynamic> json) {
    return WordBook(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      description: json['description'],
      easyFrequencyRatio: json['easyFrequencyRatio'] ?? 1,
      normalFrequencyRatio: json['normalFrequencyRatio'] ?? 3,
      hardFrequencyRatio: json['hardFrequencyRatio'] ?? 6,
      statistics: json['statistics'] != null
          ? CardStatistics.fromJson(json['statistics'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'easyFrequencyRatio': easyFrequencyRatio,
      'normalFrequencyRatio': normalFrequencyRatio,
      'hardFrequencyRatio': hardFrequencyRatio,
    };
  }

  /// 통계 정보가 있는 WordBook 복사본 생성
  WordBook copyWithStatistics(CardStatistics statistics) {
    return WordBook(
      id: id,
      title: title,
      description: description,
      easyFrequencyRatio: easyFrequencyRatio,
      normalFrequencyRatio: normalFrequencyRatio,
      hardFrequencyRatio: hardFrequencyRatio,
      statistics: statistics,
    );
  }
}
