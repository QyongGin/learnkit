import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/study_session.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

/// 주간 정산 화면
class WeeklySummaryScreen extends StatefulWidget {
  const WeeklySummaryScreen({super.key});

  @override
  State<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends State<WeeklySummaryScreen> {
  List<StudySession> _weeklySessions = [];
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
        _weeklySessions = weeklySessions;
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '주간 정산',
          style: TextStyle(
            color: Color(0xFF191F28),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWeeklySummary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 기간 표시
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '최근 7일 (${_getWeekPeriod()})',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 전체 요약 카드
                    _buildOverallSummary(),
                    const SizedBox(height: 24),

                    // 목표별 통계
                    if (_goalSummaries.isNotEmpty) ...[
                      const Text(
                        '목표별 달성도',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF191F28),
                        ),
                      ),
                      const SizedBox(height: 12),

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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '이번 주 총 학습량',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

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
                margin: const EdgeInsets.symmetric(horizontal: 12),
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
                margin: const EdgeInsets.symmetric(horizontal: 12),
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
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subValue,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  /// 목표별 요약 카드
  Widget _buildGoalSummaryCard(GoalSummary summary) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flag,
                  size: 18,
                  color: Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  summary.goalTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF191F28),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${summary.sessionCount}회',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 통계 그리드
          Row(
            children: [
              Expanded(
                child: _buildGoalStatItem(
                  icon: Icons.timer_outlined,
                  label: '학습 시간',
                  value: '${summary.totalMinutes}분',
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGoalStatItem(
                  icon: Icons.local_fire_department_outlined,
                  label: '포모도로',
                  value: '${summary.totalPomodoros}세트',
                  color: const Color(0xFFFF6B6B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGoalStatItem(
                  icon: Icons.check_circle_outline,
                  label: '달성량',
                  value: '${summary.totalAchieved}',
                  color: const Color(0xFF20C997),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.insert_chart_outlined,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            '이번 주 학습 기록이 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
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
