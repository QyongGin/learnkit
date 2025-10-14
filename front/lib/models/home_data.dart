/// 홈 화면에서 표시될 데이터 모델
class HomeData {
  final String date;
  final TimerInfo timerInfo;
  final WordInfo wordInfo;
  final GoalProgress goalProgress;
  final ProgressInfo progressInfo;
  final WeeklyStats weeklyStats;

  HomeData({
    required this.date,
    required this.timerInfo,
    required this.wordInfo,
    required this.goalProgress,
    required this.progressInfo,
    required this.weeklyStats,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      date: json['date'] ?? '',
      timerInfo: TimerInfo.fromJson(json['timerInfo'] ?? {}),
      wordInfo: WordInfo.fromJson(json['wordInfo'] ?? {}),
      goalProgress: GoalProgress.fromJson(json['goalProgress'] ?? {}),
      progressInfo: ProgressInfo.fromJson(json['progressInfo'] ?? {}),
      weeklyStats: WeeklyStats.fromJson(json['weeklyStats'] ?? {}),
    );
  }
}

/// 타이머 정보
class TimerInfo {
  final int hours;
  final int minutes;

  TimerInfo({required this.hours, required this.minutes});

  factory TimerInfo.fromJson(Map<String, dynamic> json) {
    return TimerInfo(
      hours: json['hours'] ?? 0,
      minutes: json['minutes'] ?? 0,
    );
  }

  String get displayText => '이번주 달성 시간: $hours시간 $minutes분';
}

/// 단어장 정보
class WordInfo {
  final int learned;
  final int reviewed;
  final int difficult;

  WordInfo({
    required this.learned,
    required this.reviewed,
    required this.difficult,
  });

  factory WordInfo.fromJson(Map<String, dynamic> json) {
    return WordInfo(
      learned: json['learned'] ?? 0,
      reviewed: json['reviewed'] ?? 0,
      difficult: json['difficult'] ?? 0,
    );
  }

  String get displayText => '쉬움: $learned개 보통: $reviewed개 어려움: $difficult개';
}

/// 오늘의 목표 진행도
class GoalProgress {
  final int completed;
  final int total;

  GoalProgress({required this.completed, required this.total});

  factory GoalProgress.fromJson(Map<String, dynamic> json) {
    return GoalProgress(
      completed: json['completed'] ?? 0,
      total: json['total'] ?? 5,
    );
  }

  double get progress => total > 0 ? completed / total : 0;
  String get displayText => '$completed/$total';
}

/// 진행 상황 정보
class ProgressInfo {
  final int percentage;

  ProgressInfo({required this.percentage});

  factory ProgressInfo.fromJson(Map<String, dynamic> json) {
    return ProgressInfo(
      percentage: json['percentage'] ?? 0,
    );
  }

  double get progress => percentage / 100;
  String get displayText => '진행도 $percentage%';
}

/// 주간 통계
class WeeklyStats {
  final int goalIncrease;
  final int pomototoCount;

  WeeklyStats({required this.goalIncrease, required this.pomototoCount});

  factory WeeklyStats.fromJson(Map<String, dynamic> json) {
    return WeeklyStats(
      goalIncrease: json['goalIncrease'] ?? 0,
      pomototoCount: json['pomototoCount'] ?? 0,
    );
  }

  String get displayText =>
      '주간 목표 달성률: +$goalIncrease% 총 뽀모도로: $pomototoCount회';
}
