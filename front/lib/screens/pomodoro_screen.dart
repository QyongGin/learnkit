// Dart 비동기 처리 (Timer 사용)
import 'dart:async';
// Flutter 기본 위젯
import 'package:flutter/material.dart';
// 가속도계 센서 (폰 뒤집기 감지)
import 'package:sensors_plus/sensors_plus.dart';
// 진동 기능
import 'package:vibration/vibration.dart';
// Provider 패턴 (설정 상태 관리)
import 'package:provider/provider.dart';
// 데이터 모델
import '../models/goal.dart';
import '../models/study_session.dart';
// API 통신 및 인증
import '../services/api_service.dart';
import '../services/auth_service.dart';
// 설정 Provider (센서 활성화 여부)
import '../providers/settings_provider.dart';

/// ⏱️ 포모도로 시간 설정 (테스트용으로 쉽게 변경 가능)
/// 실제 배포 시: FOCUS = 25, SHORT_BREAK = 5, LONG_BREAK = 30
const int FOCUS_MINUTES = 1;       // 집중 시간 (분) - 테스트: 1분으로 변경 가능
const int SHORT_BREAK_MINUTES = 1;  // 짧은 휴식 (분) - 테스트: 1분으로 변경 가능
const int LONG_BREAK_MINUTES = 2;  // 장휴식 (분) - 테스트: 2분으로 변경 가능

/// 포모도로 타이머 상태
enum PomodoroState {
  focus,      // 집중
  shortBreak, // 짧은 휴식
  longBreak,  // 장휴식
}

/// 포모도로 타이머 화면
class PomodoroScreen extends StatefulWidget {
  final int? resumeSessionId; // 이어하기할 세션 ID
  final int? resumePomoCount; // 이어하기할 포모도로 카운트

  const PomodoroScreen({
    super.key,
    this.resumeSessionId,
    this.resumePomoCount,
  });

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
  int _remainingSeconds = FOCUS_MINUTES * 60; // 기본 집중 시간
  bool _isRunning = false;

  // 세션
  StudySession? _currentSession;

  // === 센서 관련 ===
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription; // 가속도계 센서 구독
  bool _isPhoneFaceDown = false; // 폰이 뒤집혀있는지 (화면이 바닥을 향함)
  bool _waitingForFlip = false; // "출발!" 버튼 후 폰 뒤집기 대기 중
  bool _isShowingPopup = false; // 팝업 표시 중 여부 (팝업 중 센서 무시)
  bool _sensorEnabled = true; // 센서 활성화 상태 (설정에서 가져온 값 캐시)

  @override
  void initState() {
    super.initState();
    _initAuth(); // 인증 초기화
    _initSensorSettings(); // 설정에서 센서 활성화 여부 로드
    _initAccelerometer(); // 가속도계 센서 초기화
    _initializeSession(); // 목표 로드 후 세션 재개
  }

