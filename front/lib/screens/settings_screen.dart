// Flutter의 Material Design 위젯 제공
import 'package:flutter/material.dart';
// iOS 스타일 위젯 제공 (CupertinoSwitch 사용)
import 'package:flutter/cupertino.dart';
// Provider 패턴으로 상태 관리
import 'package:provider/provider.dart';
// 앱 설정 관리 Provider
import '../providers/settings_provider.dart';

/// 설정 화면
/// - 다크모드 토글
/// - 센서 사용 토글
/// - 앱 정보 표시
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 배경색 설정 (연한 회색)
      backgroundColor: const Color(0xFFF5F5F5),
      // 상단 앱바
      appBar: AppBar(
        title: const Text(
          '설정',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,  // 그림자 제거
        centerTitle: true,  // 타이틀 중앙 정렬
      ),
      // Consumer: SettingsProvider 변경 감지 및 UI 자동 업데이트
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          // 설정 로딩 중이면 로딩 표시
          if (settings.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // === 앱 설정 섹션 ===
              _buildSectionTitle('앱 설정'),
              const SizedBox(height: 8),
              _buildSettingsCard(
                context,
                children: [
                  // 다크모드 토글
                  _buildSwitchTile(
                    context: context,
                    icon: Icons.dark_mode,
                    iconColor: const Color(0xFF6366F1),
                    title: '다크 모드',
                    subtitle: '어두운 테마를 사용합니다',
                    value: settings.isDarkMode,
                    // settings.setDarkMode() 호출로 다크모드 변경
                    onChanged: (value) => settings.setDarkMode(value),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // === 포모도로 타이머 설정 섹션 ===
              _buildSectionTitle('포모도로 타이머'),
              const SizedBox(height: 8),
              _buildSettingsCard(
                context,
                children: [
                  // 센서 사용 토글 (물음표 도움말 아이콘 포함)
                  _buildSwitchTileWithHelp(
                    context: context,
                    icon: Icons.screen_rotation,
                    iconColor: const Color(0xFFFF6B6B),
                    title: '센서 사용',
                    subtitle: '폰 뒤집기 동작으로 타이머를 제어합니다',
                    value: settings.isSensorEnabled,
                    onChanged: (value) => settings.setSensorEnabled(value),
                    helpTitle: '센서 사용법',
                    helpContent: '📱 위로 뒤집으면 학습 시작\n📱 앞으로 뒤집으면 일시정지',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // === 알림 설정 섹션 ===
              _buildSectionTitle('알림'),
              const SizedBox(height: 8),
              _buildSettingsCard(
                context,
                children: [
                  // 자동 알림 토글 (물음표 도움말 아이콘 포함)
                  _buildSwitchTileWithHelp(
                    context: context,
                    icon: Icons.notifications_active,
                    iconColor: const Color(0xFFFFA726),
                    title: '자동 알림',
                    subtitle: settings.autoNotification
                        ? '주 사용 시간대 기반 알림'
                        : '수동으로 알림 시간 설정',
                    value: settings.autoNotification,
                    onChanged: (value) => settings.setAutoNotification(value),
                    helpTitle: '알림 안내',
                    helpContent: settings.autoNotification
                        ? '📊 앱 사용 패턴을 분석하여\n가장 활발하게 사용하는 시간대에\n매일 알림을 보냅니다'
                        : '⏰ 설정한 시간에\n매일 학습 알림을 보냅니다',
                  ),
                  // 수동 알림 시간 선택 (자동 알림 OFF일 때만 표시)
                  if (!settings.autoNotification) ...[
                    const Divider(height: 1),
                    _buildTimePickerTile(
                      context: context,
                      settings: settings,
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              // === 앱 정보 섹션 ===
              _buildSectionTitle('앱 정보'),
              const SizedBox(height: 8),
              _buildSettingsCard(
                context,
                children: [
                  // 앱 버전 표시
                  _buildInfoTile(
                    context: context,
                    icon: Icons.info,
                    iconColor: Colors.grey,
                    title: '버전',
                    subtitle: '1.0.0',
                  ),
                ],
              ),

              const SizedBox(height: 80),  // 하단 여백
            ],
          );
        },
      ),
    );
  }

  /// 섹션 타이틀 위젯 생성
  /// 설정 카테고리 제목 표시 (회색, 작은 글씨)
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF757575),  // 회색
          letterSpacing: 0.5,  // 글자 간격
        ),
      ),
    );
  }

  /// 설정 카드 컨테이너 생성
  /// 흰색 배경, 둥근 모서리, 그림자 효과
  Widget _buildSettingsCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),  // 둥근 모서리
        boxShadow: [
          // 약간의 그림자 효과
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),  // 아래쪽으로 2px
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  /// 스위치 토글 타일 생성
  /// 아이콘, 제목, 설명, iOS 스타일 스위치 포함
  ///
  /// 매개변수:
  /// - icon: 아이콘
  /// - iconColor: 아이콘 배경색 및 스위치 활성 색상
  /// - title: 설정 제목
  /// - subtitle: 설정 설명
  /// - value: 현재 스위치 상태 (true/false)
  /// - onChanged: 스위치 토글 시 호출되는 콜백 함수
  Widget _buildSwitchTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      // 아이콘 영역 (둥근 배경에 아이콘)
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),  // 반투명 배경
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      // 설정 제목
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
        ),
      ),
      // 설정 설명
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
      // iOS 스타일 스위치
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: iconColor,  // 켜짐 상태 색상
      ),
    );
  }

  /// 정보 표시 타일 (읽기 전용)
  /// 아이콘, 제목, 설명만 표시. 탭 동작 없음
  ///
  /// 용도: 센서 사용법 안내, 앱 버전 표시 등
  Widget _buildInfoTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      // 아이콘 영역
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),  // 반투명 배경
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      // 제목
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
        ),
      ),
      // 설명
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  /// 시간 선택 타일
  /// 사용자가 탭하면 TimePicker를 표시하여 알림 시간 선택
  ///
  /// 매개변수:
  /// - context: BuildContext
  /// - settings: SettingsProvider 인스턴스
  Widget _buildTimePickerTile({
    required BuildContext context,
    required SettingsProvider settings,
  }) {
    // 시간을 "오후 7:00" 형식으로 포맷
    final hour = settings.manualNotificationHour;
    final minute = settings.manualNotificationMinute;
    final timeString = _formatTime(hour, minute);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      // 아이콘 영역
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFFA726).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.access_time, color: Color(0xFFFFA726), size: 24),
      ),
      // 제목
      title: const Text(
        '알림 시간',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
        ),
      ),
      // 설정된 시간 표시
      subtitle: Text(
        timeString,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
      // 우측 화살표 아이콘
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey.shade400,
      ),
      // 탭 시 TimePicker 표시
      onTap: () => _showTimePicker(context, settings),
    );
  }

  /// 시간 포맷팅
  /// 24시간제를 12시간제 + 오전/오후로 변환
  ///
  /// 예: (19, 0) → "오후 7:00"
  ///     (9, 30) → "오전 9:30"
  String _formatTime(int hour, int minute) {
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minuteString = minute.toString().padLeft(2, '0');
    return '$period $displayHour:$minuteString';
  }

  /// TimePicker 다이얼로그 표시
  ///
  /// Material Design 스타일의 시간 선택 다이얼로그를 표시하고
  /// 사용자가 선택한 시간을 SettingsProvider에 저장
  Future<void> _showTimePicker(BuildContext context, SettingsProvider settings) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.manualNotificationHour,
        minute: settings.manualNotificationMinute,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            // TimePicker 색상 커스터마이징
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFFA726), // 선택된 시간 색상
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF212121),
            ),
          ),
          child: child!,
        );
      },
    );

    // 사용자가 시간을 선택했을 때만 저장
    if (picked != null) {
      await settings.setManualNotificationTime(picked.hour, picked.minute);
    }
  }

  /// 스위치 토글 타일 생성 (물음표 도움말 아이콘 포함)
  ///
  /// 기본 스위치 타일에 물음표 아이콘을 추가하여
  /// 사용자가 원할 때만 도움말을 볼 수 있도록 함
  ///
  /// 매개변수:
  /// - helpTitle: 도움말 팝업 제목
  /// - helpContent: 도움말 내용
  Widget _buildSwitchTileWithHelp({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required String helpTitle,
    required String helpContent,
  }) {
    // 물음표 아이콘의 위치를 저장하기 위한 GlobalKey
    final GlobalKey iconKey = GlobalKey();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      // 아이콘 영역 (둥근 배경에 아이콘)
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      // 설정 제목 및 물음표 아이콘
      title: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(width: 6),
          // 물음표 도움말 아이콘 (토스 스타일)
          GestureDetector(
            key: iconKey,
            onTap: () => _showHelpTooltip(context, iconKey, helpTitle, helpContent),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.question_mark,
                size: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
      // 설정 설명
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
      // iOS 스타일 스위치
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: iconColor,
      ),
    );
  }

  /// 도움말 툴팁 표시 (토스/네이버 스타일 말풍선)
  ///
  /// 물음표 아이콘을 탭했을 때 호출되는 함수
  /// 아이콘 바로 위에 흰색 말풍선 스타일 툴팁 표시
  void _showHelpTooltip(
    BuildContext context,
    GlobalKey iconKey,
    String title,
    String content,
  ) {
    // 물음표 아이콘의 위치 정보 가져오기
    final RenderBox? renderBox =
        iconKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    // 화면 크기 가져오기
    final screenWidth = MediaQuery.of(context).size.width;

    // Overlay를 사용한 커스텀 툴팁
    final overlayState = Overlay.of(context);
    OverlayEntry? overlayEntry;

    // 툴팁 크기
    const tooltipWidth = 240.0;
    const tooltipPadding = 16.0;

    // 아이콘 중심 위치
    final iconCenterX = offset.dx + size.width / 2;

    // 툴팁이 화면 밖으로 나가지 않도록 left 계산
    double tooltipLeft = iconCenterX - tooltipWidth / 2;
    if (tooltipLeft < tooltipPadding) {
      tooltipLeft = tooltipPadding;
    } else if (tooltipLeft + tooltipWidth > screenWidth - tooltipPadding) {
      tooltipLeft = screenWidth - tooltipWidth - tooltipPadding;
    }

    // 삼각형 화살표의 위치 (아이콘을 가리키도록)
    final arrowOffset = iconCenterX - tooltipLeft - 8; // 8은 화살표 너비의 절반

    overlayEntry = OverlayEntry(
      builder: (context) {
        // 툴팁 내용의 높이를 측정하기 위한 TextPainter 사용
        final titlePainter = TextPainter(
          text: TextSpan(
            text: title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF191919),
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: tooltipWidth - 28); // padding 고려

        final contentPainter = TextPainter(
          text: TextSpan(
            text: content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF666666),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: tooltipWidth - 28); // padding 고려

        // 툴팁의 총 높이 계산
        final tooltipHeight = 28 + // padding (14 * 2)
            titlePainter.height +
            6 + // 제목-내용 간격
            contentPainter.height;

        const arrowHeight = 8.0;
        const spacing = 8.0; // 아이콘과 화살표 사이 간격

        // 툴팁이 물음표 바로 위에 오도록 top 계산
        final tooltipTop = offset.dy - tooltipHeight - arrowHeight - spacing;

        return GestureDetector(
          // 배경 탭 시 툴팁 닫기
          onTap: () => overlayEntry?.remove(),
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              // 툴팁 위치 (아이콘 바로 위)
              Positioned(
                left: tooltipLeft,
                top: tooltipTop,
                child: Material(
                  color: Colors.transparent,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - value) * -8),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 말풍선 본체 (토스/네이버 스타일: 흰색 배경)
                        Container(
                          width: tooltipWidth,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFE0E0E0),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 제목
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF191919),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // 내용
                              Text(
                                content,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 삼각형 화살표 (말풍선 아래)
                        Padding(
                          padding: EdgeInsets.only(left: arrowOffset),
                          child: CustomPaint(
                            size: const Size(16, 8),
                            painter: _TrianglePainter(
                              color: Colors.white,
                              borderColor: const Color(0xFFE0E0E0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    overlayState.insert(overlayEntry);

    // 3초 후 자동으로 닫기
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry?.remove();
    });
  }
}

/// 삼각형 화살표 그리기 (말풍선 포인터용)
class _TrianglePainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  _TrianglePainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    // 테두리 그리기
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;

    final borderPath = Path()
      ..moveTo(size.width / 2 - 8, 0) // 왼쪽
      ..lineTo(size.width / 2, size.height) // 아래 (뾰족한 부분)
      ..lineTo(size.width / 2 + 8, 0) // 오른쪽
      ..close();

    canvas.drawPath(borderPath, borderPaint);

    // 내부 채우기
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final fillPath = Path()
      ..moveTo(size.width / 2 - 7, 0)
      ..lineTo(size.width / 2, size.height - 1)
      ..lineTo(size.width / 2 + 7, 0)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

}
