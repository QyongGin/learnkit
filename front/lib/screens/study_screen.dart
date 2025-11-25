import 'package:flutter/material.dart';
import '../models/wordbook.dart';
import '../models/card.dart' as model;
import '../services/api_service.dart';
import '../services/auth_service.dart';

/// 학습 화면
/// 카드의 앞면(질문)과 뒷면(답+난이도 선택)을 보여주는 화면
class StudyScreen extends StatefulWidget {
  final WordBook wordBook;
  final List<model.CardDetail> cards;

  const StudyScreen({
    super.key,
    required this.wordBook,
    required this.cards,
  });

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  int _currentIndex = 0;
  bool _showAnswer = false; // 앞면(false) vs 뒷면(true)
  final TextEditingController _answerController = TextEditingController();
  
  // 세션 관련
  int? _sessionId;
  DateTime? _startTime;
  int _easyCount = 0;
  int _normalCount = 0;
  int _hardCount = 0;
  Future<void>? _sessionStartFuture;

  @override
  void initState() {
    super.initState();
    _sessionStartFuture = _startSession();
  }

  Future<void> _startSession() async {
    try {
      print('학습 세션 시작 요청...');
      final authService = await AuthService.getInstance();
      final userId = authService.currentUserId;
      
      // 현재 카드들의 난이도 분포 계산
      int initialHard = 0;
      int initialNormal = 0;
      int initialEasy = 0;
      
      for (var card in widget.cards) {
        if (card.difficulty == model.CardDifficulty.HARD) {
          initialHard++;
        } else if (card.difficulty == model.CardDifficulty.NORMAL) {
          initialNormal++;
        } else if (card.difficulty == model.CardDifficulty.EASY) {
          initialEasy++;
        }
      }
      
      print('초기 난이도 분포 - 어려움: $initialHard, 보통: $initialNormal, 쉬움: $initialEasy');
      
      final session = await ApiService.startWordBookSession(
        userId: userId,
        wordBookId: widget.wordBook.id,
        initialHardCount: initialHard,
        initialNormalCount: initialNormal,
        initialEasyCount: initialEasy,
      );
      
      setState(() {
        _sessionId = session.id;
        _startTime = DateTime.now();
      });
      print('학습 세션 시작 성공: ID=${session.id}');
    } catch (e) {
      print('세션 시작 실패: $e');
    }
  }

  Future<void> _endSession() async {
    print('학습 세션 종료 시도...');
    
    // 세션 시작이 완료될 때까지 대기
    if (_sessionStartFuture != null) {
      await _sessionStartFuture;
    }

    if (_sessionId == null || _startTime == null) {
      print('세션 ID 또는 시작 시간이 없어 종료할 수 없습니다.');
      return;
    }

    try {
      // 최종 난이도 분포 계산
      // 백엔드는 "전체 카드의 현재 난이도 분포"를 기대하므로 API에서 다시 조회
      final cards = await ApiService.fetchCards(widget.wordBook.id);
      
      int finalHard = 0;
      int finalNormal = 0;
      int finalEasy = 0;
      
      for (var card in cards) {
        if (card.difficulty == model.CardDifficulty.HARD) {
          finalHard++;
        } else if (card.difficulty == model.CardDifficulty.NORMAL) {
          finalNormal++;
        } else if (card.difficulty == model.CardDifficulty.EASY) {
          finalEasy++;
        }
      }

      print('학습 세션 종료 요청');
      print('최종 난이도 분포 - 어려움: $finalHard, 보통: $finalNormal, 쉬움: $finalEasy');

      final result = await ApiService.endWordBookSession(
        sessionId: _sessionId!,
        hardCount: finalHard,
        normalCount: finalNormal,
        easyCount: finalEasy,
      );
      print('✅ 학습 세션 종료 성공: ID=${result.id}');
      
      // 세션 ID 초기화하여 중복 종료 방지
      _sessionId = null;
      _startTime = null;
    } catch (e, stackTrace) {
      print('❌ 세션 종료 실패: $e');
      print('Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    // 화면을 나갈 때도 세션 종료 시도 (비동기로 실행하되 대기하지 않음)
    if (_sessionId != null && _startTime != null) {
      _endSession().catchError((e) {
        print('dispose에서 세션 종료 실패: $e');
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= widget.cards.length) {
      return _buildCompletionScreen();
    }

    final currentCard = widget.cards[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('${widget.wordBook.title} 학습'),
        backgroundColor: const Color(0xFF4A90E2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_currentIndex + 1}/${widget.cards.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _showAnswer
          ? _buildBackSide(currentCard)
          : _buildFrontSide(currentCard),
    );
  }

  /// 앞면: 질문 + 답변 입력란
  Widget _buildFrontSide(model.CardDetail card) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 진행도 바
            _buildProgressBar(),
            const SizedBox(height: 24),

            // 질문 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "질문" 라벨
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90E2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '질문',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A90E2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 질문 텍스트
                  Text(
                    card.frontText,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 답변 입력 영역
            const Text(
              '답변을 입력하세요',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _answerController,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: '여기에 답변을 작성해보세요...',
                  hintStyle: TextStyle(color: Colors.black38),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(20),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 완료 버튼
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showAnswer = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                '완료',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 뒷면: 정답 + 난이도 선택
  Widget _buildBackSide(model.CardDetail card) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 진행도 바
            _buildProgressBar(),
            const SizedBox(height: 24),

            // 질문 카드 (축소 버전)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '질문',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A90E2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    card.frontText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 정답 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "정답" 라벨
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '정답',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 정답 텍스트
                  Text(
                    card.backText,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 내 답변 (입력한 내용)
            if (_answerController.text.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9E6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '내 답변',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF57C00),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _answerController.text,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 난이도 선택 섹션
            const Text(
              '이 카드의 난이도를 선택하세요',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // 난이도 버튼들
            _buildDifficultyButton(
              '쉬움 😊',
              '${widget.wordBook.easyFrequencyRatio}배',
              const Color(0xFF4CAF50),
              model.CardDifficulty.EASY,
            ),
            const SizedBox(height: 12),

            _buildDifficultyButton(
              '보통 😐',
              '${widget.wordBook.normalFrequencyRatio}배',
              const Color(0xFF4A90E2),
              model.CardDifficulty.NORMAL,
            ),
            const SizedBox(height: 12),

            _buildDifficultyButton(
              '어려움 😰',
              '${widget.wordBook.hardFrequencyRatio}배',
              const Color(0xFF9C27B0),
              model.CardDifficulty.HARD,
            ),
          ],
        ),
      ),
    );
  }

  /// 진행도 바
  Widget _buildProgressBar() {
    final progress = (_currentIndex + 1) / widget.cards.length;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '진행 상황',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A90E2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
          ),
        ),
      ],
    );
  }

