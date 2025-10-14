import 'package:shared_preferences/shared_preferences.dart';

/// 사용자 인증 상태를 관리하는 서비스
/// 회원가입 기능 없이 userId=1로 고정된 사용자 사용
class AuthService {
  static const String _keyUserId = 'user_id';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const int _defaultUserId = 1; // 고정된 사용자 ID

  static AuthService? _instance;
  SharedPreferences? _prefs;
  
  int? _currentUserId;
  bool _isLoggedIn = false;

  AuthService._();

  /// 싱글톤 인스턴스 가져오기
  static Future<AuthService> getInstance() async {
    if (_instance == null) {
      _instance = AuthService._();
      await _instance!._init();
    }
    return _instance!;
  }

  /// 초기화
  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getInt(_keyUserId);
    _isLoggedIn = _prefs?.getBool(_keyIsLoggedIn) ?? false;

    // 첫 실행이거나 로그인 정보가 없으면 자동 로그인
    if (!_isLoggedIn || _currentUserId == null) {
      await autoLogin();
    }
  }

  /// 자동 로그인 (userId=1로 고정)
  Future<void> autoLogin() async {
    _currentUserId = _defaultUserId;
    _isLoggedIn = true;
    
    await _prefs?.setInt(_keyUserId, _defaultUserId);
    await _prefs?.setBool(_keyIsLoggedIn, true);
  }

  /// 현재 로그인된 사용자 ID 가져오기
  int get currentUserId {
    return _currentUserId ?? _defaultUserId;
  }

  /// 로그인 상태 확인
  bool get isLoggedIn {
    return _isLoggedIn;
  }

  /// 로그아웃 (테스트용)
  Future<void> logout() async {
    _currentUserId = null;
    _isLoggedIn = false;
    
    await _prefs?.remove(_keyUserId);
    await _prefs?.setBool(_keyIsLoggedIn, false);
  }

  /// 사용자 정보 초기화 (디버깅용)
  Future<void> reset() async {
    await _prefs?.clear();
    await autoLogin();
  }
}
