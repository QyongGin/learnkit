import 'dart:async';
import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../models/study_session.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

/// 포모도로 타이머 상태
enum PomodoroState {
  focus,      // 25분 집중
  shortBreak, // 5분 휴식
  longBreak,  // 30분 장휴식
}

/// 포모도로 타이머 화면
class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  int _userId = 1;
  List<Goal> _goals = [];
  Goal? _selectedGoal;
  bool _isLoadingGoals = true;

  // 포모도로 상태
  PomodoroState _pomodoroState = PomodoroState.focus;
  int _completedSets = 0; // 완료한 세트 수 (1세트 = 25분 집중)
  int _totalPomodoros = 0; // 총 완료한 포모도로 횟수

  // 타이머
  Timer? _timer;
  int _remainingSeconds = 25 * 60; // 기본 25분
  bool _isRunning = false;

  // 세션
  StudySession? _currentSession;
  DateTime? _sessionStartTime;

  @override
  void initState() {
    super.initState();
    _initAuth();
    _loadGoals();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initAuth() async {
    final authService = await AuthService.getInstance();
    setState(() {
      _userId = authService.currentUserId;
    });
  }

  Future<void> _loadGoals() async {
    setState(() {
      _isLoadingGoals = true;
    });

    try {
      final goals = await ApiService.fetchActiveGoals(_userId);
      setState(() {
        _goals = goals;
        _isLoadingGoals = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingGoals = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('목표를 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  /// 타이머 시작
  void _startTimer() async {
    // 첫 시작 시 세션 생성
    if (_currentSession == null) {
      try {
        final session = await ApiService.startPomodoroSession(
          userId: _userId,
          goalId: _selectedGoal?.id,
        );
        setState(() {
          _currentSession = session;
          _sessionStartTime = DateTime.now();
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('세션 시작 실패: $e')),
          );
        }
        return;
      }
    }

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        // 타이머 완료
        _onTimerComplete();
      }
    });
  }

  /// 타이머 일시정지
  void _pauseTimer() {
    setState(() {
      _isRunning = false;
    });
    _timer?.cancel();
  }

  /// 타이머 완료 시 처리
  void _onTimerComplete() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });

    if (_pomodoroState == PomodoroState.focus) {
      // 집중 세션 완료
      setState(() {
        _completedSets++;
        _totalPomodoros++;
      });

      // 4세트 완료 시 장휴식, 아니면 짧은 휴식
      if (_completedSets % 4 == 0) {
        _showBreakDialog('장휴식 시간입니다!', '30분 동안 푹 쉬세요 😊', PomodoroState.longBreak);
      } else {
        _showBreakDialog('잠깐 쉬어가세요!', '5분 휴식', PomodoroState.shortBreak);
      }
    } else {
      // 휴식 완료
      _showNextFocusDialog();
    }
  }

  /// 휴식 시작 다이얼로그
  void _showBreakDialog(String title, String message, PomodoroState breakState) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 12),
            Text(
              '완료한 세트: $_completedSets개',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _endSession();
            },
            child: const Text('학습 종료'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startBreak(breakState);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text('휴식 시작', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// 다음 집중 세션 다이얼로그
  void _showNextFocusDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('휴식 완료!', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('다음 집중 세션을 시작하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _endSession();
            },
            child: const Text('학습 종료'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _pomodoroState = PomodoroState.focus;
                _remainingSeconds = 25 * 60;
              });
              _startTimer();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text('집중 시작', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// 휴식 시작
  void _startBreak(PomodoroState breakState) {
    setState(() {
      _pomodoroState = breakState;
      _remainingSeconds = breakState == PomodoroState.longBreak ? 30 * 60 : 5 * 60;
    });
    _startTimer();
  }

  /// 세션 종료
  void _endSession() async {
    if (_currentSession == null) {
      Navigator.pop(context);
      return;
    }

    // 달성량 입력 다이얼로그
    _showAchievementDialog();
  }

  /// 달성량 입력 다이얼로그
  void _showAchievementDialog() {
    final achievementController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('학습 완료!', style: TextStyle(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '완료한 포모도로: $_totalPomodoros세트',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '학습 시간: ${_calculateDuration()}분',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 20),

              if (_selectedGoal != null) ...[
                Text(
                  '달성량 (${_selectedGoal!.targetUnit})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: achievementController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '예: 30',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixText: _selectedGoal!.targetUnit,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const Text(
                '메모 (선택사항)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '학습 내용을 기록하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final achievement = int.tryParse(achievementController.text) ?? 0;
              await _completeSession(achievement, noteController.text);
              if (mounted) {
                Navigator.pop(context); // 다이얼로그 닫기
                Navigator.pop(context); // 타이머 화면 닫기
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text('완료', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// 세션 완료 처리
  Future<void> _completeSession(int achievement, String note) async {
    if (_currentSession == null) return;

    try {
      final duration = _calculateDuration();

      await ApiService.endPomodoroSession(
        sessionId: _currentSession!.id,
        achievedAmount: achievement,
        durationMinutes: duration,
        pomoCount: _totalPomodoros,
        note: note.isEmpty ? null : note,
      );

      // 목표에 달성량 추가
      if (_selectedGoal != null && achievement > 0) {
        await ApiService.addGoalProgress(
          goalId: _selectedGoal!.id,
          amount: achievement,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('학습이 기록되었습니다!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('세션 종료 실패: $e')),
      );
    }
  }

  /// 학습 시간 계산 (분)
  int _calculateDuration() {
    if (_sessionStartTime == null) return 0;
    final duration = DateTime.now().difference(_sessionStartTime!);
    return duration.inMinutes;
  }

  /// 시간 포맷팅 (MM:SS)
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// 전체 시간 (초)
  int _getTotalSeconds() {
    switch (_pomodoroState) {
      case PomodoroState.focus:
        return 25 * 60;
      case PomodoroState.shortBreak:
        return 5 * 60;
      case PomodoroState.longBreak:
        return 30 * 60;
    }
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
          '포모도로 타이머',
          style: TextStyle(
            color: Color(0xFF191F28),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          if (_currentSession != null)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
              onPressed: _endSession,
              tooltip: '학습 종료',
            ),
        ],
      ),
      body: _isLoadingGoals
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 목표 선택
                  _buildGoalSelector(),
                  const SizedBox(height: 32),

                  // 타이머
                  _buildTimer(),
                  const SizedBox(height: 32),

                  // 세트 정보
                  _buildSessionInfo(),
                  const SizedBox(height: 32),

                  // 시작/정지 버튼
                  _buildControlButton(),
                ],
              ),
            ),
    );
  }

  /// 목표 선택기
  Widget _buildGoalSelector() {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '학습 목표 선택',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF191F28),
            ),
          ),
          const SizedBox(height: 12),

          if (_goals.isEmpty)
            Text(
              '진행 중인 목표가 없습니다',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            )
          else
            DropdownButtonFormField<Goal>(
              initialValue: _selectedGoal,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              hint: const Text('목표를 선택하세요'),
              items: _goals.map((goal) {
                return DropdownMenuItem<Goal>(
                  value: goal,
                  child: Text(
                    '${goal.title} (${goal.currentProgress}/${goal.totalTargetAmount} ${goal.targetUnit})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: _isRunning
                  ? null
                  : (goal) {
                      setState(() {
                        _selectedGoal = goal;
                      });
                    },
            ),
        ],
      ),
    );
  }

  /// 타이머 위젯
  Widget _buildTimer() {
    final progress = 1 - (_remainingSeconds / _getTotalSeconds());
    final color = _pomodoroState == PomodoroState.focus
        ? const Color(0xFF6366F1)
        : const Color(0xFF20C997);

    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 진행률 원
          SizedBox(
            width: 240,
            height: 240,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),

          // 시간 표시
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatTime(_remainingSeconds),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _pomodoroState == PomodoroState.focus
                    ? '집중 시간'
                    : _pomodoroState == PomodoroState.shortBreak
                        ? '짧은 휴식'
                        : '장휴식',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 세션 정보
  Widget _buildSessionInfo() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            label: '완료 세트',
            value: '$_completedSets',
            color: const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            label: '총 포모도로',
            value: '$_totalPomodoros',
            color: const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// 시작/정지 버튼
  Widget _buildControlButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isRunning
              ? [Colors.orange.shade400, Colors.orange.shade600]
              : [const Color(0xFF4F46E5), const Color(0xFF6366F1)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isRunning ? Colors.orange : const Color(0xFF6366F1))
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isRunning ? _pauseTimer : _startTimer,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isRunning ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  _isRunning ? '일시정지' : '시작',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
