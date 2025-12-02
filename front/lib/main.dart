// Flutter의 기본 위젯과 Material Design 제공
import 'package:flutter/material.dart';

// 다국어 지원 (한글, 영어 등)
import 'package:flutter_localizations/flutter_localizations.dart';

// 날짜 형식을 한국어로 표시하기 위한 패키지
// 예: "2025년 1월 13일 월요일"
import 'package:intl/date_symbol_data_local.dart';

// Provider: 앱 전체에서 데이터를 공유하는 패키지
import 'package:provider/provider.dart';

// SharedPreferences: 로컬 저장소 (설정 데이터 읽기)
import 'package:shared_preferences/shared_preferences.dart';

// Supabase: 백엔드 서비스 (Storage, Auth, Database)
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/home_screen.dart';           // 홈 화면
import 'services/auth_service.dart';         // 로그인 서비스
import 'services/api_service.dart';          // API 서비스 (앱 실행 기록 등)
import 'services/notification_service.dart'; // 로컬 알림 서비스
import 'providers/settings_provider.dart';   // 설정 관리 Provider
import 'config/constants.dart';              // 앱 상수

import 'config/supabase_config.dart'; 

/// 앱의 시작점 (진입점)
///
/// 이 함수가 가장 먼저 실행되며, 앱을 초기화하고 시작합니다.
/// async: 비동기 함수 (await를 사용할 수 있음)
void main() async {
  // Flutter 엔진 초기화 (async 함수에서 await를 쓰기 전에 필수)
  WidgetsFlutterBinding.ensureInitialized();

  // 날짜를 한국어로 표시하도록 초기화
  // 'ko_KR': 한국어, 대한민국
  await initializeDateFormatting('ko_KR', null);

  // 로그인 서비스 초기화 (userId=1로 자동 로그인)
  final authService = await AuthService.getInstance();

  // Supabase 초기화
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // 로컬 알림 서비스 초기화
  await NotificationService.initialize();

  // 앱 실행 시간 기록 (백그라운드에서 실행, 실패해도 앱 계속 진행)
  ApiService.recordAppLaunch(authService.currentUserId);

  // 앱 시작
  // runApp: Flutter에게 "이제 앱을 화면에 그려!" 라고 알림
  runApp(
    // ChangeNotifierProvider: SettingsProvider를 앱 전체에서 사용 가능하게 만듦
    // 이제 어떤 화면에서든 settings.isDarkMode 같은 값을 읽을 수 있음
    ChangeNotifierProvider(
      // create: SettingsProvider 인스턴스를 생성하고
      // ..loadSettings(): 생성 직후 바로 설정을 불러옴
      // .. 연산자: 같은 객체에 여러 작업을 연속으로 수행
      create: (_) => SettingsProvider()
        ..loadSettings().then((_) {
          // 설정 로드 완료 후 알림 스케줄링
          _scheduleNotifications(authService.currentUserId);
        }),
      child: const LearnKitApp(),
    ),
  );
}

/// 로컬 알림 스케줄링
///
/// 설정에 따라 알림을 예약:
/// - 자동 알림 ON: 주 사용 시간대 기반 (peak-hours API)
/// - 자동 알림 OFF: 사용자가 설정한 시간
///
/// 매개변수:
/// - userId: 사용자 ID (peak-hours 조회용)
Future<void> _scheduleNotifications(int userId) async {
  try {
    // SettingsProvider에서 설정 읽기
    // 주의: 이 시점에는 Provider context가 없으므로 SharedPreferences 직접 접근
    final prefs = await SharedPreferences.getInstance();
    final autoNotification = prefs.getBool('auto_notification') ?? false;
    final manualHour = prefs.getInt('manual_notification_hour') ?? 19;
    final manualMinute = prefs.getInt('manual_notification_minute') ?? 0;

    if (autoNotification) {
      // 자동 알림: 주 사용 시간대에서 가장 많이 사용한 시간 1회
      final peakHour = await ApiService.fetchPeakHour(userId);
      await NotificationService.scheduleDailyNotification(
        hour: peakHour,
        minute: 0,
        message: NotificationConstants.dailyReminderMessage,
      );
    } else {
      // 수동 알림: 사용자가 설정한 시간
      await NotificationService.scheduleDailyNotification(
        hour: manualHour,
        minute: manualMinute,
        message: NotificationConstants.dailyReminderMessage,
      );
    }
  } catch (e) {
    debugPrint('알림 스케줄링 실패: $e');
    // 실패해도 앱 실행은 계속 진행
  }
}

