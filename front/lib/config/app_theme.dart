import 'package:flutter/material.dart';

/// 앱 전역 테마 및 스타일 상수
/// 
/// 모든 화면에서 일관된 디자인을 위해 색상, 스타일을 한 곳에서 관리합니다.
/// 
/// 사용법:
/// ```dart
/// import '../config/app_theme.dart';
/// 
/// Container(color: AppColors.primary)
/// Text('제목', style: AppTextStyles.heading1)
/// ```

/// 색상 상수
class AppColors {
  AppColors._(); // 인스턴스 생성 방지

  // 브랜드 컬러
  static const Color primary = Color(0xFF6366F1);      // 인디고 (메인)
  static const Color primaryLight = Color(0xFF8B5CF6); // 연한 인디고
  static const Color primaryDark = Color(0xFF4F46E5);  // 진한 인디고

  // 상태 컬러
  static const Color success = Color(0xFF20C997);      // 초록 (완료, 쉬움)
  static const Color warning = Color(0xFFFFA726);      // 주황 (경고)
  static const Color error = Color(0xFFFF6B6B);        // 빨강 (에러, 어려움)
  static const Color info = Color(0xFF3182F6);         // 파랑 (정보, 보통)

  // 난이도 컬러
  static const Color difficultyEasy = success;
  static const Color difficultyNormal = info;
  static const Color difficultyHard = error;

  // 배경 컬러
  static const Color background = Color(0xFFF9FAFB);   // 연한 회색 배경
  static const Color backgroundAlt = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;           // 카드/컨테이너 배경

  // 텍스트 컬러
  static const Color textPrimary = Color(0xFF191F28);  // 주요 텍스트
  static const Color textSecondary = Color(0xFF6B7280); // 보조 텍스트
  static const Color textHint = Color(0xFF9CA3AF);     // 힌트 텍스트

  // 보더/구분선
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);
}

/// 간격 상수
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}

/// 둥근 모서리 상수
class AppRadius {
  AppRadius._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double full = 999.0; // 완전 원형
}

/// 텍스트 스타일
class AppTextStyles {
  AppTextStyles._();

  // 제목
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
  );

  // 본문
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // 캡션/라벨
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // 버튼
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );

  // 숫자 (통계용)
  static const TextStyle number = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static const TextStyle numberSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );
}

/// 그림자 스타일
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get small => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get large => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  /// 특정 색상의 그림자 (버튼 등에 사용)
  static List<BoxShadow> colored(Color color, {double alpha = 0.3}) => [
    BoxShadow(
      color: color.withValues(alpha: alpha),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}

/// 카드 및 컨테이너 데코레이션
class AppDecorations {
  AppDecorations._();

  /// 기본 카드 스타일
  static BoxDecoration get card => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    boxShadow: AppShadows.small,
  );

  /// 강조 카드 (테두리 포함)
  static BoxDecoration cardWithBorder(Color borderColor) => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    border: Border.all(color: borderColor, width: 2),
    boxShadow: AppShadows.small,
  );

  /// 하단 네비게이션 바 스타일
  static BoxDecoration get bottomNavBar => BoxDecoration(
    color: AppColors.surface,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 10,
        offset: const Offset(0, -2),
      ),
    ],
  );

  /// 입력 필드 스타일
  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    Widget? suffixIcon,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
  );
}

/// AppBar 스타일
class AppBarStyles {
  AppBarStyles._();

  /// 기본 흰색 AppBar
  static AppBar standard({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = false,
  }) => AppBar(
    backgroundColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    leading: leading,
    title: Text(
      title,
      style: AppTextStyles.heading2,
    ),
    centerTitle: centerTitle,
    actions: actions,
  );
}
