import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// 화면에서 공통으로 사용되는 초기화 로직을 담은 Mixin
/// 
/// 사용법:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with AuthMixin {
///   @override
///   void initState() {
///     super.initState();
///     initAuth(); // AuthMixin에서 제공
///   }
/// }
/// ```

mixin AuthMixin<T extends StatefulWidget> on State<T> {
  int userId = 1;
  bool isAuthInitialized = false;

  /// 인증 서비스 초기화 및 userId 설정
  /// 
  /// 완료 후 [onAuthInitialized]를 호출하여 추가 작업 가능
  Future<void> initAuth() async {
    final authService = await AuthService.getInstance();
    if (mounted) {
      setState(() {
        userId = authService.currentUserId;
        isAuthInitialized = true;
      });
      onAuthInitialized();
    }
  }

  /// 인증 초기화 완료 후 호출되는 콜백
  /// 
  /// 오버라이드하여 데이터 로드 등 추가 작업 수행
  void onAuthInitialized() {
    // 서브클래스에서 오버라이드
  }
}
