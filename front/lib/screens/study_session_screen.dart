// dart:async - 비동기 프로그래밍 (Timer, Future 등)
import 'dart:async';
// dart:math - 수학 함수 (Random, min, max 등)
import 'dart:math';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/card.dart' as model;
import '../models/wordbook.dart';
import '../services/api_service.dart';
import '../services/logger_service.dart';

/// Anki 스타일 학습 세션 화면 (토스 디자인)
class StudySessionScreen extends StatefulWidget {
  final WordBook wordBook;
  final int? existingSessionId; // 이어하기용 기존 세션 ID

  const StudySessionScreen({
    super.key,
    required this.wordBook,
    this.existingSessionId,
  });

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isFlipped = false; // 카드 뒤집힘 상태
  model.Card? _currentCard;
  SessionStartResponse? _sessionInfo;
  int? _sessionId; // 실제 백엔드 세션 ID
  int _reviewedCount = 0;
  final int _userId = 1; // 기본 사용자 ID

  // 학습 시작 전 통계 (before)
  int _beforeEasyCount = 0;
  int _beforeNormalCount = 0;
  int _beforeHardCount = 0;

  // 학습 타이머
  late DateTime _sessionStartTime;
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;

  // 플립 애니메이션 컨트롤러
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _startSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flipController.dispose();
    super.dispose();
  }

  /// 타이머 시작
  void _startTimer() {
    _sessionStartTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_sessionStartTime);
        });
      }
    });
  }

  /// 플립 애니메이션 초기화
  void _initAnimation() {
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  /// 학습 세션 시작
  Future<void> _startSession() async {
    try {
      setState(() => _isLoading = true);

      // 학습 시작 전 통계 저장 (before)
      final beforeStats = await ApiService.fetchWordBookStatistics(widget.wordBook.id);
      _beforeEasyCount = beforeStats.easyCount;
      _beforeNormalCount = beforeStats.normalCount;
      _beforeHardCount = beforeStats.hardCount;

      // 기존 세션이 있으면 이어하기, 없으면 새로 시작
      if (widget.existingSessionId != null) {
        // 이어하기: 기존 세션 ID 사용
        Log.d('🔄 기존 세션 이어하기: sessionId=${widget.existingSessionId}');
        _sessionId = widget.existingSessionId;
        
        // 통계 정보는 현재 상태로 설정
        _sessionInfo = SessionStartResponse(
          totalCards: beforeStats.totalCount,
          easyCount: beforeStats.easyCount,
          normalCount: beforeStats.normalCount,
          hardCount: beforeStats.hardCount,
        );
      } else {
        // 새로 시작: 단어장 학습 세션 API 호출
        Log.d('🎯 새 세션 시작: wordBookId=${widget.wordBook.id}');
        final session = await ApiService.startWordBookSession(
          userId: _userId,
          wordBookId: widget.wordBook.id,
          initialHardCount: beforeStats.hardCount,
          initialNormalCount: beforeStats.normalCount,
          initialEasyCount: beforeStats.easyCount,
        );
        
        _sessionId = session.id;
        
        Log.d('✅ 세션 생성 완료: sessionId=$_sessionId');
        
        // 통계 정보 설정
        _sessionInfo = SessionStartResponse(
          totalCards: beforeStats.totalCount,
          easyCount: beforeStats.easyCount,
          normalCount: beforeStats.normalCount,
          hardCount: beforeStats.hardCount,
        );
      }

      // 첫 번째(또는 다음) 카드 로드
      final firstCard = await ApiService.getNextCard(widget.wordBook.id);

      if (mounted) {
        setState(() {
          _currentCard = firstCard;
          _isLoading = false;
          _isFlipped = false;
        });

        // 타이머 시작
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('세션 시작 실패', e.toString());
      }
    }
  }

  /// 카드 뒤집기
  void _flipCard() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  /// 난이도 선택 및 다음 카드 로드
  Future<void> _selectDifficulty(model.CardDifficulty difficulty) async {
    if (_currentCard == null) return;

    try {
      // 복습 완료 API 호출
      await ApiService.reviewCard(
        cardId: _currentCard!.id,
        difficulty: difficulty,
      );

      setState(() => _reviewedCount++);

      // 다음 카드 로드
      final nextCard = await ApiService.getNextCard(widget.wordBook.id);

      if (nextCard == null) {
        // 모든 카드 복습 완료
        _showCompletionDialog();
      } else {
        // 플립 애니메이션 리셋 후 다음 카드 표시
        _flipController.reset();
        setState(() {
          _currentCard = nextCard;
          _isFlipped = false;
        });
      }
    } catch (e) {
      _showErrorDialog('카드 저장 실패', e.toString());
    }
  }

  /// 학습 완료 다이얼로그
  Future<void> _showCompletionDialog() async {
    // 세션 종료 처리
    await _endSession();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 학습 완료!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '총 $_reviewedCount개의 카드를 복습했어요',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              '훌륭해요! 꾸준히 복습하면\n더 오래 기억할 수 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 다이얼로그 닫기
              Navigator.pop(context); // 학습 화면 닫기
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 세션 종료 처리
  Future<void> _endSession() async {
    if (_sessionId == null) return;

    try {
      _timer?.cancel();

      // 학습 후 통계 가져오기
      final afterStats = await ApiService.fetchWordBookStatistics(widget.wordBook.id);

      Log.d('✅ 세션 종료 시작: sessionId=$_sessionId');
      Log.d('난이도 변화: HARD $_beforeHardCount→${afterStats.hardCount}, '
            'NORMAL $_beforeNormalCount→${afterStats.normalCount}, '
            'EASY $_beforeEasyCount→${afterStats.easyCount}');

      // 세션 종료 API 호출 (백엔드에서 시간 자동 계산)
      await ApiService.endWordBookSession(
        sessionId: _sessionId!,
        hardCount: afterStats.hardCount,
        normalCount: afterStats.normalCount,
        easyCount: afterStats.easyCount,
      );

      Log.d('✅ 세션 종료 완료');
    } catch (e) {
      Log.d('❌ 세션 종료 실패: $e');
    }
  }

  /// Duration을 "MM:SS" 형식으로 변환
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// 종료 다이얼로그 (before/after 통계 표시)
  Future<void> _showExitDialog() async {
    // 타이머 정지
    _timer?.cancel();

    // 현재 통계 가져오기 (after)
    final afterStats = await ApiService.fetchWordBookStatistics(widget.wordBook.id);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '학습 완료!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF191F28),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 세션 정보
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Icon(Icons.timer, color: Colors.blue.shade700, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        _formatDuration(_elapsedTime),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('학습 시간', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(Icons.credit_card, color: Colors.green.shade700, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        '$_reviewedCount개',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('복습한 카드', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Before/After 통계
            const Text(
              '난이도별 변화',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildStatChange('쉬움', _beforeEasyCount, afterStats.easyCount, const Color(0xFF20C997)),
            const SizedBox(height: 8),
            _buildStatChange('보통', _beforeNormalCount, afterStats.normalCount, const Color(0xFF3182F6)),
            const SizedBox(height: 8),
            _buildStatChange('어려움', _beforeHardCount, afterStats.hardCount, const Color(0xFFEF4444)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // 세션 종료 처리
              await _endSession();
              
              if (mounted) {
                Navigator.pop(context); // 다이얼로그 닫기
                Navigator.pop(context); // 학습 화면 닫기
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 난이도별 Before/After 위젯
  Widget _buildStatChange(String label, int before, int after, Color color) {
    final change = after - before;
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        Text('$before', style: TextStyle(fontSize: 15, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Icon(Icons.arrow_forward, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Text('$after', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(width: 8),
        SizedBox(
          width: 50,
          child: Text(
            change > 0 ? '(+$change)' : change < 0 ? '($change)' : '(+0)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: change > 0 ? const Color(0xFF10B981) : change < 0 ? const Color(0xFFEF4444) : Colors.grey.shade500,
            ),
          ),
        ),
      ],
    );
  }

  /// 에러 다이얼로그
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _showExitDialog();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(Icons.timer_outlined, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              _formatDuration(_elapsedTime),
              style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(width: AppSpacing.lg),
            Icon(Icons.credit_card, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '복습한 카드 $_reviewedCount개',
              style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _showExitDialog,
            icon: const Icon(Icons.stop_circle_outlined, size: 20),
            label: const Text('종료'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
          ),
          const SizedBox(width: 8),
        ],
      ),
        body: _isLoading
            ? const LoadingIndicator()
            : _currentCard == null
                ? const EmptyState(
                    icon: Icons.library_books,
                    title: '카드가 없습니다',
                    subtitle: '단어장에 카드를 추가해주세요',
                  )
                : _buildStudyContent(),
      ),
    );
  }

  Widget _buildStudyContent() {
    return Column(
      children: [
        _buildProgressBar(),
        const SizedBox(height: AppSpacing.xxl),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: _buildFlipCard(),
          ),
        ),
        _buildActionButtons(),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }

  /// 진행률 바
  Widget _buildProgressBar() {
    final progress = _sessionInfo != null
        ? _reviewedCount / _sessionInfo!.totalCards
        : 0.0;

    return Container(
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.divider,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  /// 플립 카드 위젯
  Widget _buildFlipCard() {
    return GestureDetector(
      onTap: _isFlipped ? null : _flipCard,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          // 회전 각도 계산
          final angle = _flipAnimation.value * pi;
          final isBack = angle > pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // 원근감
              ..rotateY(angle),
            child: isBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _buildCardBack(),
                  )
                : _buildCardFront(),
          );
        },
      ),
    );
  }

  /// 카드 앞면
  Widget _buildCardFront() {
    return FlashCard(
      label: '질문',
      content: _currentCard!.frontText,
      labelBgColor: const Color(0xFFF9FAFB),
      labelTextColor: const Color(0xFF6B7280),
      hintText: '답을 확인하려면 탭하세요',
      hintIcon: Icons.touch_app,
    );
  }

  /// 카드 뒷면
  Widget _buildCardBack() {
    return FlashCard(
      label: '정답',
      content: _currentCard!.backText,
      labelBgColor: const Color(0xFFF0F9FF),
      labelTextColor: const Color(0xFF0284C7),
      hintText: '아래에서 난이도를 선택하세요',
    );
  }

  /// 하단 액션 버튼들
  Widget _buildActionButtons() {
    if (!_isFlipped) {
      // 앞면일 때는 뒤집기 버튼만 표시
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _flipCard,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              '답 확인하기',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    // 뒷면일 때는 난이도 선택 버튼들 표시
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Text(
            '얼마나 잘 기억하셨나요?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DifficultyButton(
                  label: '어려움',
                  color: const Color(0xFFEF4444),
                  icon: Icons.close,
                  onPressed: () => _selectDifficulty(model.CardDifficulty.HARD),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DifficultyButton(
                  label: '보통',
                  color: const Color(0xFFF59E0B),
                  icon: Icons.remove,
                  onPressed: () => _selectDifficulty(model.CardDifficulty.NORMAL),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DifficultyButton(
                  label: '쉬움',
                  color: const Color(0xFF10B981),
                  icon: Icons.check,
                  onPressed: () => _selectDifficulty(model.CardDifficulty.EASY),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

