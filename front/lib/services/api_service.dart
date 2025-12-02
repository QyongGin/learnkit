import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/home_data.dart';
import '../models/schedule.dart';
import '../models/wordbook.dart';
import '../models/card.dart';
import '../models/user.dart';
import '../models/goal.dart';
import '../models/study_session.dart';
import '../models/weekly_stats.dart' as ws;
import '../config/api_config.dart';
import 'logger_service.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;
  static const _headers = {'Content-Type': 'application/json'};

  // ─────────────────────────────────────────────────────────────
  // HTTP 헬퍼 메서드
  // ─────────────────────────────────────────────────────────────

  static Future<http.Response> _get(String path) =>
      http.get(Uri.parse('$baseUrl$path'), headers: _headers);

  static Future<http.Response> _post(String path, [Map<String, dynamic>? body]) =>
      http.post(Uri.parse('$baseUrl$path'), headers: _headers, body: body != null ? json.encode(body) : null);

  static Future<http.Response> _patch(String path, [Map<String, dynamic>? body]) =>
      http.patch(Uri.parse('$baseUrl$path'), headers: _headers, body: body != null ? json.encode(body) : null);

  static Future<http.Response> _delete(String path) =>
      http.delete(Uri.parse('$baseUrl$path'), headers: _headers);

  /// JSON 응답 파싱 (UTF-8)
  static dynamic _decode(http.Response response) =>
      json.decode(utf8.decode(response.bodyBytes));

  // ─────────────────────────────────────────────────────────────
  // 홈
  // ─────────────────────────────────────────────────────────────

  /// 홈 화면 데이터를 가져옵니다
  static Future<HomeData> fetchHomeData() async {
    try {
      final response = await _get('/home');
      if (response.statusCode == 200) {
        return HomeData.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to load home data: ${response.statusCode}');
    } catch (e) {
      Log.d('홈 데이터 로드 실패: $e');
      return HomeData(
        date: '',
        timerInfo: TimerInfo(hours: 0, minutes: 0),
        wordInfo: WordInfo(learned: 0, reviewed: 0, difficult: 0),
        goalProgress: GoalProgress(completed: 0, total: 0),
        progressInfo: ProgressInfo(percentage: 0),
        weeklyStats: WeeklyStats(goalIncrease: 0, pomototoCount: 0),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 스케줄
  // ─────────────────────────────────────────────────────────────

  /// 특정 사용자의 스케줄을 가져옵니다
  static Future<List<Schedule>> fetchSchedules({required int userId, DateTime? start, DateTime? end}) async {
    try {
      final response = await _get('/users/$userId/schedules');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Schedule.fromJson(json)).toList();
      }
      throw Exception('Failed to load schedules: ${response.statusCode}');
    } catch (e) {
      Log.d('스케줄 로드 실패: $e');
      return [];
    }
  }

  /// 새 스케줄 생성
  static Future<Schedule> createSchedule({
    required int userId,
    required String title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final body = <String, dynamic>{'title': title};
      if (description != null && description.isNotEmpty) body['description'] = description;
      if (startTime != null) body['startTime'] = startTime.toIso8601String();
      if (endTime != null) body['endTime'] = endTime.toIso8601String();

      Log.d('🔍 Creating schedule with body: $body');
      final response = await _post('/users/$userId/schedules', body);
      Log.d('🔍 Response status: ${response.statusCode}');

      if (response.statusCode == 201) {
        return Schedule.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to create schedule: ${response.statusCode}');
    } catch (e) {
      Log.d('❌ Error in createSchedule: $e');
      throw Exception('Failed to create schedule: $e');
    }
  }

  /// 스케줄 수정
  static Future<Schedule> updateSchedule({
    required int scheduleId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    bool? isCompleted,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (startTime != null) body['startTime'] = startTime.toIso8601String();
      if (endTime != null) body['endTime'] = endTime.toIso8601String();
      if (isCompleted != null) body['isCompleted'] = isCompleted;

      final response = await _patch('/schedules/$scheduleId', body);
      if (response.statusCode == 200) {
        return Schedule.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to update schedule: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to update schedule: $e');
    }
  }

  /// 스케줄 삭제
  static Future<void> deleteSchedule(int scheduleId) async {
    try {
      final response = await _delete('/schedules/$scheduleId');
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete schedule: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete schedule: $e');
    }
  }

  /// 특정 스케줄 상세 조회
  static Future<Schedule> fetchScheduleById(int scheduleId) async {
    try {
      final response = await _get('/schedules/$scheduleId');
      if (response.statusCode == 200) {
        return Schedule.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to load schedule: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to load schedule: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 단어장
  // ─────────────────────────────────────────────────────────────

  /// 사용자의 모든 단어장 조회
  static Future<List<WordBook>> fetchWordBooks(int userId) async {
    try {
      final response = await _get('/users/$userId/wordbooks');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => WordBook.fromJson(json)).toList();
      }
      throw Exception('Failed to load wordbooks: ${response.statusCode}');
    } catch (e) {
      Log.d('단어장 로드 실패: $e');
      return [];
    }
  }

  /// 단일 단어장 조회
  static Future<WordBook?> fetchWordBook(int wordBookId) async {
    try {
      final response = await _get('/wordbooks/$wordBookId');
      if (response.statusCode == 200) {
        return WordBook.fromJson(_decode(response));
      }
      throw Exception('Failed to load wordbook: ${response.statusCode}');
    } catch (e) {
      Log.d('단어장 조회 실패: $e');
      return null;
    }
  }

  /// 새 단어장 생성
  static Future<WordBook> createWordBook({
    required int userId,
    required String title,
    String? description,
    int? easyFrequencyRatio,
    int? normalFrequencyRatio,
    int? hardFrequencyRatio,
  }) async {
    try {
      final body = <String, dynamic>{'title': title};
      if (description != null) body['description'] = description;
      if (easyFrequencyRatio != null) body['easyFrequencyRatio'] = easyFrequencyRatio;
      if (normalFrequencyRatio != null) body['normalFrequencyRatio'] = normalFrequencyRatio;
      if (hardFrequencyRatio != null) body['hardFrequencyRatio'] = hardFrequencyRatio;

      final response = await _post('/users/$userId/wordbooks', body);
      if (response.statusCode == 201) {
        return WordBook.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to create wordbook: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to create wordbook: $e');
    }
  }

  /// 단어장 수정
  static Future<WordBook> updateWordBook({
    required int wordBookId,
    String? title,
    String? description,
    int? easyFrequencyRatio,
    int? normalFrequencyRatio,
    int? hardFrequencyRatio,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (easyFrequencyRatio != null) body['easyFrequencyRatio'] = easyFrequencyRatio;
      if (normalFrequencyRatio != null) body['normalFrequencyRatio'] = normalFrequencyRatio;
      if (hardFrequencyRatio != null) body['hardFrequencyRatio'] = hardFrequencyRatio;

      final response = await _patch('/wordbooks/$wordBookId', body);
      if (response.statusCode == 200) {
        return WordBook.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to update wordbook: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to update wordbook: $e');
    }
  }

  /// 단어장 삭제
  static Future<void> deleteWordBook(int wordBookId) async {
    try {
      final response = await _delete('/wordbooks/$wordBookId');
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete wordbook: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete wordbook: $e');
    }
  }

  /// 단어장의 카드 통계 조회
  static Future<CardStatistics> fetchWordBookStatistics(int wordBookId) async {
    try {
      final response = await _get('/wordbooks/$wordBookId/cards/statistics');
      if (response.statusCode == 200) {
        return CardStatistics.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to load statistics: ${response.statusCode}');
    } catch (e) {
      return CardStatistics.empty();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 카드
  // ─────────────────────────────────────────────────────────────

  /// 단어장에 새 카드 추가
  static Future<Card> createCard({
    required int wordBookId,
    required String question,
    required String answer,
    required CardDifficulty difficulty,
  }) async {
    try {
      final body = {'frontText': question, 'backText': answer, 'difficulty': difficulty.name};
      final response = await _post('/wordbooks/$wordBookId/cards', body);
      if (response.statusCode == 201) {
        return Card.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to create card: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to create card: $e');
    }
  }

  /// 카드 수정
  static Future<Card> updateCard({
    required int cardId,
    String? question,
    String? answer,
    CardDifficulty? difficulty,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (question != null) body['frontText'] = question;
      if (answer != null) body['backText'] = answer;
      if (difficulty != null) body['difficulty'] = difficulty.name;

      final response = await _patch('/cards/$cardId', body);
      if (response.statusCode == 200) {
        return Card.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to update card: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to update card: $e');
    }
  }

  /// 단어장의 모든 카드 조회
  static Future<List<Card>> fetchCards(int wordBookId) async {
    try {
      final response = await _get('/wordbooks/$wordBookId/cards');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Card.fromJson(json)).toList();
      }
      throw Exception('Failed to load cards: ${response.statusCode}');
    } catch (e) {
      return [];
    }
  }

  /// 카드 삭제
  static Future<void> deleteCard(int cardId) async {
    try {
      final response = await _delete('/cards/$cardId');
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete card: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete card: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 카드 학습
  // ─────────────────────────────────────────────────────────────

  /// 학습 세션 시작 (단어장의 모든 카드 우선순위 리셋)
  static Future<SessionStartResponse> startStudySession(int wordBookId) async {
    try {
      final response = await _post('/wordbooks/$wordBookId/study/start');
      if (response.statusCode == 200) {
        return SessionStartResponse.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to start study session: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to start study session: $e');
    }
  }

  /// 다음 학습할 카드 조회 (우선순위 기반)
  static Future<Card?> getNextCard(int wordBookId) async {
    try {
      final response = await _get('/wordbooks/$wordBookId/study/next');
      if (response.statusCode == 200) {
        return Card.fromJson(json.decode(response.body));
      } else if (response.statusCode == 204) {
        return null; // 모든 카드 복습 완료
      }
      throw Exception('Failed to get next card: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to get next card: $e');
    }
  }

  /// 카드 복습 완료 (난이도 선택)
  static Future<Card> reviewCard({required int cardId, required CardDifficulty difficulty}) async {
    try {
      final response = await _patch('/cards/$cardId/review', {'difficulty': difficulty.name});
      if (response.statusCode == 200) {
        return Card.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to review card: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to review card: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 사용자
  // ─────────────────────────────────────────────────────────────

  /// 사용자 정보 조회 (ID로)
  static Future<User> fetchUserById(int userId) async {
    final response = await _get('/users/$userId');
    if (response.statusCode == 200) {
      return User.fromJson(_decode(response));
    }
    throw Exception('사용자 정보를 불러오는데 실패했습니다: ${response.statusCode}');
  }

  /// 사용자 정보 조회 (이메일로)
  static Future<User> fetchUserByEmail(String email) async {
    final response = await _get('/users/search?email=${Uri.encodeComponent(email)}');
    if (response.statusCode == 200) {
      return User.fromJson(_decode(response));
    }
    throw Exception('사용자 정보를 불러오는데 실패했습니다: ${response.statusCode}');
  }

  /// 프로필 수정
  static Future<User> updateProfile({required int userId, String? nickname, String? profileImageUrl}) async {
    final body = <String, dynamic>{};
    if (nickname != null) body['nickname'] = nickname;
    if (profileImageUrl != null) body['profileImageUrl'] = profileImageUrl;

    final response = await _patch('/users/$userId/profile', body);
    if (response.statusCode == 200) {
      return User.fromJson(_decode(response));
    }
    throw Exception('프로필 수정에 실패했습니다: ${response.statusCode}');
  }

  // ─────────────────────────────────────────────────────────────
  // 목표
  // ─────────────────────────────────────────────────────────────

  /// 목표 생성
  static Future<Goal> createGoal({
    required int userId,
    required String title,
    DateTime? startDate,
    DateTime? endDate,
    required int totalTargetAmount,
    required String targetUnit,
  }) async {
    final body = <String, dynamic>{'title': title, 'totalTargetAmount': totalTargetAmount, 'targetUnit': targetUnit};
    if (startDate != null) body['startDate'] = startDate.toIso8601String().split('T')[0];
    if (endDate != null) body['endDate'] = endDate.toIso8601String().split('T')[0];

    final response = await _post('/users/$userId/goals', body);
    if (response.statusCode == 201) {
      return Goal.fromJson(_decode(response));
    }
    throw Exception('목표 생성에 실패했습니다: ${response.statusCode}');
  }

  /// 목표 수정
  static Future<Goal> updateGoal({
    required int goalId,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    int? totalTargetAmount,
    String? targetUnit,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (startDate != null) body['startDate'] = startDate.toIso8601String().split('T')[0];
    if (endDate != null) body['endDate'] = endDate.toIso8601String().split('T')[0];
    if (totalTargetAmount != null) body['totalTargetAmount'] = totalTargetAmount;
    if (targetUnit != null) body['targetUnit'] = targetUnit;

    final response = await _patch('/goals/$goalId', body);
    if (response.statusCode == 200) {
      return Goal.fromJson(_decode(response));
    }
    throw Exception('목표 수정에 실패했습니다: ${response.statusCode}');
  }

  /// 목표 삭제
  static Future<void> deleteGoal(int goalId) async {
    final response = await _delete('/goals/$goalId');
    if (response.statusCode != 204) {
      throw Exception('목표 삭제에 실패했습니다: ${response.statusCode}');
    }
  }

  /// 사용자의 진행 중인 목표 조회
  static Future<List<Goal>> fetchActiveGoals(int userId) async {
    final response = await _get('/users/$userId/goals/active');
    if (response.statusCode == 200) {
      final List<dynamic> data = _decode(response);
      return data.map((json) => Goal.fromJson(json)).toList();
    }
    throw Exception('목표 목록을 불러오는데 실패했습니다: ${response.statusCode}');
  }

  /// 사용자의 모든 목표 조회
  static Future<List<Goal>> fetchGoals(int userId) async {
    final response = await _get('/users/$userId/goals');
    if (response.statusCode == 200) {
      final List<dynamic> data = _decode(response);
      return data.map((json) => Goal.fromJson(json)).toList();
    }
    throw Exception('목표 목록을 불러오는데 실패했습니다: ${response.statusCode}');
  }

  /// 목표 진행도 추가
  static Future<Goal> addGoalProgress({required int goalId, required int amount}) async {
    final response = await _patch('/goals/$goalId/progress', {'amount': amount});
    if (response.statusCode == 200) {
      return Goal.fromJson(_decode(response));
    }
    throw Exception('목표 진행도 업데이트에 실패했습니다: ${response.statusCode}');
  }

  // ─────────────────────────────────────────────────────────────
  // 포모도로 세션
  // ─────────────────────────────────────────────────────────────

  /// 포모도로 학습 세션 시작
  static Future<StudySession> startPomodoroSession({required int userId, int? goalId}) async {
    final body = goalId != null ? {'goalId': goalId} : <String, dynamic>{};
    final response = await _post('/users/$userId/goal-study-sessions', body);
    if (response.statusCode == 201) {
      return StudySession.fromJson(_decode(response));
    }
    throw Exception('학습 세션 시작에 실패했습니다: ${response.statusCode}');
  }

  /// 포모도로 학습 세션 종료
  static Future<StudySession> endPomodoroSession({
    required int sessionId,
    required int achievedAmount,
    required int durationMinutes,
    required int pomoCount,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'achievedAmount': achievedAmount,
      'durationMinutes': durationMinutes,
      'pomoCount': pomoCount,
    };
    if (note != null && note.isNotEmpty) body['note'] = note;

    final response = await _patch('/goal-study-sessions/$sessionId/end', body);
    if (response.statusCode == 200) {
      return StudySession.fromJson(_decode(response));
    }
    throw Exception('학습 세션 종료에 실패했습니다: ${response.statusCode}');
  }

  /// 진행 중인 포모도로 세션 조회
  static Future<StudySession?> fetchActivePomodoroSession(int userId) async {
    try {
      final response = await _get('/users/$userId/goal-study-sessions/active');
      if (response.statusCode == 200) {
        return StudySession.fromJson(_decode(response));
      } else if (response.statusCode == 404) {
        return null;
      }
      throw Exception('진행 중인 세션 조회 실패: ${response.statusCode}');
    } catch (e) {
      return null;
    }
  }

  /// 특정 목표의 학습 세션 목록 조회
  static Future<List<StudySession>> fetchSessionsByGoal(int goalId) async {
    final response = await _get('/goal-study-sessions?goalId=$goalId');
    if (response.statusCode == 200) {
      final List<dynamic> data = _decode(response);
      return data.map((json) => StudySession.fromJson(json)).toList();
    }
    throw Exception('세션 목록을 불러오는데 실패했습니다: ${response.statusCode}');
  }

  /// 사용자의 모든 학습 세션 조회 (목표 학습 + 단어장 학습)
  static Future<List<StudySession>> fetchUserSessions(int userId) async {
    try {
      final goalResponse = await _get('/users/$userId/goal-study-sessions');
      final wordBookResponse = await _get('/users/$userId/wordbook-study-sessions');

      List<StudySession> allSessions = [];

      if (goalResponse.statusCode == 200) {
        final List<dynamic> goalData = _decode(goalResponse);
        allSessions.addAll(goalData.map((json) => StudySession.fromJson(json)));
      }
      if (wordBookResponse.statusCode == 200) {
        final List<dynamic> wordBookData = _decode(wordBookResponse);
        allSessions.addAll(wordBookData.map((json) => StudySession.fromJson(json)));
      }

      allSessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return allSessions;
    } catch (e) {
      Log.d('세션 목록 로드 중 오류: $e');
      throw Exception('세션 목록을 불러오는데 실패했습니다: $e');
    }
  }

  /// 진행 중인 세션의 포모도로 카운트 업데이트
  static Future<StudySession> updatePomoCount({required int sessionId, required int pomoCount}) async {
    final response = await _patch('/goal-study-sessions/$sessionId/pomo-count?pomoCount=$pomoCount');
    if (response.statusCode == 200) {
      return StudySession.fromJson(_decode(response));
    }
    throw Exception('포모도로 카운트 업데이트에 실패했습니다: ${response.statusCode}');
  }

  // ─────────────────────────────────────────────────────────────
  // 단어장 학습 세션
  // ─────────────────────────────────────────────────────────────

  /// 단어장 학습 세션 시작
  static Future<StudySession> startWordBookSession({
    required int userId,
    required int wordBookId,
    required int initialHardCount,
    required int initialNormalCount,
    required int initialEasyCount,
  }) async {
    final body = {
      'wordBookId': wordBookId,
      'hardCount': initialHardCount,
      'normalCount': initialNormalCount,
      'easyCount': initialEasyCount,
    };

    Log.d('API 요청: 단어장 세션 시작 (userId=$userId, wordBookId=$wordBookId)');
    final response = await _post('/users/$userId/wordbook-study-sessions', body);
    Log.d('API 응답: ${response.statusCode}');

    if (response.statusCode == 201) {
      return StudySession.fromJson(_decode(response));
    }
    throw Exception('단어장 학습 세션 시작 실패: ${response.statusCode}');
  }

  /// 진행 중인 단어장 학습 세션 조회
  static Future<StudySession?> fetchActiveWordBookSession(int userId) async {
    try {
      final response = await _get('/users/$userId/wordbook-study-sessions/active');
      if (response.statusCode == 200) {
        return StudySession.fromJson(_decode(response));
      } else if (response.statusCode == 404) {
        return null;
      }
      throw Exception('진행 중인 단어장 세션 조회 실패: ${response.statusCode}');
    } catch (e) {
      Log.d('진행 중인 단어장 세션 조회 중 에러: $e');
      return null;
    }
  }

  /// 단어장 학습 세션 종료
  static Future<StudySession> endWordBookSession({
    required int sessionId,
    required int hardCount,
    required int normalCount,
    required int easyCount,
  }) async {
    final body = {'hardCount': hardCount, 'normalCount': normalCount, 'easyCount': easyCount};

    Log.d('API 요청: 단어장 세션 종료 (sessionId=$sessionId)');
    final response = await _patch('/wordbook-study-sessions/$sessionId/end', body);
    Log.d('API 응답: ${response.statusCode}');

    if (response.statusCode == 200) {
      return StudySession.fromJson(_decode(response));
    }
    throw Exception('단어장 학습 세션 종료 실패: ${response.statusCode}');
  }

  /// 단어장 학습 세션 삭제 (미완료 세션 제거용)
  static Future<void> deleteWordBookSession(int sessionId) async {
    Log.d('API 요청: 단어장 세션 삭제 (sessionId=$sessionId)');
    final response = await _delete('/wordbook-study-sessions/$sessionId');
    Log.d('API 응답: ${response.statusCode}');

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('단어장 학습 세션 삭제 실패: ${response.statusCode}');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 앱 사용 통계
  // ─────────────────────────────────────────────────────────────

  /// 앱 실행 시간 기록 (로컬 알림 스케줄링용)
  static Future<void> recordAppLaunch(int userId) async {
    try {
      final response = await _post('/users/$userId/app-launches');
      if (response.statusCode == 204 || response.statusCode == 200 || response.statusCode == 201) {
        Log.d('✅ 앱 실행 시간 기록 성공');
      } else {
        throw Exception('앱 실행 기록 실패: ${response.statusCode}');
      }
    } catch (e) {
      Log.d('앱 실행 기록 API 오류: $e');
    }
  }

  /// 사용자의 주 사용 시간대 조회 (0-23시)
  static Future<int> fetchPeakHour(int userId) async {
    try {
      final response = await _get('/users/$userId/peak-hours');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['peakHour'] as int;
      }
      throw Exception('주 사용 시간대 조회 실패: ${response.statusCode}');
    } catch (e) {
      Log.d('주 사용 시간대 API 오류: $e');
      return 19; // 기본값: 오후 7시
    }
  }

  /// 주간 통계 조회
  static Future<ws.WeeklyStats?> fetchWeeklyStats(int userId) async {
    try {
      final response = await _get('/users/$userId/weekly-stats');
      if (response.statusCode == 200) {
        return ws.WeeklyStats.fromJson(_decode(response));
      }
      throw Exception('주간 통계 조회 실패: ${response.statusCode}');
    } catch (e) {
      Log.d('주간 통계 API 오류: $e');
      return null;
    }
  }

  /// 주간 통계 기준선 생성 (앱 실행 시 호출)
  static Future<void> createWeeklyBaseline(int userId) async {
    try {
      await _post('/users/$userId/weekly-stats/baseline');
    } catch (e) {
      Log.d('주간 통계 기준선 생성 오류: $e');
    }
  }
}

/// 학습 세션 시작 응답
class SessionStartResponse {
  final int totalCards;
  final int easyCount;
  final int normalCount;
  final int hardCount;

  SessionStartResponse({
    required this.totalCards,
    required this.easyCount,
    required this.normalCount,
    required this.hardCount,
  });

  factory SessionStartResponse.fromJson(Map<String, dynamic> json) {
    return SessionStartResponse(
      totalCards: json['totalCards'] ?? 0,
      easyCount: json['easyCount'] ?? 0,
      normalCount: json['normalCount'] ?? 0,
      hardCount: json['hardCount'] ?? 0,
    );
  }
}

