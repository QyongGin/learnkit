// Flutter의 상태 관리 기능을 제공하는 패키지
// ChangeNotifier: 데이터가 변경되면 자동으로 UI에게 알려주는 역할
import 'package:flutter/material.dart';

// 로컬 저장소 기능을 제공하는 패키지
// SharedPreferences: 휴대폰에 간단한 데이터를 저장하고 불러오는 기능
// 예) 앱을 껐다 켜도 "다크모드 설정"이 기억되도록 저장
import 'package:shared_preferences/shared_preferences.dart';

// 로컬 알림 서비스 (알림 재스케줄링용)
import '../services/notification_service.dart';
// API 서비스 (peak-hours 조회용)
import '../services/api_service.dart';
// 인증 서비스 (userId 가져오기용)
import '../services/auth_service.dart';
// 앱 상수
import '../config/constants.dart';
// 로거 서비스
import '../services/logger_service.dart';

/// 앱 설정을 관리하는 Provider 클래스
///
/// Provider는 앱 전체에서 데이터를 공유하는 "관리자" 
/// 이 클래스는 센서 사용 설정과 알림 설정을 관리하며,
/// 설정이 변경되면 자동으로 모든 화면에 알립니다.
///
/// 주요 기능:
/// - 센서 사용 ON/OFF 관리
/// - 알림 설정 관리
/// - SharedPreferences로 설정을 휴대폰에 영구 저장
class SettingsProvider extends ChangeNotifier {
  // SharedPreferences에서 데이터를 찾을 때 사용하는 "이름표"
  static const String _keySensorEnabled = 'sensor_enabled';
  static const String _keyNotificationEnabled = 'notification_enabled'; // 알림 사용 여부
  static const String _keyAutoNotification = 'auto_notification'; // 자동 알림 설정
  static const String _keyManualNotificationHour = 'manual_notification_hour'; // 수동 알림 시
  static const String _keyManualNotificationMinute = 'manual_notification_minute'; // 수동 알림 분

  // 현재 설정 상태를 저장하는 변수들
  // _로 시작하면 private (외부에서 직접 수정 불가)
  bool _isSensorEnabled = true;      // 센서 켜짐/꺼짐 (기본값: 켜짐)
  bool _notificationEnabled = true;  // 알림 사용 켜짐/꺼짐 (기본값: 켜짐)
  bool _autoNotification = true;     // 자동 알림 켜짐/꺼짐 (기본값: 켜짐)
  int _manualNotificationHour = 19;  // 수동 알림 시 (기본값: 19시)
  int _manualNotificationMinute = 0; // 수동 알림 분 (기본값: 0분)
  int _autoNotificationHour = 9;     // 자동 알림 시간 (서버에서 계산)
  int _autoNotificationMinute = 0;   // 자동 알림 분
  bool _isLoading = true;            // 설정을 불러오는 중인지 여부

  // Getter: 외부에서 설정 값을 읽을 수 있게 해주는 함수
  bool get isSensorEnabled => _isSensorEnabled;
  bool get notificationEnabled => _notificationEnabled;
  bool get autoNotification => _autoNotification;
  int get manualNotificationHour => _manualNotificationHour;
  int get manualNotificationMinute => _manualNotificationMinute;
  int get autoNotificationHour => _autoNotificationHour;
  int get autoNotificationMinute => _autoNotificationMinute;
  bool get isLoading => _isLoading;

