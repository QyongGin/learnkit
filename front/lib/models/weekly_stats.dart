class WeeklyStats {
  final WeekInfo weekInfo;
  final StudyTime studyTime;
  final CardImprovement cardImprovement;
  final List<GoalProgress> goalProgress;

  WeeklyStats({
    required this.weekInfo,
    required this.studyTime,
    required this.cardImprovement,
    required this.goalProgress,
  });

  factory WeeklyStats.fromJson(Map<String, dynamic> json) {
    return WeeklyStats(
      weekInfo: WeekInfo.fromJson(json['weekInfo']),
      studyTime: StudyTime.fromJson(json['studyTime']),
      cardImprovement: CardImprovement.fromJson(json['cardImprovement']),
      goalProgress: (json['goalProgress'] as List)
          .map((e) => GoalProgress.fromJson(e))
          .toList(),
    );
  }
}

class WeekInfo {
  final int year;
  final int month;
  final int weekNumber;

  WeekInfo({
    required this.year,
    required this.month,
    required this.weekNumber,
  });

  factory WeekInfo.fromJson(Map<String, dynamic> json) {
    return WeekInfo(
      year: json['year'],
      month: json['month'],
      weekNumber: json['weekNumber'],
    );
  }
}

class StudyTime {
  final int pomodoroMinutes;
  final int wordBookMinutes;
  final int totalMinutes;

  StudyTime({
    required this.pomodoroMinutes,
    required this.wordBookMinutes,
    required this.totalMinutes,
  });

  factory StudyTime.fromJson(Map<String, dynamic> json) {
    return StudyTime(
      pomodoroMinutes: json['pomodoroMinutes'],
      wordBookMinutes: json['wordBookMinutes'],
      totalMinutes: json['totalMinutes'],
    );
  }
}

class CardImprovement {
  final DifficultyCount weekStart;
  final DifficultyCount current;
  final DifficultyChange changes;

  CardImprovement({
    required this.weekStart,
    required this.current,
    required this.changes,
  });

  factory CardImprovement.fromJson(Map<String, dynamic> json) {
    return CardImprovement(
      weekStart: DifficultyCount.fromJson(json['weekStart']),
      current: DifficultyCount.fromJson(json['current']),
      changes: DifficultyChange.fromJson(json['changes']),
    );
  }
}

class DifficultyCount {
  final int hard;
  final int normal;
  final int easy;

  DifficultyCount({
    required this.hard,
    required this.normal,
    required this.easy,
  });

  factory DifficultyCount.fromJson(Map<String, dynamic> json) {
    return DifficultyCount(
      hard: json['hard'],
      normal: json['normal'],
      easy: json['easy'],
    );
  }
}

class DifficultyChange {
  final int hard;
  final int normal;
  final int easy;

  DifficultyChange({
    required this.hard,
    required this.normal,
    required this.easy,
  });

  factory DifficultyChange.fromJson(Map<String, dynamic> json) {
    return DifficultyChange(
      hard: json['hard'],
      normal: json['normal'],
      easy: json['easy'],
    );
  }
}

class GoalProgress {
  final int goalId;
  final String goalTitle;
  final int startAmount;
  final int currentAmount;
  final int change;
  final String unit;

  GoalProgress({
    required this.goalId,
    required this.goalTitle,
    required this.startAmount,
    required this.currentAmount,
    required this.change,
    required this.unit,
  });

  factory GoalProgress.fromJson(Map<String, dynamic> json) {
    return GoalProgress(
      goalId: json['goalId'],
      goalTitle: json['goalTitle'],
      startAmount: json['startAmount'],
      currentAmount: json['currentAmount'],
      change: json['change'],
      unit: json['unit'],
    );
  }
}
