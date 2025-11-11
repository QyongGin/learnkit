import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
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
    _loadGoals();
  }

  Future<void> _initAuth() async {
    final authService = await AuthService.getInstance();
    setState(() {
      _userId = authService.currentUserId;
    });
  }

  Future<void> _loadGoals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final goals = await ApiService.fetchGoals(_userId);
      setState(() {
        _goals = goals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('목표를 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  void _navigateToGoalForm([Goal? goal]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoalFormScreen(goal: goal),
      ),
    );

    if (result == true) {
      _loadGoals();
    }
  }

  void _navigateToGoalDetail(Goal goal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoalDetailScreen(goal: goal),
      ),
    ).then((_) => _loadGoals());
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
          '목표',
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
          : _goals.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadGoals,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _goals.length,
                    itemBuilder: (context, index) {
                      return _buildGoalCard(_goals[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToGoalForm(),
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flag_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '목표가 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '+ 버튼을 눌러 첫 목표를 추가해보세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Goal goal) {
    final progressPercentage = goal.progressPercentage;
    final isCompleted = goal.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCompleted
            ? Border.all(color: const Color(0xFF20C997), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToGoalDetail(goal),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더: 제목 + 완료 뱃지
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF20C997).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Color(0xFF20C997),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '완료',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF20C997),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // 진행도 텍스트
                Row(
                  children: [
                    Text(
                      '${goal.currentProgress}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    Text(
                      ' / ${goal.totalTargetAmount} ${goal.targetUnit}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${progressPercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 진행률 바
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressPercentage / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted
                          ? const Color(0xFF20C997)
                          : const Color(0xFF6366F1),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 기간 정보
                if (goal.startDate != null || goal.endDate != null)
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDateRange(goal.startDate, goal.endDate),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '';
    if (start != null && end != null) {
      return '${_formatDate(start)} ~ ${_formatDate(end)}';
    } else if (start != null) {
      return '${_formatDate(start)} ~';
    } else {
      return '~ ${_formatDate(end!)}';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
