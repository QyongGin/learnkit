import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// 재사용 가능한 공통 UI 위젯 모음
/// 
/// 여러 화면에서 반복되는 UI 패턴을 위젯으로 추출하여
/// 코드 중복을 줄이고 일관성을 유지합니다.

/// 중앙 로딩 인디케이터
class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              message!,
              style: AppTextStyles.body2,
            ),
          ],
        ],
      ),
    );
  }
}

/// 에러 표시 및 재시도 버튼
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String retryText;

  const ErrorView({
    super.key,
    this.message = '데이터를 불러오는데 실패했습니다',
    this.onRetry,
    this.retryText = '다시 시도',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryText),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 데이터가 없을 때 표시하는 Empty State
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                style: AppTextStyles.body2,
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 삭제/종료 등 확인이 필요한 액션을 위한 다이얼로그
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final bool isDestructive;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = '확인',
    this.cancelText = '취소',
    this.confirmColor,
    this.isDestructive = false,
  });

  /// 다이얼로그를 표시하고 결과를 반환
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = '확인',
    String cancelText = '취소',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveConfirmColor = confirmColor ?? 
        (isDestructive ? AppColors.error : AppColors.primary);

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Text(title, style: AppTextStyles.heading3),
      content: Text(content, style: AppTextStyles.body1),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            cancelText,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            foregroundColor: effectiveConfirmColor,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }
}

/// 스낵바를 쉽게 표시하기 위한 헬퍼 클래스
class AppSnackBar {
  AppSnackBar._();

  /// 성공 메시지
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, AppColors.success, Icons.check_circle);
  }

  /// 에러 메시지
  static void showError(BuildContext context, String message) {
    _show(context, message, AppColors.error, Icons.error);
  }

  /// 정보 메시지
  static void showInfo(BuildContext context, String message) {
    _show(context, message, AppColors.info, Icons.info);
  }

  /// 일반 메시지
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static void _show(
    BuildContext context,
    String message,
    Color backgroundColor,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }
}

/// 리스트 섹션 헤더 (제목 + 선택적 액션 버튼)
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.label.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (onAction != null && actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 카드 난이도를 표시하는 뱃지
class DifficultyBadge extends StatelessWidget {
  final String difficulty; // 'EASY', 'NORMAL', 'HARD'
  final bool showLabel;

  const DifficultyBadge({
    super.key,
    required this.difficulty,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final label = _getLabel();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getColor() {
    switch (difficulty.toUpperCase()) {
      case 'EASY':
        return AppColors.difficultyEasy;
      case 'NORMAL':
        return AppColors.difficultyNormal;
      case 'HARD':
        return AppColors.difficultyHard;
      default:
        return AppColors.textHint;
    }
  }

  String _getLabel() {
    switch (difficulty.toUpperCase()) {
      case 'EASY':
        return '쉬움';
      case 'NORMAL':
        return '보통';
      case 'HARD':
        return '어려움';
      default:
        return '-';
    }
  }
}

/// 완료 상태를 표시하는 뱃지
class CompletedBadge extends StatelessWidget {
  final String label;

  const CompletedBadge({
    super.key,
    this.label = '완료',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            size: 14,
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 숫자와 라벨을 표시하는 통계 카드
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;
  final Color? borderColor;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.valueColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: borderColor != null
            ? Border.all(color: borderColor!.withValues(alpha: 0.2), width: 2)
            : null,
        boxShadow: AppShadows.small,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.number.copyWith(
              color: valueColor ?? AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.body2,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 설정 화면용 위젯
// ─────────────────────────────────────────────────────────────

/// 설정 섹션 타이틀
class SettingsSectionTitle extends StatelessWidget {
  final String title;
  const SettingsSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF757575),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// 설정 카드 컨테이너
class SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const SettingsCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

/// 설정 타일 아이콘 (둥근 배경)
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

/// 설정 타일 텍스트 스타일
class _SettingsText {
  static const title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Color(0xFF212121),
  );
  
  static TextStyle get subtitle => TextStyle(
    fontSize: 13,
    color: Colors.grey.shade600,
  );
}

/// 정보 표시 타일 (읽기 전용)
class SettingsInfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? trailing;

  const SettingsInfoTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: _SettingsIcon(icon: icon, color: iconColor),
      title: Text(title, style: _SettingsText.title),
      subtitle: trailing != null
          ? Text(subtitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1976D2)))
          : Text(subtitle, style: _SettingsText.subtitle),
      trailing: trailing != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(trailing!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: iconColor)),
            )
          : null,
    );
  }
}

/// 시간 선택 타일
class SettingsTimeTile extends StatelessWidget {
  final String timeString;
  final VoidCallback onTap;

  const SettingsTimeTile({
    super.key,
    required this.timeString,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: const _SettingsIcon(icon: Icons.access_time, color: Color(0xFFFFA726)),
      title: const Text('알림 시간', style: _SettingsText.title),
      subtitle: Text(timeString, style: _SettingsText.subtitle),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}

// ============================================================================
// 포모도로/타이머 공통 위젯
// ============================================================================

/// 통계/정보 카드 (포모도로 세트 수, 진행률 등)
class StatInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const StatInfoCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.number.copyWith(color: color)),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTextStyles.body2),
        ],
      ),
    );
  }
}

/// 그라데이션 버튼 (시작/정지/출발 등)
class GradientActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback? onTap;
  final bool showLoading;
  final String? loadingText;

  const GradientActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.colors,
    this.onTap,
    this.showLoading = false,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: showLoading
          ? Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    loadingText ?? label,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
            )
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

// ============================================================================
// 플래시카드/학습 공통 위젯
// ============================================================================

/// 플래시카드 공통 컨테이너
class FlashCard extends StatelessWidget {
  final String label;
  final String content;
  final Color labelBgColor;
  final Color labelTextColor;
  final String? hintText;
  final IconData? hintIcon;

  const FlashCard({
    super.key,
    required this.label,
    required this.content,
    this.labelBgColor = const Color(0xFFF9FAFB),
    this.labelTextColor = const Color(0xFF6B7280),
    this.hintText,
    this.hintIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 상단 라벨
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: labelBgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: labelTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // 카드 내용
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 하단 힌트
          if (hintText != null)
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hintIcon != null) ...[
                    Icon(hintIcon, size: 20, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                  ],
                  Text(hintText!, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 난이도 선택 버튼
class DifficultyButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const DifficultyButton({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// 이모지가 있는 난이도 선택 버튼 (study_screen용)
class DifficultyOptionButton extends StatelessWidget {
  final String title;      // "쉬움 😊"
  final String subtitle;   // "3배"
  final Color color;
  final VoidCallback onTap;

  const DifficultyOptionButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final parts = title.split(' ');
    final label = parts.first;
    final emoji = parts.length > 1 ? parts.last : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

