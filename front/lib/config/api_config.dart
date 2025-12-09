// dart:io - 플랫폼 정보 접근 (Platform.isIOS 등)
import 'dart:io';
import '../services/logger_service.dart';

/// API 설정 관리
class ApiConfig {
  // ngrok 터널링 주소 (어디서든 접속 가능)
  static const String _ngrokUrl = 'https://fondly-oneirocritical-erasmo.ngrok-free.dev';
  
  // 로컬 개발용 (시뮬레이터)
  static const String _localIp = '192.168.35.20';
  static const int _port = 8080;
  
  // true: ngrok 사용 (실제 기기), false: 로컬 IP (시뮬레이터)
  static const bool useNgrok = true;

  /// 백엔드 서버 주소
  static String get baseUrl {
    if (useNgrok) {
      return '$_ngrokUrl/api';
    }
    
    // 시뮬레이터에서는 localhost 사용
    if (Platform.isIOS && _isSimulator()) {
      return 'http://localhost:$_port/api';
    }

    // 실제 기기에서는 맥북 IP 사용
    return 'http://$_localIp:$_port/api';
  }

  /// 시뮬레이터 여부 확인 (간단한 방법)
  static bool _isSimulator() {
    // 실제 기기는 대부분 arm64, 시뮬레이터는 x86_64
    // 하지만 M1 맥은 둘 다 arm64이므로 정확하지 않음
    // 일단 간단하게 처리
    return false; // 실제 기기로 가정
  }

  /// 현재 설정 출력 (디버깅용)
  static void printConfig() {
    Log.i('🌐 API Base URL: $baseUrl');
    Log.i('📱 Platform: ${Platform.operatingSystem}');
  }
}
