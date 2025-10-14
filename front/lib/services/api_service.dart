import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/home_data.dart';
import '../models/schedule.dart';
import '../models/wordbook.dart';
import '../models/card.dart';

class ApiService {
  // 백엔드 서버 주소
  // 자동으로 시뮬레이터/실제 기기 구분
  static String get baseUrl {
    // 실제 iOS/Android 기기에서는 Mac의 로컬 IP 사용
    // 시뮬레이터/에뮬레이터는 localhost 사용 가능
    // 하지만 간단하게 하기 위해 Mac IP 사용 (시뮬레이터에서도 작동)
    return 'http://192.168.35.141:8080/api';

    // 시뮬레이터에서 테스트할 때는 아래 주석 해제
    // return 'http://localhost:8080/api';
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
    int? easyIntervalMinutes,
    int? normalIntervalMinutes,
    int? hardIntervalMinutes,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'title': title,
      };

      // 선택적 파라미터 추가
      if (easyIntervalMinutes != null) {
        body['easyIntervalMinutes'] = easyIntervalMinutes;
      }
      if (normalIntervalMinutes != null) {
        body['normalIntervalMinutes'] = normalIntervalMinutes;
      }
      if (hardIntervalMinutes != null) {
        body['hardIntervalMinutes'] = hardIntervalMinutes;
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
    int? easyIntervalMinutes,
    int? normalIntervalMinutes,
    int? hardIntervalMinutes,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (title != null) body['title'] = title;
      if (easyIntervalMinutes != null) {
        body['easyIntervalMinutes'] = easyIntervalMinutes;
      }
      if (normalIntervalMinutes != null) {
        body['normalIntervalMinutes'] = normalIntervalMinutes;
      }
      if (hardIntervalMinutes != null) {
        body['hardIntervalMinutes'] = hardIntervalMinutes;
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

}

