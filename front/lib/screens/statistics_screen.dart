import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/weekly_stats.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/logger_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _userId = 1;
  bool _isLoading = true;
  WeeklyStats? _stats;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    final authService = await AuthService.getInstance();
    setState(() {
      _userId = authService.currentUserId;
    });
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 기준선 생성 시도 (이번 주 첫 접속일 경우를 대비)
      await ApiService.createWeeklyBaseline(_userId);
      
      final stats = await ApiService.fetchWeeklyStats(_userId);
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      Log.d('통계 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('학습 통계', style: AppTextStyles.heading2),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _stats == null
              ? ErrorView(
                  message: '통계 데이터를 불러올 수 없습니다',
                  onRetry: _loadStats,
                )
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDateHeader(),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildSummaryCards(),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildWordBookStats(),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildGoalStats(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildDateHeader() {
    if (_stats == null) return const SizedBox();
    final info = _stats!.weekInfo;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${info.year}년 ${info.month}월 ${info.weekNumber}주차',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF191F28),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '이번 주 학습 현황입니다 🔥',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    if (_stats == null) return const SizedBox();
    final time = _stats!.studyTime;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.timer,
            iconColor: const Color(0xFF6366F1),
            label: '총 학습 시간',
            value: _formatDuration(time.totalMinutes),
            subValue: '',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department,
            iconColor: const Color(0xFFFF6B6B),
            label: '포모도로',
            value: '${(time.pomodoroMinutes / 25).floor()}회', // 대략적인 횟수 추정
            subValue: '',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String subValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF191F28),
            ),
          ),
          if (subValue.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subValue,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWordBookStats() {
    if (_stats == null) return const SizedBox();
    final improvement = _stats!.cardImprovement;
    final changes = improvement.changes;
    final current = improvement.current;
    final start = improvement.weekStart;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '단어장 학습 현황',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191F28),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '학습 시간: ${_formatDuration(_stats!.studyTime.wordBookMinutes)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // 난이도 변화 그래프
          Row(
            children: [
              _buildDifficultyColumn('어려움', Colors.red.shade400, start.hard, current.hard, changes.hard),
              const SizedBox(width: 16),
              _buildDifficultyColumn('보통', Colors.orange.shade400, start.normal, current.normal, changes.normal),
              const SizedBox(width: 16),
              _buildDifficultyColumn('쉬움', Colors.green.shade400, start.easy, current.easy, changes.easy),
            ],
          ),
          
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          
          // 긍정적 변화 메시지
          if (changes.hard < 0 || changes.easy > 0)
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getImprovementMessage(changes),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              '꾸준히 학습하여 단어를 마스터해보세요!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }

  String _getImprovementMessage(DifficultyChange changes) {
    List<String> parts = [];
    if (changes.hard < 0) parts.add('어려운 단어 ${changes.hard.abs()}개 정복');
    if (changes.easy > 0) parts.add('쉬운 단어 ${changes.easy}개 증가');
    
    if (parts.isEmpty) return '학습을 통해 단어 실력을 향상시켜보세요!';
    return '${parts.join(', ')}! 훌륭해요 👏';
  }

  Widget _buildDifficultyColumn(String label, Color color, int start, int current, int change) {
    // 최대값 기준으로 높이 비율 계산 (최소 10)
    int maxVal = [start, current, 10].reduce((curr, next) => curr > next ? curr : next);
    
    return Expanded(
      child: Column(
        children: [
          // 그래프 바
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 시작 시점 (회색)
              _buildBar(start, maxVal, Colors.grey.shade300),
              const SizedBox(width: 4),
              // 현재 시점 (컬러)
              _buildBar(current, maxVal, color),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$current',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (change != 0) ...[
                const SizedBox(width: 4),
                Text(
                  change > 0 ? '+$change' : '$change',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: change > 0 
                        ? (label == '어려움' ? Colors.red : Colors.green) 
                        : (label == '어려움' ? Colors.green : Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(int value, int max, Color color) {
    // 높이 계산 (최대 80px)
    double height = (value / max) * 80;
    if (height < 4 && value > 0) height = 4;
    
    return Container(
      width: 16,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
    );
  }

  Widget _buildGoalStats() {
    if (_stats == null || _stats!.goalProgress.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '목표별 학습 현황',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF191F28),
          ),
        ),
        const SizedBox(height: 16),
        ..._stats!.goalProgress.map((goal) => _buildGoalCard(goal)),
      ],
    );
  }

  Widget _buildGoalCard(GoalProgress goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.flag, color: Color(0xFF6366F1), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.goalTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF191F28),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '이번 주: +${goal.change} ${goal.unit}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${goal.currentAmount} ${goal.unit}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191F28),
                ),
              ),
              Text(
                '누적 달성',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes분';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hours시간';
    return '$hours시간 $mins분';
  }
}
