/// 학습 세션 모델
class StudySession {
  final int id;
  final int? goalId;
  final String? goalTitle;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int achievedAmount;
  final int durationMinutes;
  final int pomoCount;
  final String? note;
  final bool inProgress;

  StudySession({
    required this.id,
    this.goalId,
    this.goalTitle,
    required this.startedAt,
    this.endedAt,
    required this.achievedAmount,
    required this.durationMinutes,
    required this.pomoCount,
    this.note,
    required this.inProgress,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      goalId: json['goalId'],
      goalTitle: json['goalTitle'],
      startedAt: DateTime.parse(json['startedAt']),
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
      achievedAmount: json['achievedAmount'] ?? 0,
      durationMinutes: json['durationMinutes'] ?? 0,
      pomoCount: json['pomoCount'] ?? 0,
      note: json['note'],
      inProgress: json['inProgress'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goalId': goalId,
      'goalTitle': goalTitle,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'achievedAmount': achievedAmount,
      'durationMinutes': durationMinutes,
      'pomoCount': pomoCount,
      'note': note,
      'inProgress': inProgress,
    };
  }
}