  /// 앱 시작 시 저장된 설정을 불러오는 함수
  ///
  /// 동작 과정:
  /// 1. SharedPreferences를 열어서 (휴대폰 저장소 접근)
  /// 2. 'sensor_enabled' 키로 저장된 값을 읽음 (없으면 true 사용)
  /// 3. 로딩 완료 후 notifyListeners()로 화면에 알림
  ///
  /// ?? 연산자: 왼쪽 값이 null이면 오른쪽 기본값 사용
  Future<void> loadSettings() async {
    try {
      // SharedPreferences 인스턴스 가져오기
      // await: 비동기 작업이 완료될 때까지 기다림
      final prefs = await SharedPreferences.getInstance();

      // 저장된 센서 설정 읽기
      _isSensorEnabled = prefs.getBool(_keySensorEnabled) ?? true;

      // 저장된 알림 사용 설정 읽기
      _notificationEnabled = prefs.getBool(_keyNotificationEnabled) ?? true;

      // 저장된 자동 알림 설정 읽기
      _autoNotification = prefs.getBool(_keyAutoNotification) ?? true;

      // 저장된 수동 알림 시간 읽기
      _manualNotificationHour = prefs.getInt(_keyManualNotificationHour) ?? 19;
      _manualNotificationMinute = prefs.getInt(_keyManualNotificationMinute) ?? 0;

      // 자동 알림 시간 가져오기 (서버에서)
      if (_notificationEnabled && _autoNotification) {
        await _fetchAutoNotificationTime();
      }

      // 로딩 완료
      _isLoading = false;

      // notifyListeners(): 이 Provider를 사용하는 모든 화면에게
      // "데이터가 변경되었으니 화면을 다시 그려!" 라고 알림
      notifyListeners();
    } catch (e) {
      // 에러 발생 시 (예: 권한 없음, 저장소 접근 실패)
      Log.e('설정 로드 실패: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 센서 사용을 켜거나 끄는 함수 (토글)
  Future<void> toggleSensor() async {
    _isSensorEnabled = !_isSensorEnabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySensorEnabled, _isSensorEnabled);
    } catch (e) {
      Log.e('센서 설정 저장 실패: $e');
    }
  }

  /// 센서 사용을 특정 값으로 직접 설정하는 함수
  Future<void> setSensorEnabled(bool value) async {
    if (_isSensorEnabled == value) return;

    _isSensorEnabled = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySensorEnabled, _isSensorEnabled);
    } catch (e) {
      Log.e('센서 설정 저장 실패: $e');
    }
  }

  /// 자동 알림을 켜거나 끄는 함수 (토글)
  ///
  /// 자동 알림:
  /// - ON: 주 사용 시간대 분석 기반 알림 (peak-hours API)
  /// - OFF: 매일 오후 7시 고정 알림
  Future<void> toggleAutoNotification() async {
    _autoNotification = !_autoNotification;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAutoNotification, _autoNotification);
    } catch (e) {
      Log.e('자동 알림 설정 저장 실패: $e');
    }
  }

  /// 자동 알림을 특정 값으로 직접 설정하는 함수
  ///
  /// 매개변수:
  /// - value: true = 자동 알림 켜기, false = 고정 시간 알림
  Future<void> setAutoNotification(bool value) async {
    if (_autoNotification == value) return;

    _autoNotification = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAutoNotification, _autoNotification);

      // 자동 알림으로 변경되면 서버에서 시간 가져오기
      if (_autoNotification) {
        await _fetchAutoNotificationTime();
      }

      // 알림 설정 변경 시 알림 재스케줄링
      if (_notificationEnabled) {
        await _rescheduleNotifications();
      }
    } catch (e) {
      Log.e('자동 알림 설정 저장 실패: $e');
    }
  }

  /// 알림 사용 설정
  ///
  /// 매개변수:
  /// - value: true = 알림 켜기, false = 알림 끄기
  Future<void> setNotificationEnabled(bool value) async {
    if (_notificationEnabled == value) return;

    _notificationEnabled = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyNotificationEnabled, _notificationEnabled);

      if (_notificationEnabled) {
        // 알림 켜기 - 자동 알림이면 시간 먼저 가져오기
        if (_autoNotification) {
          await _fetchAutoNotificationTime();
        }
        await _rescheduleNotifications();
      } else {
        // 알림 끄기 - 모든 알림 취소
        await NotificationService.cancelAllNotifications();
      }
    } catch (e) {
      Log.e('알림 설정 저장 실패: $e');
    }
  }

  /// 서버에서 자동 알림 시간 가져오기
  Future<void> _fetchAutoNotificationTime() async {
    try {
      final authService = await AuthService.getInstance();
      final userId = authService.currentUserId;
      final peakHour = await ApiService.fetchPeakHour(userId);
      
      _autoNotificationHour = peakHour;
      _autoNotificationMinute = 0;
      notifyListeners();
    } catch (e) {
      // 실패 시 기본값 유지 (9시)
      _autoNotificationHour = 9;
      _autoNotificationMinute = 0;
      Log.e('자동 알림 시간 조회 실패: $e');
    }
  }

  /// 수동 알림 시간 설정
  ///
  /// 매개변수:
  /// - hour: 알림 시 (0-23)
  /// - minute: 알림 분 (0-59)
  Future<void> setManualNotificationTime(int hour, int minute) async {
    _manualNotificationHour = hour;
    _manualNotificationMinute = minute;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyManualNotificationHour, hour);
      await prefs.setInt(_keyManualNotificationMinute, minute);

      // 자동 알림이 꺼져있을 때만 재스케줄링
      if (!_autoNotification) {
        await _rescheduleNotifications();
      }
    } catch (e) {
      Log.e('수동 알림 시간 저장 실패: $e');
    }
  }

  /// 알림 재스케줄링
  ///
  /// 알림 설정 변경 시 호출되어 알림을 다시 예약
  /// - 자동 알림 ON: 주 사용 시간대 기반 (저장된 시간)
  /// - 자동 알림 OFF: 사용자가 설정한 시간
  Future<void> _rescheduleNotifications() async {
    try {
      if (_autoNotification) {
        // 자동 알림: 저장된 자동 알림 시간 사용
        await NotificationService.scheduleDailyNotification(
          hour: _autoNotificationHour,
          minute: _autoNotificationMinute,
          message: NotificationConstants.dailyReminderMessage,
        );
      } else {
        // 수동 알림: 사용자가 설정한 시간
        await NotificationService.scheduleDailyNotification(
          hour: _manualNotificationHour,
          minute: _manualNotificationMinute,
          message: NotificationConstants.dailyReminderMessage,
        );
      }
    } catch (e) {
      Log.e('알림 재스케줄링 실패: $e');
    }
  }
}

