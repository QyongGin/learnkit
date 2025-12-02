import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/goal.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import 'goal_detail_screen.dart';
import 'goal_form_screen.dart';

/// 목표 목록 화면
class GoalListScreen extends StatefulWidget {
  const GoalListScreen({super.key});

  @override
  State<GoalListScreen> createState() => _GoalListScreenState();
}

class _GoalListScreenState extends State<GoalListScreen> {
  List<Goal> _goals = [];
  bool _isLoading = true;
  int _userId = 1;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    final authService = await AuthService.getInstance();
    if (mounted) {
      setState(() => _userId = authService.currentUserId);
      _loadGoals();
    }
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);

    try {
      final goals = await ApiService.fetchGoals(_userId);
      if (mounted) {
        setState(() {
          _goals = goals;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.showError(context, '목표를 불러오는데 실패했습니다');
      }
    }
  }

  Future<void> _navigateToGoalForm([Goal? goal]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => GoalFormScreen(goal: goal)),
    );
    if (result == true) _loadGoals();
  }

  void _navigateToGoalDetail(Goal goal) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: goal)),
    ).then((_) => _loadGoals());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBarStyles.standard(title: '목표'),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToGoalForm(),
        backgroundColor: AppColors.textPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator();
    }

    if (_goals.isEmpty) {
      return EmptyState(
        icon: Icons.flag_outlined,
        title: '목표가 없습니다',
        subtitle: '+ 버튼을 눌러 첫 목표를 추가해보세요',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGoals,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _goals.length,
        itemBuilder: (_, index) => _GoalCard(
          goal: _goals[index],
          onTap: () => _navigateToGoalDetail(_goals[index]),
        ),
      ),
    );
  }
}

/// 목표 카드 위젯 (분리하여 재사용 가능)
class _GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onTap;

  const _GoalCard({
    required this.goal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercentage = goal.progressPercentage;
    final isCompleted = goal.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: isCompleted
          ? AppDecorations.cardWithBorder(AppColors.success)
          : AppDecorations.card,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더: 제목 + 완료 뱃지
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal.title,
                        style: AppTextStyles.heading3,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCompleted) const CompletedBadge(),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 진행도 텍스트
                Row(
                  children: [
                    Text(
                      '${goal.currentProgress}',
                      style: AppTextStyles.numberSmall,
                    ),
                    Text(
                      ' / ${goal.totalTargetAmount} ${goal.targetUnit}',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      NumberUtils.formatPercentage(progressPercentage),
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // 진행률 바
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: LinearProgressIndicator(
                    value: progressPercentage / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),

                // 기간 정보
                if (goal.startDate != null || goal.endDate != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: AppSpacing.xs + 2),
                      Text(
                        AppDateUtils.formatDateRange(goal.startDate, goal.endDate),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