  /// 설정에서 센서 활성화 여부 로드
  /// SettingsProvider에서 isSensorEnabled 값을 가져와 _sensorEnabled에 캐시
  /// WidgetsBinding.addPostFrameCallback: 위젯 빌드 완료 후 실행 (Provider 접근 가능)
  void _initSensorSettings() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // listen: false - 일회성 읽기 (변경 감지 불필요)
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      setState(() {
        _sensorEnabled = settings.isSensorEnabled;
      });
    });
  }

  /// 목표 로드 후 세션 재개 (순서 보장)
  Future<void> _initializeSession() async {
    await _loadGoals(); // 1단계: 먼저 목표들을 로드
    await _resumeSessionIfNeeded(); // 2단계: 목표 로드 완료 후 세션 재개 및 목표 자동 선택
  }

  /// 세션 이어하기 및 자동 복구
  /// 1. 서버에 진행 중인 세션이 있는지 확인
  /// 2. 있다면 해당 세션으로 상태 복구
  /// 3. 없다면 (그리고 위젯 파라미터로 전달받은 게 있다면) 파라미터 기반으로 복구 시도
  Future<void> _resumeSessionIfNeeded() async {
    try {
      // 1. 항상 서버에서 진행 중인 세션 확인 (자동 이어하기)
      final session = await ApiService.fetchActivePomodoroSession(_userId);

      if (session != null) {
        _restoreSessionState(session);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('진행 중인 학습 세션을 불러왔습니다.')),
          );
        }
        return;
      }
    } catch (e) {
      print('세션 자동 복구 실패: $e');
    }

    // 2. 서버에 없지만, 홈 화면에서 명시적으로 이어하기를 누른 경우 (오프라인 등 예외 상황)
    if (widget.resumeSessionId != null && widget.resumePomoCount != null) {
      setState(() {
        _currentSession = StudySession(
          id: widget.resumeSessionId!,
          goalId: null,
          goalTitle: null,
          startedAt: DateTime.now(),
          endedAt: null,
          achievedAmount: 0,
          durationMinutes: 0,
          pomoCount: widget.resumePomoCount!,
          note: null,
          inProgress: true,
        );
        _totalPomodoros = widget.resumePomoCount!;
        _completedSets = widget.resumePomoCount!;
        _waitingForFlip = true;
      });
    }
  }

  /// 세션 상태 복구 헬퍼
  void _restoreSessionState(StudySession session) {
    // 센서 설정 확인
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final bool sensorEnabled = settings.isSensorEnabled;

    setState(() {
      _currentSession = session;
      _totalPomodoros = session.pomoCount;
      _completedSets = session.pomoCount;

      // 센서 설정에 따라 대기 상태 결정
      if (sensorEnabled) {
        _waitingForFlip = true;
      } else {
        _waitingForFlip = false;
        _isRunning = false; // 일시정지 상태로 시작
      }

      // 목표가 있다면 자동으로 선택
      if (session.goalId != null && _goals.isNotEmpty) {
        try {
          _selectedGoal = _goals.firstWhere(
            (goal) => goal.id == session.goalId,
          );
        } catch (e) {
          print('목표를 찾을 수 없습니다: ${session.goalId}');
        }
      }
    });
  }

  /// 포모도로 카운트를 서버에 실시간 업데이트
  /// 앱 강제 종료 시에도 진행 상황이 보존되도록 매 포모도로 완료마다 호출
  Future<void> _updatePomoCountToServer() async {
    if (_currentSession != null) {
      try {
        await ApiService.updatePomoCount(
          sessionId: _currentSession!.id,
          pomoCount: _totalPomodoros,
        );
        print('포모도로 카운트 업데이트 성공: $_totalPomodoros');
      } catch (e) {
        print('포모도로 카운트 업데이트 실패: $e');
        // 에러가 발생해도 사용자 경험을 방해하지 않도록 조용히 실패
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  /// 가속도계 초기화
  /// 가속도계 센서 초기화 및 이벤트 리스너 등록
  /// accelerometerEventStream(): 센서 데이터 스트림 (x, y, z 축 가속도)
  void _initAccelerometer() {
    _accelerometerSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      // 조건 1: 설정에서 센서 비활성화된 경우 센서 무시
      if (!_sensorEnabled) {
        return;
      }

      // 조건 2: 경고 팝업 표시 중이면 센서 무시
      // 예외: _waitingForFlip 상태의 "폰을 뒤집어주세요" 팝업은 센서 허용
      if (_isShowingPopup && !_waitingForFlip) {
        return;
      }

      // 조건 3: 타이머 실행 중이거나 플립 대기 중일 때만 센서 감지
      if (!_isRunning && !_waitingForFlip) {
        return;
      }

      // Z축 가속도로 폰 방향 감지
      // Z < -9.5: 화면이 바닥을 향함 (뒤집힌 상태)
      // Z > 0: 화면이 위를 향함 (정상 상태)
      bool isFaceDown = event.z < -9.5;

      // 상태 변화 시에만 처리 (중복 이벤트 방지)
      if (isFaceDown != _isPhoneFaceDown) {
        setState(() {
          _isPhoneFaceDown = isFaceDown;
        });
        _handleFlipChange(isFaceDown);
      }
    });
  }

  /// 폰 뒤집기 상태 변화 처리
  void _handleFlipChange(bool isFaceDown) {
    if (isFaceDown) {
      // 폰을 뒤집음 (화면이 바닥을 향함)
      _onPhoneFlippedDown();
    } else {
      // 폰을 다시 뒤집음 (화면이 위를 향함)
      _onPhoneFlippedUp();
    }
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

  /// 폰을 뒤집었을 때 (화면이 바닥을 향함)
  void _onPhoneFlippedDown() {
    if (_waitingForFlip) {
      // "출발!" 버튼 후 대기 중이었다면 → 팝업 닫고 타이머 시작

      // 기존 팝업 닫기
      if (_isShowingPopup && mounted) {
        try {
          Navigator.of(context).pop();
        } catch (e) {
          print('팝업 닫기 실패 (onFlipDown): $e');
        } finally {
          _isShowingPopup = false;
        }
      }

      setState(() {
        _waitingForFlip = false;
      });
      _vibrate();
      _showPomodoroPopup('${_totalPomodoros + 1}포모 시작!');
      _startTimer();
    } else if (_isRunning && _pomodoroState == PomodoroState.focus) {
      // 집중 타이머 동작 중 → 아무것도 안함 (집중 유지)
    } else if (!_isRunning && _pomodoroState == PomodoroState.focus) {
      // 집중 모드인데 정지 상태 → 타이머 재개
      _vibrate();
      _showPomodoroPopup('학습 재개!');
      _startTimer();
    }
    // 휴식 중에는 뒤집어도 아무 일 없음
  }

  /// 폰을 다시 뒤집었을 때 (화면이 위를 향함)
  void _onPhoneFlippedUp() {
    if (_isRunning && _pomodoroState == PomodoroState.focus) {
      // 집중 타이머 동작 중 폰을 뒤집음 → 경고 후 초기화
      _pauseTimer();
      _vibrate();
      _showWarningDialog();
    }
    // 휴식 중에는 뒤집어도 아무 일 없음
  }

  /// 진동
  void _vibrate() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 500);
    }
  }

  /// 중앙 팝업 (몇 포모, 휴식 등)
  void _showPomodoroPopup(String message) {
    // 이미 팝업이 표시 중이면 무시
    if (_isShowingPopup) return;

    _isShowingPopup = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: Color(0xFFFF6B6B),
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF191F28),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // 2초 후 자동으로 닫기
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isShowingPopup) {
        try {
          Navigator.of(context).pop();
        } catch (e) {
          print('팝업 닫기 실패: $e');
        } finally {
          _isShowingPopup = false; // 팝업 닫힐 때 플래그 리셋
        }
      }
    });
  }

  /// 경고 다이얼로그 (집중 중 폰 뒤집음)
  void _showWarningDialog() {
    // 팝업이 표시되는 동안 센서 완전히 중지
    _isShowingPopup = true;

    showDialog(
      context: context,
      barrierDismissible: false, // 사용자가 반드시 선택하도록 강제
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('집중을 방해했습니다!'),
          ],
        ),
        content: const Text('타이머가 초기화됩니다.\n다시 집중하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _isShowingPopup = false; // 센서 재활성화
              // 타이머 초기화
              _resetCurrentTimer();
            },
            child: const Text('다시 집중하기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _isShowingPopup = false; // 센서 재활성화
              // 세션 종료
              _endSession();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('종료하기'),
          ),
        ],
      ),
    );
  }

  /// 현재 타이머 초기화
  void _resetCurrentTimer() {
    setState(() {
      if (_pomodoroState == PomodoroState.focus) {
        _remainingSeconds = FOCUS_MINUTES * 60;
      } else if (_pomodoroState == PomodoroState.shortBreak) {
        _remainingSeconds = SHORT_BREAK_MINUTES * 60;
      } else {
        _remainingSeconds = LONG_BREAK_MINUTES * 60;
      }
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

    _vibrate(); // 진동

    if (_pomodoroState == PomodoroState.focus) {
      // 집중 세션 완료
      setState(() {
        _completedSets++;
        _totalPomodoros++;
      });

      // 포모도로 카운트를 서버에 실시간 업데이트 (앱 강제 종료 대비)
      _updatePomoCountToServer();

      // 4세트 완료 시 장휴식, 아니면 짧은 휴식 - 자동으로 시작
      if (_completedSets % 4 == 0) {
        _showPomodoroPopup('장휴식 시작!\n30분 동안 푹 쉬세요');
        _startBreak(PomodoroState.longBreak);  // 자동으로 장휴식 시작
      } else {
        _showPomodoroPopup('휴식 시작!\n5분 쉬어가세요');
        _startBreak(PomodoroState.shortBreak);  // 자동으로 짧은 휴식 시작
      }
    } else {
      // 휴식 완료 - 다음 포모도로 준비
      _vibrate();
      
      if (_sensorEnabled) {
        // 센서 사용 시: 폰 뒤집기 대기
        _showPomodoroPopup('${_totalPomodoros + 1}포모 준비!\n폰을 뒤집으세요');
        setState(() {
          _pomodoroState = PomodoroState.focus;
          _remainingSeconds = FOCUS_MINUTES * 60;
          _waitingForFlip = true;  // 폰 뒤집기 대기
        });
      } else {
        // 센서 미사용 시: 버튼 대기
        _showPomodoroPopup('${_totalPomodoros + 1}포모 준비 완료!');
        setState(() {
          _pomodoroState = PomodoroState.focus;
          _remainingSeconds = FOCUS_MINUTES * 60;
          _waitingForFlip = false; // 대기 없음
          _isRunning = false;      // 정지 상태 (사용자가 시작 눌러야 함)
        });
      }
    }
  }

  /// 휴식 시작
  void _startBreak(PomodoroState breakState) {
    setState(() {
      _pomodoroState = breakState;
      _remainingSeconds = breakState == PomodoroState.longBreak ? LONG_BREAK_MINUTES * 60 : SHORT_BREAK_MINUTES * 60;
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
                '학습 시간: ${_totalPomodoros * 25}분',
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
      // 포모도로 세트 수로 시간 계산 (1세트 = 25분)
      final duration = _totalPomodoros * 25;

      // 백엔드에서 Goal progress를 자동으로 업데이트하므로 프론트에서 별도 호출 불필요
      await ApiService.endPomodoroSession(
        sessionId: _currentSession!.id,
        achievedAmount: achievement,
        durationMinutes: duration,
        pomoCount: _totalPomodoros,
        note: note.isEmpty ? null : note,
      );

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
        return FOCUS_MINUTES * 60;
      case PomodoroState.shortBreak:
        return SHORT_BREAK_MINUTES * 60;
      case PomodoroState.longBreak:
        return LONG_BREAK_MINUTES * 60;
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
              isExpanded: true, // 텍스트 오버플로우 방지
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

  /// 출발! 버튼 - 센서 활성화 여부에 따라 다르게 동작
  /// 포모도로 시작 전 센서 설정에 따른 처리
  /// - 센서 활성화: 폰 뒤집기 대기 상태로 전환
  /// - 센서 비활성화: 즉시 타이머 시작
  void _startWaitingForFlip() {
    if (_sensorEnabled) {
      // 센서 활성화 모드: 폰 뒤집기 대기
      setState(() {
        _waitingForFlip = true; // 플립 대기 상태 활성화
        _isPhoneFaceDown = false; // 사용자가 화면을 보고 있으므로 앞면 상태
      });

      _vibrate(); // 햅틱 피드백
      _showPomodoroPopup('폰을 뒤집어주세요!'); // 안내 메시지
    } else {
      // 센서 비활성화 모드: 즉시 타이머 시작
      _vibrate(); // 햅틱 피드백
      _showPomodoroPopup('${_totalPomodoros + 1}포모 시작!'); // 시작 메시지
      _startTimer(); // 타이머 즉시 시작
    }
  }

  /// 시작/정지 버튼
  Widget _buildControlButton() {
    // 대기 중
    if (_waitingForFlip) {
      return Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade600],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '폰을 뒤집어주세요...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
          onTap: () {
            if (_isRunning) {
              _pauseTimer();
            } else if (!_waitingForFlip) {
              // 첫 시작 또는 재개 - 모두 폰 뒤집기부터 시작
              _startWaitingForFlip();
            } else {
              // 대기 중 취소
              setState(() {
                _waitingForFlip = false;
              });
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isRunning ? Icons.pause_circle_filled :
                  _waitingForFlip ? Icons.cancel :
                  (_currentSession == null ? Icons.flag : Icons.play_circle_filled),
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  _isRunning ? '일시정지' :
                  _waitingForFlip ? '대기 취소' :
                  (_currentSession == null ? '출발!' : '재개'),
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
