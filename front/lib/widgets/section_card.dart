import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// 카드 형태의 섹션 위젯
class SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? customContent;
  final VoidCallback? onTap;

  const SectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.customContent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: AppDecorations.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: AppTextStyles.heading3),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textHint,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (customContent != null)
              customContent!
            else
              Text(subtitle, style: AppTextStyles.body2),
          ],
        ),
      ),
    );
  }
}

/// 원형 진행도 위젯
class CircularProgressWidget extends StatelessWidget {
  final int completed;
  final int total;

  const CircularProgressWidget({
    super.key,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;
    
    return Row(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.success,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$completed/$total',
              style: AppTextStyles.label,
            ),
            Row(
              children: List.generate(
                total,
                (index) => Container(
                  margin: const EdgeInsets.only(right: 4, top: 4),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < completed
                        ? AppColors.success
                        : AppColors.divider,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 선형 진행도 바 위젯
class LinearProgressWidget extends StatelessWidget {
  final int percentage;

  const LinearProgressWidget({
    super.key,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '진행도 $percentage%',
          style: AppTextStyles.body2,
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 20,
            backgroundColor: AppColors.divider,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.success,
            ),
          ),
        ),
      ],
    );
  }
}
