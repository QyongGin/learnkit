import 'package:flutter/material.dart';
// intl: 날짜/시간 포맷팅 (DateFormat)
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/common_widgets.dart';

/// 주간 정산 화면
class WeeklySummaryScreen extends StatefulWidget {
  const WeeklySummaryScreen({super.key});

  @override
  State<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends State<WeeklySummaryScreen> {
  Map<int, GoalSummary> _goalSummaries = {};
  bool _isLoading = true;
  int _userId = 1;

  // 전체 통계
  int _totalMinutes = 0;
  int _totalPomodoros = 0;
  int _totalSessions = 0;

  @override
  void initState() {
    super.initState();
    _initAuth();
    _loadWeeklySummary();
  }

  Future<void> _initAuth() async {
    final authService = await AuthService.getInstance();
    setState(() {
      _userId = authService.currentUserId;
    });
  }

  Future<void> _loadWeeklySummary() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 지난 7일 세션 가져오기
      final allSessions = await ApiService.fetchUserSessions(_userId);
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final weeklySessions = allSessions.where((session) {
        return session.startedAt.isAfter(weekAgo);
      }).toList();

      // 전체 통계 계산
      int totalMinutes = 0;
      int totalPomodoros = 0;
      for (var session in weeklySessions) {
        totalMinutes += session.durationMinutes;
        totalPomodoros += session.pomoCount;
      }

      // 목표별 집계
      final Map<int, GoalSummary> goalSummaries = {};
      for (var session in weeklySessions) {
        if (session.goalId == null) continue;

        if (!goalSummaries.containsKey(session.goalId)) {
          goalSummaries[session.goalId!] = GoalSummary(
            goalId: session.goalId!,
            goalTitle: session.goalTitle ?? '목표 없음',
            totalMinutes: 0,
            totalPomodoros: 0,
            totalAchieved: 0,
            sessionCount: 0,
          );
        }

        goalSummaries[session.goalId]!.totalMinutes += session.durationMinutes;
        goalSummaries[session.goalId]!.totalPomodoros += session.pomoCount;
        goalSummaries[session.goalId]!.totalAchieved += session.achievedAmount;
        goalSummaries[session.goalId]!.sessionCount += 1;
      }

      setState(() {
        _goalSummaries = goalSummaries;
        _totalMinutes = totalMinutes;
        _totalPomodoros = totalPomodoros;
        _totalSessions = weeklySessions.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('주간 정산을 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  String _getWeekPeriod() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return '${DateFormat('M.d').format(weekAgo)} - ${DateFormat('M.d').format(now)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '주간 정산',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : RefreshIndicator(
              onRefresh: _loadWeeklySummary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 기간 표시
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '최근 7일 (${_getWeekPeriod()})',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 전체 요약 카드
                    _buildOverallSummary(),
                    const SizedBox(height: AppSpacing.xxl),

                    // 목표별 통계
                    if (_goalSummaries.isNotEmpty) ...[
                      Text(
                        '목표별 달성도',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      ..._goalSummaries.values.map((summary) {
                        return _buildGoalSummaryCard(summary);
                      }),
                    ] else ...[
                      _buildEmptyState(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  /// 전체 요약 카드 (그라데이션)
  Widget _buildOverallSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withBlue(240)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '이번 주 총 학습량',
                style: AppTextStyles.heading3.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          // 3개 통계
          Row(
            children: [
              Expanded(
                child: _buildOverallStatItem(
                  label: '학습 시간',
                  value: '${(_totalMinutes / 60).toStringAsFixed(1)}h',
                  subValue: '$_totalMinutes분',
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withValues(alpha: 0.3),
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              ),
              Expanded(
                child: _buildOverallStatItem(
                  label: '포모도로',
                  value: '$_totalPomodoros',
                  subValue: '세트',
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withValues(alpha: 0.3),
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              ),
              Expanded(
                child: _buildOverallStatItem(
                  label: '학습 횟수',
                  value: '$_totalSessions',
                  subValue: '회',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStatItem({
    required String label,
    required String value,
    required String subValue,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.number.copyWith(
            color: Colors.white,
            fontSize: 26,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subValue,
          style: AppTextStyles.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  /// 목표별 요약 카드
  Widget _buildGoalSummaryCard(GoalSummary summary) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 목표 제목
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  Icons.flag,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  summary.goalTitle,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  '${summary.sessionCount}회',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 통계 그리드
          Row(
            children: [
              Expanded(
                child: _buildGoalStatItem(
                  icon: Icons.timer_outlined,
                  label: '학습 시간',
                  value: '${summary.totalMinutes}분',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildGoalStatItem(
                  icon: Icons.local_fire_department_outlined,
                  label: '포모도로',
                  value: '${summary.totalPomodoros}세트',
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildGoalStatItem(
                  icon: Icons.check_circle_outline,
                  label: '달성량',
                  value: '${summary.totalAchieved}',
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.insert_chart_outlined,
      title: '이번 주 학습 기록이 없습니다',
    );
  }
}

/// 목표별 요약 데이터 클래스
class GoalSummary {
  final int goalId;
  final String goalTitle;
  int totalMinutes;
  int totalPomodoros;
  int totalAchieved;
  int sessionCount;

  GoalSummary({
    required this.goalId,
    required this.goalTitle,
    required this.totalMinutes,
    required this.totalPomodoros,
    required this.totalAchieved,
    required this.sessionCount,
  });
}
