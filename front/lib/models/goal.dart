/// 학습 목표 모델
class Goal {
  final int id;
  final String title;
  final DateTime? startDate;
  final DateTime? endDate;
  final int totalTargetAmount;
  final String targetUnit;
  final int currentProgress;
  final bool isCompleted;
  final DateTime? completedAt;

  Goal({
    required this.id,
    required this.title,
    this.startDate,
    this.endDate,
    required this.totalTargetAmount,
    required this.targetUnit,
    required this.currentProgress,
    required this.isCompleted,
    this.completedAt,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : null,
      totalTargetAmount: json['totalTargetAmount'] ?? 0,
      targetUnit: json['targetUnit'] ?? '',
      currentProgress: json['currentProgress'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }

  /// 진행률 (%)
  double get progressPercentage {
    if (totalTargetAmount == 0) return 0;
    return (currentProgress / totalTargetAmount * 100).clamp(0, 100);
  }

  /// 남은 목표량
  int get remainingAmount {
    return (totalTargetAmount - currentProgress).clamp(0, totalTargetAmount);
  }
}