  /// 난이도 선택 버튼
  Widget _buildDifficultyButton(
    String title,
    String subtitle,
    Color color,
    model.CardDifficulty difficulty,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectDifficulty(difficulty),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    title.split(' ').last, // 이모지만 추출
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.split(' ').first, // "쉬움", "보통", "어려움"
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 난이도 선택 처리
  void _selectDifficulty(model.CardDifficulty difficulty) async {
    // 난이도별 카운트 증가
    if (difficulty == model.CardDifficulty.EASY) {
      _easyCount++;
      print('✅ 쉬움 선택 (총 $_easyCount)');
    } else if (difficulty == model.CardDifficulty.NORMAL) {
      _normalCount++;
      print('✅ 보통 선택 (총 $_normalCount)');
    } else if (difficulty == model.CardDifficulty.HARD) {
      _hardCount++;
      print('✅ 어려움 선택 (총 $_hardCount)');
    }

    // API 호출 (난이도 업데이트)
    try {
      await ApiService.reviewCard(
        cardId: widget.cards[_currentIndex].id,
        difficulty: difficulty,
      );
    } catch (e) {
      print('난이도 업데이트 실패: $e');
      // 실패해도 학습은 계속 진행
    }

    // 다음 카드로 이동
    setState(() {
      _currentIndex++;
      _showAnswer = false;
      _answerController.clear();
    });

    // 모든 카드를 학습했으면 세션 종료
    if (_currentIndex >= widget.cards.length) {
      print('🎯 모든 카드 학습 완료! 세션 종료 시작...');
      print('최종 카운트 - 쉬움: $_easyCount, 보통: $_normalCount, 어려움: $_hardCount');
      await _endSession();
    }

    // 스낵바로 피드백
    final difficultyLabel = difficulty == model.CardDifficulty.EASY
        ? '쉬움'
        : difficulty == model.CardDifficulty.NORMAL
            ? '보통'
            : '어려움';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('난이도: $difficultyLabel - 다음 카드로 이동합니다'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 완료 화면
  Widget _buildCompletionScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF4A90E2),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 완료 아이콘
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF4CAF50),
                    size: 80,
                  ),
                ),
                const SizedBox(height: 32),

                // 축하 메시지
                const Text(
                  '학습 완료!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  '${widget.cards.length}개의 카드를 모두 학습했습니다',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // 버튼들
                ElevatedButton(
                  onPressed: () async {
                    // 세션 종료를 기다렸다가 화면 닫기
                    if (_sessionId != null && _startTime != null) {
                      await _endSession();
                    }
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4A90E2),
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '단어장으로 돌아가기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentIndex = 0;
                      _showAnswer = false;
                      _answerController.clear();
                      // 카운트 초기화
                      _easyCount = 0;
                      _normalCount = 0;
                      _hardCount = 0;
                    });
                    // 새 세션 시작
                    _startSession();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '다시 학습하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
