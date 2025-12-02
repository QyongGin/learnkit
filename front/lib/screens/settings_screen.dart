import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../providers/settings_provider.dart';

/// 설정 화면
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      appBar: AppBar(
        title: Text('설정', style: AppTextStyles.heading2),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          if (settings.isLoading) return const LoadingIndicator();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const SettingsSectionTitle('포모도로 타이머'),
              const SizedBox(height: AppSpacing.sm),
              SettingsCard(
                children: [
                  _SwitchTileWithHelp(
                    icon: Icons.screen_rotation,
                    iconColor: AppColors.error,
                    title: '센서 사용',
                    subtitle: '폰 뒤집기 동작으로 타이머를 제어합니다',
                    value: settings.isSensorEnabled,
                    onChanged: settings.setSensorEnabled,
                    helpTitle: '센서 사용법',
                    helpContent: '📱 위로 뒤집으면 학습 시작\n📱 앞으로 뒤집으면 일시정지',
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xxl),

              const SettingsSectionTitle('알림'),
              const SizedBox(height: 8),
              SettingsCard(
                children: [
                  _SwitchTile(
                    icon: Icons.notifications,
                    iconColor: const Color(0xFF42A5F5),
                    title: '알림 사용',
                    subtitle: settings.notificationEnabled ? '알림이 켜져 있습니다' : '알림이 꺼져 있습니다',
                    value: settings.notificationEnabled,
                    onChanged: settings.setNotificationEnabled,
                  ),
                  
                  if (settings.notificationEnabled) ...[
                    const Divider(height: 1),
                    _SwitchTileWithHelp(
                      icon: Icons.auto_awesome,
                      iconColor: const Color(0xFFFFA726),
                      title: '자동 알림',
                      subtitle: settings.autoNotification ? '앱 사용 패턴 기반 알림' : '수동으로 시간 설정',
                      value: settings.autoNotification,
                      onChanged: settings.setAutoNotification,
                      helpTitle: '자동 알림 안내',
                      helpContent: settings.autoNotification
                          ? '📊 앱 사용 패턴을 분석하여\n가장 활발하게 사용하는 시간대에\n매일 알림을 보냅니다'
                          : '⏰ 설정한 시간에\n매일 학습 알림을 보냅니다',
                    ),
                    
                    if (settings.autoNotification) ...[
                      const Divider(height: 1),
                      SettingsInfoTile(
                        icon: Icons.schedule,
                        iconColor: const Color(0xFF66BB6A),
                        title: '오늘의 알림 시간',
                        subtitle: _formatTime(settings.autoNotificationHour, settings.autoNotificationMinute),
                        trailing: '자동 설정',
                      ),
                    ],
                    
                    if (!settings.autoNotification) ...[
                      const Divider(height: 1),
                      SettingsTimeTile(
                        timeString: _formatTime(settings.manualNotificationHour, settings.manualNotificationMinute),
                        onTap: () => _showTimePicker(context, settings),
                      ),
                    ],
                  ],
                ],
              ),

              const SizedBox(height: 24),

              const SettingsSectionTitle('앱 정보'),
              const SizedBox(height: 8),
              const SettingsCard(
                children: [
                  SettingsInfoTile(
                    icon: Icons.info,
                    iconColor: Colors.grey,
                    title: '버전',
                    subtitle: '1.0.0',
                  ),
                ],
              ),

              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  static String _formatTime(int hour, int minute) {
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$period $displayHour:${minute.toString().padLeft(2, '0')}';
  }

  static Future<void> _showTimePicker(BuildContext context, SettingsProvider settings) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.manualNotificationHour, minute: settings.manualNotificationMinute),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFFFA726),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF212121),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) await settings.setManualNotificationTime(picked.hour, picked.minute);
  }
}

// 설정 아이콘 (둥근 배경)
class _SettingsIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _SettingsIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

// 스위치 타일
class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: _SettingsIcon(icon: icon, color: iconColor),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF212121))),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      trailing: CupertinoSwitch(value: value, onChanged: onChanged, activeTrackColor: iconColor),
    );
  }
}

// 스위치 타일 + 물음표 도움말
class _SwitchTileWithHelp extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String helpTitle;
  final String helpContent;

  const _SwitchTileWithHelp({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.helpTitle,
    required this.helpContent,
  });

  @override
  Widget build(BuildContext context) {
    final iconKey = GlobalKey();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: _SettingsIcon(icon: icon, color: iconColor),
      title: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF212121))),
          const SizedBox(width: 6),
          GestureDetector(
            key: iconKey,
            onTap: () => _showHelpTooltip(context, iconKey),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
              child: Icon(Icons.question_mark, size: 12, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      trailing: CupertinoSwitch(value: value, onChanged: onChanged, activeTrackColor: iconColor),
    );
  }

  void _showHelpTooltip(BuildContext context, GlobalKey iconKey) {
    final renderBox = iconKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenWidth = MediaQuery.of(context).size.width;
    final overlayState = Overlay.of(context);
    
    late OverlayEntry overlayEntry;
    bool isRemoved = false;
    
    void removeOverlay() {
      if (!isRemoved) {
        isRemoved = true;
        overlayEntry.remove();
      }
    }

    const tooltipWidth = 240.0;
    const tooltipPadding = 16.0;
    final iconCenterX = offset.dx + size.width / 2;

    double tooltipLeft = iconCenterX - tooltipWidth / 2;
    tooltipLeft = tooltipLeft.clamp(tooltipPadding, screenWidth - tooltipWidth - tooltipPadding);

    final arrowOffset = iconCenterX - tooltipLeft - 8;

    overlayEntry = OverlayEntry(
      builder: (context) {
        final titlePainter = TextPainter(
          text: TextSpan(text: helpTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: tooltipWidth - 28);

        final contentPainter = TextPainter(
          text: TextSpan(text: helpContent, style: const TextStyle(fontSize: 13, height: 1.5)),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: tooltipWidth - 28);

        final tooltipHeight = 28 + titlePainter.height + 6 + contentPainter.height;
        final tooltipTop = offset.dy - tooltipHeight - 16;

        return GestureDetector(
          onTap: removeOverlay,
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              Positioned(
                left: tooltipLeft,
                top: tooltipTop,
                child: Material(
                  color: Colors.transparent,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(offset: Offset(0, (1 - value) * -8), child: child),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: tooltipWidth,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(helpTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF191919))),
                              const SizedBox(height: 6),
                              Text(helpContent, style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF666666))),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: arrowOffset),
                          child: CustomPaint(size: const Size(16, 8), painter: _TrianglePainter()),
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
    Future.delayed(const Duration(seconds: 3), removeOverlay);
  }
}

// 삼각형 화살표 (말풍선 포인터)
class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()..color = const Color(0xFFE0E0E0)..style = PaintingStyle.fill;
    final borderPath = Path()..moveTo(size.width / 2 - 8, 0)..lineTo(size.width / 2, size.height)..lineTo(size.width / 2 + 8, 0)..close();
    canvas.drawPath(borderPath, borderPaint);

    final fillPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final fillPath = Path()..moveTo(size.width / 2 - 7, 0)..lineTo(size.width / 2, size.height - 1)..lineTo(size.width / 2 + 7, 0)..close();
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