/// 앱의 최상위 위젯
///
/// StatelessWidget: 변하지 않는 위젯
/// MaterialApp을 감싸서 설정(다크모드, 테마 등)을 적용합니다.
class LearnKitApp extends StatelessWidget {
  const LearnKitApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumer: SettingsProvider의 변화를 감지하는 위젯
    // settings가 변경되면 이 부분이 자동으로 다시 그려짐
    return Consumer<SettingsProvider>(
      // builder: settings가 변경될 때마다 실행되는 함수
      // context: 현재 위젯의 위치 정보
      // settings: SettingsProvider 인스턴스
      // child: 변하지 않는 부분 (최적화용, 여기서는 사용 안함)
      builder: (context, settings, child) {
        // MaterialApp: Flutter 앱의 기본 구조 제공
        // - 라우팅 (화면 전환)
        // - 테마 (색상, 폰트 등)
        // - 다국어 지원
        return MaterialApp(
          title: 'LearnKit',
          // 디버그 배너 숨기기 (우측 상단의 "DEBUG" 띠)
          debugShowCheckedModeBanner: false,

          // 다국어 지원 설정
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,     // Material 위젯 다국어
            GlobalWidgetsLocalizations.delegate,      // 기본 위젯 다국어
            GlobalCupertinoLocalizations.delegate,    // iOS 스타일 위젯 다국어
          ],
          // 지원하는 언어 목록
          supportedLocales: const [
            Locale('ko', 'KR'),  // 한국어
            Locale('en', 'US'),  // 영어
          ],
          // 기본 언어 설정
          locale: const Locale('ko', 'KR'),

          // 라이트 테마만 사용
          themeMode: ThemeMode.light,

          // 라이트 테마 정의 (밝은 화면)
          theme: ThemeData(
            // Material Design 3 사용 (최신 디자인)
            useMaterial3: true,

            // 색상 스키마 (앱 전체 색상 규칙)
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF212121),        // 주 색상 (버튼 등)
              secondary: const Color(0xFF424242),      // 부 색상
              surface: Colors.white,                   // 카드, 다이얼로그 배경
              surfaceContainerHighest: const Color(0xFFF5F5F5), // 비활성 영역 배경
              onPrimary: Colors.white,                 // primary 위의 텍스트 색
              onSecondary: Colors.white,               // secondary 위의 텍스트 색
              onSurface: const Color(0xFF212121),      // surface 위의 텍스트 색
              outline: const Color(0xFFE0E0E0),        // 테두리 색
            ),
            // 기본 배경색
            scaffoldBackgroundColor: Colors.white,
            // 폰트 (애플 고딕)
            fontFamily: 'AppleSDGothicNeo',

            // AppBar 스타일 (상단 바)
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF212121),
              elevation: 0,  // 그림자 없음
            ),

            // Card 위젯 스타일
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,  // 그림자 없음
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),  // 둥근 모서리
                side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),  // 테두리
              ),
            ),

            // ElevatedButton 스타일 (일반 버튼)
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF212121),  // 버튼 배경색
                foregroundColor: Colors.white,             // 버튼 글자색
                elevation: 0,  // 그림자 없음
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            // Dialog 스타일 (팝업)
            dialogTheme: DialogThemeData(
              backgroundColor: Colors.white,
              elevation: 4,  // 약간의 그림자
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // 다크 테마 정의 (어두운 화면)
          // 라이트 테마와 동일한 구조이지만 색상이 다름
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFFBB86FC),        // 보라색 (다크모드에서 눈에 편한 색)
              secondary: const Color(0xFF03DAC6),      // 청록색
              surface: const Color(0xFF1E1E1E),        // 어두운 배경
              surfaceContainerHighest: const Color(0xFF2C2C2C),
              onPrimary: Colors.black,                 // 보라색 위의 텍스트는 검정색
              onSecondary: Colors.black,
              onSurface: Colors.white,                 // 어두운 배경 위의 텍스트는 흰색
              outline: const Color(0xFF3E3E3E),
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),  // 아주 어두운 배경
            fontFamily: 'AppleSDGothicNeo',
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF1E1E1E),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF3E3E3E), width: 1),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBB86FC),
                foregroundColor: Colors.black,  // 보라색 버튼에 검정 글씨
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: const Color(0xFF2C2C2C),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // 앱이 시작될 때 보여줄 첫 화면
          home: const HomeScreen(),
        );
      },
    );
  }
}
