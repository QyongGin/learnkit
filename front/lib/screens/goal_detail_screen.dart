import 'package:flutter/material.dart';
// intl: 날짜/시간 포맷팅 (DateFormat)
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../models/goal.dart';
import '../models/study_session.dart';
import '../services/api_service.dart';
import 'goal_form_screen.dart';

/// 목표 상세 화면 - 학습 세션 기록 표시
class GoalDetailScreen extends StatefulWidget {
  final Goal goal;

  const GoalDetailScreen({super.key, required this.goal});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  List<StudySession> _sessions = [];
  bool _isLoading = true;
  Goal? _latestGoal;

  @override
  void initState() {
    super.initState();
    _latestGoal = widget.goal;
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sessions = await ApiService.fetchSessionsByGoal(widget.goal.id);
      // 최신순 정렬
      sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));

      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('학습 기록을 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoalFormScreen(goal: _latestGoal),
      ),
    );

    if (result == true) {
      // 목표 정보 새로고침
      try {
        final updatedGoal = await ApiService.fetchGoals(_latestGoal!.id);
        setState(() {
          if (updatedGoal.isNotEmpty) {
            _latestGoal = updatedGoal.first;
          }
        });
      } catch (e) {
        // 실패 시 무시
      }
    }
  }

  Future<void> _deleteGoal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('목표 삭제'),
        content: const Text('이 목표를 삭제하시겠습니까?\n학습 기록도 함께 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteGoal(widget.goal.id);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('목표가 삭제되었습니다')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('삭제 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  DateTime? _getLastStudyDate() {
    if (_sessions.isEmpty) return null;
    return _sessions.first.startedAt;
  }

  @override
  Widget build(BuildContext context) {
    final goal = _latestGoal ?? widget.goal;
    final lastStudyDate = _getLastStudyDate();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(goal.title, style: AppTextStyles.heading2),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
            onPressed: _navigateToEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: _deleteGoal,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSessions,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressCard(goal),
              const SizedBox(height: AppSpacing.xl),

              if (lastStudyDate != null) _buildLastStudyCard(lastStudyDate),
              if (lastStudyDate != null) const SizedBox(height: AppSpacing.xl),

              // 학습 기록 섹션
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '학습 기록',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF191F28),
                    ),
                  ),
                  Text(
                    '${_sessions.length}회',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 학습 기록 목록
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_sessions.isEmpty)
                _buildEmptyState()
              else
                ..._sessions.map((session) => _buildSessionCard(session)),
            ],
          ),
        ),
      ),
    );
  }

  /// 진행도 카드
  Widget _buildProgressCard(Goal goal) {
    final progressPercentage = goal.progressPercentage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: goal.isCompleted
              ? [const Color(0xFF20C997), const Color(0xFF12B886)]
              : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (goal.isCompleted
                    ? const Color(0xFF20C997)
                    : const Color(0xFF6366F1))
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (goal.isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    '완료',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // 진행도 숫자
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${goal.currentProgress}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              Text(
                ' / ${goal.totalTargetAmount} ${goal.targetUnit}',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 진행률 바
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressPercentage / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),

          // 퍼센트와 남은 양
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${progressPercentage.toStringAsFixed(0)}% 달성',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (!goal.isCompleted)
                Text(
                  '${goal.remainingAmount} ${goal.targetUnit} 남음',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 최근 학습일 카드
  Widget _buildLastStudyCard(DateTime lastDate) {
    final daysAgo = DateTime.now().difference(lastDate).inDays;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Color(0xFF6366F1),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '최근 학습일',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('yyyy.MM.dd').format(lastDate),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            daysAgo == 0
                ? '오늘'
                : daysAgo == 1
                    ? '어제'
                    : '$daysAgo일 전',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// 빈 상태
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.history_outlined,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            '학습 기록이 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// 학습 세션 카드
  Widget _buildSessionCard(StudySession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜와 시간
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('yyyy.MM.dd HH:mm').format(session.startedAt),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 학습 정보
          Row(
            children: [
              _buildSessionInfo(
                icon: Icons.timer_outlined,
                label: '${session.durationMinutes}분',
                color: const Color(0xFF6366F1),
              ),
              const SizedBox(width: 16),
              _buildSessionInfo(
                icon: Icons.local_fire_department_outlined,
                label: '${session.pomoCount}세트',
                color: const Color(0xFFFF6B6B),
              ),
              const SizedBox(width: 16),
              _buildSessionInfo(
                icon: Icons.check_circle_outline,
                label: '${session.achievedAmount} ${widget.goal.targetUnit}',
                color: const Color(0xFF20C997),
              ),
            ],
          ),

          // 메모
          if (session.note != null && session.note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                session.note!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSessionInfo({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
