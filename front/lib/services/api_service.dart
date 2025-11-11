import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/home_data.dart';
import '../models/schedule.dart';
import '../models/wordbook.dart';
import '../models/card.dart';
import '../models/user.dart';
import '../models/goal.dart';
import '../models/study_session.dart';

class ApiService {
  // 백엔드 서버 주소
  // 자동으로 시뮬레이터/실제 기기 구분
  static String get baseUrl {
    // 시뮬레이터에서 테스트할 때는 localhost 사용
    // return 'http://localhost:8080/api';

    // 실제 iOS/Android 기기에서는 Mac의 로컬 IP 사용
    // ⚠️ WiFi 재연결 시 IP가 변경될 수 있음 - ifconfig 명령으로 확인 필요
    return 'http://10.200.52.136:8080/api';
  }

  /// 홈 화면 데이터를 가져옵니다
  static Future<HomeData> fetchHomeData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/home'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return HomeData.fromJson(data);
      } else {
        throw Exception('Failed to load home data: ${response.statusCode}');
      }
    } catch (e) {
      // 서버 연결 실패 시 기본값 반환
      print('홈 데이터 로드 실패: $e');
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

  /// 특정 사용자의 스케줄을 가져옵니다
  static Future<List<Schedule>> fetchSchedules({
    required int userId,
    DateTime? start,
    DateTime? end,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/schedules'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Schedule.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load schedules: ${response.statusCode}');
      }
    } catch (e) {
      // 서버 연결 실패 시 빈 리스트 반환
      print('스케줄 로드 실패: $e');
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
      // 백엔드 API 스펙에 맞춘 body 생성
      final Map<String, dynamic> body = {
        'title': title,
      };
      
      // null이 아닌 값만 추가
      if (description != null && description.isNotEmpty) {
        body['description'] = description;
      }
      if (startTime != null) {
        body['startTime'] = startTime.toIso8601String();
      }
      if (endTime != null) {
        body['endTime'] = endTime.toIso8601String();
      }

      // 디버그 출력
      print('🔍 Creating schedule with body: $body');
      print('🔍 JSON encoded: ${json.encode(body)}');

      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/schedules'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      print('🔍 Response status: ${response.statusCode}');
      print('🔍 Response body: ${response.body}');

      if (response.statusCode == 201) {
        try {
          final jsonData = json.decode(response.body);
          print('🔍 Decoded JSON: $jsonData');
          print('🔍 JSON type field: ${jsonData['type']}');
          print('🔍 JSON title field: ${jsonData['title']}');
          return Schedule.fromJson(jsonData);
        } catch (e, stackTrace) {
          print('❌ Error parsing JSON: $e');
          print('❌ Stack trace: $stackTrace');
          rethrow;
        }
      } else {
        throw Exception('Failed to create schedule: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in createSchedule: $e');
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
      final Map<String, dynamic> body = {};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (startTime != null) body['startTime'] = startTime.toIso8601String();
      if (endTime != null) body['endTime'] = endTime.toIso8601String();
      if (isCompleted != null) body['isCompleted'] = isCompleted;

      final response = await http.patch(
        Uri.parse('$baseUrl/schedules/$scheduleId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return Schedule.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update schedule: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update schedule: $e');
    }
  }

  /// 스케줄 삭제
  static Future<void> deleteSchedule(int scheduleId) async { // String에서 int로 변경
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/schedules/$scheduleId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete schedule: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete schedule: $e');
    }
  }

  /// 특정 스케줄 상세 조회
  static Future<Schedule> fetchScheduleById(int scheduleId) async { // String에서 int로 변경
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/schedules/$scheduleId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return Schedule.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load schedule: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load schedule: $e');
    }
  }

  // ============================================
  // 단어장(WordBook) API
  // ============================================

  /// 사용자의 모든 단어장 조회
  static Future<List<WordBook>> fetchWordBooks(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/wordbooks'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => WordBook.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load wordbooks: ${response.statusCode}');
      }
    } catch (e) {
      // 서버 연결 실패 시 빈 리스트 반환
      print('단어장 로드 실패: $e');
      return [];
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
      final Map<String, dynamic> body = {
        'title': title,
      };

      // 선택적 파라미터 추가
      if (description != null) {
        body['description'] = description;
      }
      if (easyFrequencyRatio != null) {
        body['easyFrequencyRatio'] = easyFrequencyRatio;
      }
      if (normalFrequencyRatio != null) {
        body['normalFrequencyRatio'] = normalFrequencyRatio;
      }
      if (hardFrequencyRatio != null) {
        body['hardFrequencyRatio'] = hardFrequencyRatio;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/wordbooks'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        return WordBook.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create wordbook: ${response.statusCode}');
      }
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
      final Map<String, dynamic> body = {};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (easyFrequencyRatio != null) {
        body['easyFrequencyRatio'] = easyFrequencyRatio;
      }
      if (normalFrequencyRatio != null) {
        body['normalFrequencyRatio'] = normalFrequencyRatio;
      }
      if (hardFrequencyRatio != null) {
        body['hardFrequencyRatio'] = hardFrequencyRatio;
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/wordbooks/$wordBookId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return WordBook.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update wordbook: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update wordbook: $e');
    }
  }

  /// 단어장 삭제
  static Future<void> deleteWordBook(int wordBookId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/wordbooks/$wordBookId'),
        headers: {'Content-Type': 'application/json'},
      );

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
      final response = await http.get(
        Uri.parse('$baseUrl/wordbooks/$wordBookId/cards/statistics'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return CardStatistics.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load statistics: ${response.statusCode}');
      }
    } catch (e) {
      // 통계 조회 실패 시 빈 통계 반환
      return CardStatistics.empty();
    }
  }

  // ============================================
  // 카드(Card) API
  // ============================================

  /// 단어장에 새 카드 추가
  static Future<Card> createCard({
    required int wordBookId,
    required String question,
    required String answer,
    required CardDifficulty difficulty,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'frontText': question,
        'backText': answer,
        'difficulty': difficulty.name,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/wordbooks/$wordBookId/cards'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        return Card.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create card: ${response.statusCode}');
      }
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
      final Map<String, dynamic> body = {};
      if (question != null) body['frontText'] = question;
      if (answer != null) body['backText'] = answer;
      if (difficulty != null) body['difficulty'] = difficulty.name;

      final response = await http.patch(
        Uri.parse('$baseUrl/cards/$cardId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return Card.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update card: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update card: $e');
    }
  }

  /// 단어장의 모든 카드 조회
  static Future<List<Card>> fetchCards(int wordBookId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/wordbooks/$wordBookId/cards'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Card.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load cards: ${response.statusCode}');
      }
    } catch (e) {
      // 서버 연결 실패 시 빈 목록 반환
      return [];
    }
  }

  /// 카드 삭제
  static Future<void> deleteCard(int cardId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cards/$cardId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete card: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete card: $e');
    }
  }

  // ============================================
  // 학습(Study) API
  // ============================================

  /// 학습 세션 시작 (단어장의 모든 카드 우선순위 리셋)
  static Future<SessionStartResponse> startStudySession(int wordBookId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/wordbooks/$wordBookId/study/start'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return SessionStartResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to start study session: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to start study session: $e');
    }
  }

  /// 다음 학습할 카드 조회 (우선순위 기반)
  static Future<Card?> getNextCard(int wordBookId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/wordbooks/$wordBookId/study/next'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return Card.fromJson(json.decode(response.body));
      } else if (response.statusCode == 204) {
        // 모든 카드 복습 완료
        return null;
      } else {
        throw Exception('Failed to get next card: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get next card: $e');
    }
  }

  /// 카드 복습 완료 (난이도 선택)
  static Future<Card> reviewCard({
    required int cardId,
    required CardDifficulty difficulty,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'difficulty': difficulty.name,
      };

      final response = await http.patch(
        Uri.parse('$baseUrl/cards/$cardId/review'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return Card.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to review card: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to review card: $e');
    }
  }

  // ========================================
  // User API
  // ========================================

  /// 사용자 정보 조회 (ID로)
  static Future<User> fetchUserById(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return User.fromJson(data);
    } else {
      throw Exception('사용자 정보를 불러오는데 실패했습니다: ${response.statusCode}');
    }
  }

  /// 사용자 정보 조회 (이메일로)
  static Future<User> fetchUserByEmail(String email) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/search?email=${Uri.encodeComponent(email)}'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return User.fromJson(data);
    } else {
      throw Exception('사용자 정보를 불러오는데 실패했습니다: ${response.statusCode}');
    }
  }

  /// 프로필 수정
  static Future<User> updateProfile({
    required int userId,
    String? nickname,
    String? profileImageUrl,
  }) async {
    final Map<String, dynamic> body = {};
    if (nickname != null) body['nickname'] = nickname;
    if (profileImageUrl != null) body['profileImageUrl'] = profileImageUrl;

    final response = await http.patch(
      Uri.parse('$baseUrl/users/$userId/profile'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return User.fromJson(data);
    } else {
      throw Exception('프로필 수정에 실패했습니다: ${response.statusCode}');
    }
  }

  // ========================================
  // Goal API
  // ========================================

  /// 목표 생성
  static Future<Goal> createGoal({
    required int userId,
    required String title,
    DateTime? startDate,
    DateTime? endDate,
    required int totalTargetAmount,
    required String targetUnit,
  }) async {
    final Map<String, dynamic> body = {
      'title': title,
      'totalTargetAmount': totalTargetAmount,
      'targetUnit': targetUnit,
    };
    if (startDate != null) body['startDate'] = startDate.toIso8601String().split('T')[0];
    if (endDate != null) body['endDate'] = endDate.toIso8601String().split('T')[0];

    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/goals'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 201) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return Goal.fromJson(data);
    } else {
      throw Exception('목표 생성에 실패했습니다: ${response.statusCode}');
    }
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
    final Map<String, dynamic> body = {};
    if (title != null) body['title'] = title;
    if (startDate != null) body['startDate'] = startDate.toIso8601String().split('T')[0];
    if (endDate != null) body['endDate'] = endDate.toIso8601String().split('T')[0];
    if (totalTargetAmount != null) body['totalTargetAmount'] = totalTargetAmount;
    if (targetUnit != null) body['targetUnit'] = targetUnit;

    final response = await http.patch(
      Uri.parse('$baseUrl/goals/$goalId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return Goal.fromJson(data);
    } else {
      throw Exception('목표 수정에 실패했습니다: ${response.statusCode}');
    }
  }

  /// 목표 삭제
  static Future<void> deleteGoal(int goalId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/goals/$goalId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 204) {
      throw Exception('목표 삭제에 실패했습니다: ${response.statusCode}');
    }
  }

  /// 사용자의 진행 중인 목표 조회
  static Future<List<Goal>> fetchActiveGoals(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/goals/active'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((json) => Goal.fromJson(json)).toList();
    } else {
      throw Exception('목표 목록을 불러오는데 실패했습니다: ${response.statusCode}');
    }
  }

  /// 사용자의 모든 목표 조회
  static Future<List<Goal>> fetchGoals(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/goals'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((json) => Goal.fromJson(json)).toList();
    } else {
      throw Exception('목표 목록을 불러오는데 실패했습니다: ${response.statusCode}');
    }
  }

  /// 목표 진행도 추가
  static Future<Goal> addGoalProgress({
    required int goalId,
    required int amount,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/goals/$goalId/progress'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'amount': amount}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return Goal.fromJson(data);
    } else {
      throw Exception('목표 진행도 업데이트에 실패했습니다: ${response.statusCode}');
    }
  }

  // ========================================
  // StudySession API (포모도로 타이머)
  // ========================================

  /// 포모도로 학습 세션 시작
  static Future<StudySession> startPomodoroSession({
    required int userId,
    int? goalId,
  }) async {
    final Map<String, dynamic> body = {};
    if (goalId != null) body['goalId'] = goalId;

    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/study-sessions'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 201) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return StudySession.fromJson(data);
    } else {
      throw Exception('학습 세션 시작에 실패했습니다: ${response.statusCode}');
    }
  }

  /// 포모도로 학습 세션 종료
  static Future<StudySession> endPomodoroSession({
    required int sessionId,
    required int achievedAmount,
    required int durationMinutes,
    required int pomoCount,
    String? note,
  }) async {
    final Map<String, dynamic> body = {
      'achievedAmount': achievedAmount,
      'durationMinutes': durationMinutes,
      'pomoCount': pomoCount,
    };
    if (note != null && note.isNotEmpty) body['note'] = note;

    final response = await http.patch(
      Uri.parse('$baseUrl/study-sessions/$sessionId/end'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return StudySession.fromJson(data);
    } else {
      throw Exception('학습 세션 종료에 실패했습니다: ${response.statusCode}');
    }
  }

  /// 진행 중인 포모도로 세션 조회
  static Future<StudySession?> fetchActivePomodoroSession(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/study-sessions/active'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return StudySession.fromJson(data);
      } else if (response.statusCode == 404) {
        // 진행 중인 세션 없음
        return null;
      } else {
        throw Exception('진행 중인 세션 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      // 로깅은 추후 로깅 프레임워크로 대체 예정
      return null;
    }
  }

  /// 특정 목표의 학습 세션 목록 조회
  static Future<List<StudySession>> fetchSessionsByGoal(int goalId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/study-sessions?goalId=$goalId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((json) => StudySession.fromJson(json)).toList();
    } else {
      throw Exception('세션 목록을 불러오는데 실패했습니다: ${response.statusCode}');
    }
  }

  /// 사용자의 모든 학습 세션 조회
  static Future<List<StudySession>> fetchUserSessions(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/study-sessions'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((json) => StudySession.fromJson(json)).toList();
    } else {
      throw Exception('세션 목록을 불러오는데 실패했습니다: ${response.statusCode}');
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

