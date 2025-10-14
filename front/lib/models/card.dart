/// 단어 카드 모델
class Card {
  final int id;
  final String frontText; // 앞면 (질문/단어)
  final String backText; // 뒷면 (답/뜻)
  final DateTime nextReviewAt; // 다음 복습 시간
  final CardDifficulty? difficulty; // 난이도

  Card({
    required this.id,
    required this.frontText,
    required this.backText,
    required this.nextReviewAt,
    this.difficulty,
  });

  factory Card.fromJson(Map<String, dynamic> json) {
    return Card(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      frontText: json['frontText'] ?? '',
      backText: json['backText'] ?? '',
      nextReviewAt: json['nextReviewAt'] != null
          ? DateTime.parse(json['nextReviewAt'])
          : DateTime.now(),
      difficulty: json['difficulty'] != null
          ? CardDifficulty.values.firstWhere(
              (e) => e.name.toUpperCase() == json['difficulty'].toString().toUpperCase(),
              orElse: () => CardDifficulty.NORMAL,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frontText': frontText,
      'backText': backText,
    };
  }
}

/// 카드 난이도 (백엔드 Enum과 일치)
enum CardDifficulty {
  EASY,
  NORMAL,
  HARD,
}

/// 카드 상세 정보 (통계/관리용)
class CardDetail extends Card {
  final DateTime? lastReviewedAt; // 마지막 복습 시간
  final int viewCount; // 조회 횟수
  final DateTime createdAt;
  final DateTime updatedAt;

  CardDetail({
    required super.id,
    required super.frontText,
    required super.backText,
    required super.nextReviewAt,
    super.difficulty,
    this.lastReviewedAt,
    required this.viewCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CardDetail.fromJson(Map<String, dynamic> json) {
    return CardDetail(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      frontText: json['frontText'] ?? '',
      backText: json['backText'] ?? '',
      nextReviewAt: json['nextReviewAt'] != null
          ? DateTime.parse(json['nextReviewAt'])
          : DateTime.now(),
      difficulty: json['difficulty'] != null
          ? CardDifficulty.values.firstWhere(
              (e) => e.name.toUpperCase() == json['difficulty'].toString().toUpperCase(),
              orElse: () => CardDifficulty.NORMAL,
            )
          : null,
      lastReviewedAt: json['lastReviewedAt'] != null
          ? DateTime.parse(json['lastReviewedAt'])
          : null,
      viewCount: json['viewCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}

/// 카드 난이도별 통계
class CardStatistics {
  final int easyCount; // 쉬움
  final int normalCount; // 보통
  final int hardCount; // 어려움
  final int totalCount; // 전체

  CardStatistics({
    required this.easyCount,
    required this.normalCount,
    required this.hardCount,
    required this.totalCount,
  });

  factory CardStatistics.fromJson(Map<String, dynamic> json) {
    return CardStatistics(
      easyCount: json['easyCount'] ?? 0,
      normalCount: json['normalCount'] ?? 0,
      hardCount: json['hardCount'] ?? 0,
      totalCount: json['totalCount'] ?? 0,
    );
  }

  /// 빈 통계 생성
  factory CardStatistics.empty() {
    return CardStatistics(
      easyCount: 0,
      normalCount: 0,
      hardCount: 0,
      totalCount: 0,
    );
  }
}
