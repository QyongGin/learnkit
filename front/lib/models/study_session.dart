/// 학습 세션 모델
class StudySession {
  final int id;
  // 목표 학습 (Pomodoro) 관련
  final int? goalId;
  final String? goalTitle;
  final int pomoCount;
  final int achievedAmount;
  
  // 단어장 학습 (WordBook) 관련
  final int? wordBookId;
  final String? wordBookTitle;
  final int? totalCards;
  final int? learnedCards;
  final int? reviewCards;
  final int? difficultCards;
  
  // 단어장 난이도 변화 추적
  final int? startHardCount;
  final int? startNormalCount;
  final int? startEasyCount;
  final int? endHardCount;
  final int? endNormalCount;
  final int? endEasyCount;

  // 공통 필드
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationMinutes;
  final String? note;
  final bool inProgress;
  final String type; // 'GOAL' or 'WORDBOOK'

  StudySession({
    required this.id,
    this.goalId,
    this.goalTitle,
    this.pomoCount = 0,
    this.achievedAmount = 0,
    this.wordBookId,
    this.wordBookTitle,
    this.totalCards,
    this.learnedCards,
    this.reviewCards,
    this.difficultCards,
    this.startHardCount,
    this.startNormalCount,
    this.startEasyCount,
    this.endHardCount,
    this.endNormalCount,
    this.endEasyCount,
    required this.startedAt,
    this.endedAt,
    required this.durationMinutes,
    this.note,
    required this.inProgress,
    this.type = 'GOAL',
  });

  factory StudySession.fromJson(Map<String, dynamic> json) {
    // 타입 추론 (goalId가 있으면 GOAL, wordBookId가 있으면 WORDBOOK)
    String type = 'GOAL';
    if (json.containsKey('wordBookId') && json['wordBookId'] != null) {
      type = 'WORDBOOK';
    }

    return StudySession(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      goalId: json['goalId'],
      goalTitle: json['goalTitle'],
      pomoCount: json['pomoCount'] ?? 0,
      achievedAmount: json['achievedAmount'] ?? 0,
      wordBookId: json['wordBookId'],
      wordBookTitle: json['wordBookTitle'],
      totalCards: json['totalCards'],
      learnedCards: json['learnedCards'],
      reviewCards: json['reviewCards'],
      difficultCards: json['difficultCards'],
      startHardCount: json['startHardCount'],
      startNormalCount: json['startNormalCount'],
      startEasyCount: json['startEasyCount'],
      endHardCount: json['endHardCount'],
      endNormalCount: json['endNormalCount'],
      endEasyCount: json['endEasyCount'],
      startedAt: DateTime.parse(json['startedAt']),
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
      durationMinutes: json['durationMinutes'] ?? 0,
      note: json['note'],
      inProgress: json['inProgress'] ?? false,
      type: type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goalId': goalId,
      'goalTitle': goalTitle,
      'pomoCount': pomoCount,
      'achievedAmount': achievedAmount,
      'wordBookId': wordBookId,
      'wordBookTitle': wordBookTitle,
      'totalCards': totalCards,
      'learnedCards': learnedCards,
      'reviewCards': reviewCards,
      'difficultCards': difficultCards,
      'startHardCount': startHardCount,
      'startNormalCount': startNormalCount,
      'startEasyCount': startEasyCount,
      'endHardCount': endHardCount,
      'endNormalCount': endNormalCount,
      'endEasyCount': endEasyCount,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'note': note,
      'inProgress': inProgress,
    };
  }
}
