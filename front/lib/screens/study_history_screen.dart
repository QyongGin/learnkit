import 'package:flutter/material.dart';
// intl: 날짜/시간 포맷팅 (DateFormat)
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/study_session.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

/// 학습 기록 화면 (롤 전적 스타일)
class StudyHistoryScreen extends StatefulWidget {
  const StudyHistoryScreen({super.key});

  @override
  State<StudyHistoryScreen> createState() => _StudyHistoryScreenState();
}

class _StudyHistoryScreenState extends State<StudyHistoryScreen> {
  List<StudySession> _sessions = [];
  bool _isLoading = true;
  int _userId = 1;

  @override
  void initState() {
    super.initState();
    _initAuth();
    _loadSessions();
  }

  Future<void> _initAuth() async {
    final authService = await AuthService.getInstance();
    setState(() {
      _userId = authService.currentUserId;
    });
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sessions = await ApiService.fetchUserSessions(_userId);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('학습 기록', style: AppTextStyles.heading2),
        centerTitle: false,
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _sessions.isEmpty
              ? const EmptyState(
                  icon: Icons.history_outlined,
                  title: '학습 기록이 없습니다',
                  subtitle: '포모도로 타이머로 학습을 시작해보세요',
                )
              : RefreshIndicator(
                  onRefresh: _loadSessions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      return _buildSessionCard(_sessions[index]);
                    },
                  ),
                ),
    );
  }

  /// 학습 세션 카드 (롤 전적 스타일)
  Widget _buildSessionCard(StudySession session) {
    final date = DateFormat('yyyy.MM.dd').format(session.startedAt);
    final time = DateFormat('HH:mm').format(session.startedAt);
    final isToday = DateFormat('yyyy.MM.dd').format(DateTime.now()) == date;
    final isWordBook = session.type == 'WORDBOOK';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isToday
            ? Border.all(color: const Color(0xFF6366F1), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 날짜 + 목표/단어장
            Row(
              children: [
                // 날짜 뱃지
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFF6366F1).withValues(alpha: 0.1)
                        : const Color(0xFFF1F3F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: isToday
                            ? const Color(0xFF6366F1)
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isToday ? '오늘 $time' : '$date $time',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isToday
                              ? const Color(0xFF6366F1)
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // 목표/단어장 뱃지
                if (isWordBook && session.wordBookTitle != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90E2).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.book,
                          size: 14,
                          color: Color(0xFF4A90E2),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          session.wordBookTitle!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A90E2),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  )
                else if (!isWordBook && session.goalTitle != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.flag,
                          size: 14,
                          color: Color(0xFF8B5CF6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          session.goalTitle!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8B5CF6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // 학습 통계
            if (isWordBook) ...[
              // 학습 시간 (단독 표시)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined, color: Color(0xFF6366F1), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '학습 시간: ${session.durationMinutes}분',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // 난이도 변화
              if (session.startHardCount != null && session.endHardCount != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.trending_up, size: 18, color: Color(0xFF4A90E2)),
                          const SizedBox(width: 8),
                          const Text(
                            '난이도 변화',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF191F28),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDifficultyChange(
                            '어려움',
                            session.startHardCount!,
                            session.endHardCount!,
                            Colors.red.shade400,
                          ),
                          _buildDifficultyChange(
                            '보통',
                            session.startNormalCount!,
                            session.endNormalCount!,
                            Colors.orange.shade400,
                          ),
                          _buildDifficultyChange(
                            '쉬움',
                            session.startEasyCount!,
                            session.endEasyCount!,
                            Colors.green.shade400,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ]
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.timer_outlined,
                        label: '학습 시간',
                        value: '${session.durationMinutes}분',
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade300,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.local_fire_department_outlined,
                        label: '포모도로',
                        value: '${session.pomoCount}세트',
                        color: const Color(0xFFFF6B6B),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade300,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.check_circle_outline,
                        label: '달성량',
                        value: '${session.achievedAmount}',
                        color: const Color(0xFF20C997),
                      ),
                    ),
                  ],
                ),
              ),

            // 메모
            if (session.note != null && session.note!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        session.note!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyChange(String label, int start, int end, Color color) {
    final change = end - start;
    final changeText = change > 0 ? '+$change' : change < 0 ? '$change' : '±0';
    final isImprovement = (label == '어려움' && change < 0) || (label == '쉬움' && change > 0);
    
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$start',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              '$end',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isImprovement 
                ? Colors.green.shade50 
                : change == 0 
                    ? Colors.grey.shade100 
                    : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            changeText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isImprovement 
                  ? Colors.green.shade700 
                  : change == 0 
                      ? Colors.grey.shade600 
                      : Colors.orange.shade700,
            ),
          ),
        ),
      ],
    );
  }
}


