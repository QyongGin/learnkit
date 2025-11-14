// Flutter Material Design 위젯 제공
import 'package:flutter/material.dart';
// 데이터 모델
import '../models/home_data.dart';
import '../models/schedule.dart';
// API 통신 및 인증 서비스
import '../services/api_service.dart';
import '../services/auth_service.dart';
// 커스텀 위젯
import '../widgets/section_card.dart';
import '../widgets/calendar_widget.dart';
// 화면들
import 'schedule_form_screen.dart';
import 'wordbook_list_screen.dart';
import 'profile_screen.dart';
import 'pomodoro_screen.dart';
import 'goal_list_screen.dart';
import 'study_history_screen.dart';
import 'weekly_summary_screen.dart';
import 'settings_screen.dart';
// 날짜 포맷팅 패키지
import 'package:intl/intl.dart';

/// 홈 화면
/// - 학습 목표 요약 표시
/// - 캘린더 및 일정 관리
/// - 단어장 통계
/// - 하단 네비게이션 바 (프로필, 홈, 설정)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 홈 데이터 (미구현 API)
  HomeData? _homeData;
  // 로딩 상태
  bool _isLoading = true;
  // 에러 메시지
  String _error = '';
  // 캘린더 표시 여부
  bool _showCalendar = false;
  // 선택된 날짜
  DateTime _selectedDate = DateTime.now();
  // 날짜별 일정 맵 (날짜 -> 일정 리스트)
  Map<DateTime, List<Schedule>> _schedules = {};
  // 선택된 날짜의 일정 리스트
  List<Schedule> _selectedDateSchedules = [];

  // 인증 서비스
  AuthService? _authService;
  int _userId = 1; // 현재 사용자 ID (기본값 1)

  // 단어장 통계
  int _totalCards = 0; // 전체 카드 수 (미래 사용 대비)
  int _learnedCards = 0; // 쉬움 난이도 (EASY)
  int _reviewCards = 0; // 보통 난이도 (NORMAL)
  int _difficultCards = 0; // 어려움 난이도 (HARD)

  @override
  void initState() {
    super.initState();
    _initAuth(); // 인증 초기화
    _loadAllDataParallel(); // 모든 데이터 병렬 로드
    _checkActiveSession(); // 진행 중인 학습 세션 확인
  }

  /// 인증 서비스 초기화
  /// AuthService 싱글톤 인스턴스 가져오기
  Future<void> _initAuth() async {
    _authService = await AuthService.getInstance();
    setState(() {
      _userId = _authService!.currentUserId;
    });
  }

  /// 모든 데이터를 병렬로 로드
  /// Future.wait()를 사용하여 여러 API 동시 호출로 속도 향상
  ///
  /// 로드 항목:
  /// - 일정 데이터 (_loadSchedules)
  /// - 단어장 통계 (_loadWordBookStats)
  Future<void> _loadAllDataParallel() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Future.wait: 여러 Future를 동시 실행하고 모두 완료될 때까지 대기
      await Future.wait([
        _loadSchedules(),
        _loadWordBookStats(),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSchedules() async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month - 1, 1);
      final end = DateTime(now.year, now.month + 2, 0);
      
      final schedules = await ApiService.fetchSchedules(
        userId: _userId,
        start: start,
        end: end,
      );
      
      final Map<DateTime, List<Schedule>> scheduleMap = {};
      for (var schedule in schedules) {
        // startTime이 없으면 건너뛰기
        if (schedule.startTime == null) continue;
        
        final normalizedDate = DateTime(
          schedule.startTime!.year,
          schedule.startTime!.month,
          schedule.startTime!.day,
        );
        if (scheduleMap[normalizedDate] == null) {
          scheduleMap[normalizedDate] = [];
        }
        scheduleMap[normalizedDate]!.add(schedule);
      }
      
      setState(() {
        _schedules = scheduleMap;
        _updateSelectedDateSchedules();
      });
    } catch (e) {
      // 에러 처리
    }
  }

  void _updateSelectedDateSchedules() {
    final normalizedDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    _selectedDateSchedules = _schedules[normalizedDate] ?? [];
  }

  /// 앱 시작 시 진행 중인 세션 확인
  Future<void> _checkActiveSession() async {
    try {
      final activeSession = await ApiService.fetchActivePomodoroSession(_userId);

      if (activeSession != null && mounted) {
        // 진행 중인 세션이 있으면 팝업 표시
        _showActiveSessionDialog(activeSession);
      }
    } catch (e) {
      // 에러 시 무시 (세션 없음으로 처리)
      print('진행 중인 세션 확인 실패: $e');
    }
  }

  /// 진행 중인 세션 발견 시 팝업 표시
  void _showActiveSessionDialog(dynamic activeSession) {
    showDialog(
      context: context,
      barrierDismissible: false, // 백그라운드 클릭으로 닫기 불가
      builder: (context) => AlertDialog(
        title: const Text('진행 중인 학습 세션'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('이전에 시작한 학습 세션이 진행 중입니다.'),
            const SizedBox(height: 12),
            if (activeSession.goalTitle != null)
              Text('목표: ${activeSession.goalTitle}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('포모도로: ${activeSession.pomoCount}개 완료'),
            const SizedBox(height: 12),
            const Text('이어서 진행하시겠습니까?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 종료 선택 - 세션 종료 API 호출
              _endActiveSession(activeSession.id);
              Navigator.of(context).pop();
            },
            child: const Text('종료'),
          ),
          ElevatedButton(
            onPressed: () {
              // 이어하기 선택 - 포모도로 화면으로 이동
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PomodoroScreen(
                    resumeSessionId: activeSession.id,
                    resumePomoCount: activeSession.pomoCount,
                  ),
                ),
              );
            },
            child: const Text('이어하기'),
          ),
        ],
      ),
    );
  }

  /// 진행 중인 세션 종료
  Future<void> _endActiveSession(int sessionId) async {
    try {
      await ApiService.endPomodoroSession(
        sessionId: sessionId,
        achievedAmount: 0,
        durationMinutes: 0,
        pomoCount: 0,
        note: '사용자가 종료함',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('세션 종료 실패: $e')),
        );
      }
    }
  }

  /// 단어장 통계 로드 (API 연동)
  Future<void> _loadWordBookStats() async {
    try {
      // 사용자의 모든 단어장 가져오기
      final wordBooks = await ApiService.fetchWordBooks(_userId);

      // 각 단어장의 통계 가져와서 합산
      int total = 0;
      int easy = 0;
      int normal = 0;
      int hard = 0;

      for (var wordBook in wordBooks) {
        final stats = await ApiService.fetchWordBookStatistics(wordBook.id);
        total += stats.totalCount;
        easy += stats.easyCount;
        normal += stats.normalCount;
        hard += stats.hardCount;
      }

      setState(() {
        _totalCards = total;
        _learnedCards = easy; // 쉬움 = 학습 완료
        _reviewCards = normal; // 보통 = 복습 필요
        _difficultCards = hard; // 어려움
      });
    } catch (e) {
      // 에러 시 0으로 유지
    }
  }

  /// 오늘의 목표 계산 (오늘 날짜 기준)
  GoalProgress _getTodayGoalProgress() {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final todaySchedules = _schedules[normalizedToday] ?? [];
    
    final total = todaySchedules.length;
    final completed = todaySchedules.where((s) => s.isCompleted).length;
    
    return GoalProgress(completed: completed, total: total);
  }

  String _getCurrentDate() {
    final formatter = DateFormat('yyyy년 M월 d일 EEEE', 'ko_KR');
    return formatter.format(_selectedDate);
  }

  void _toggleCalendar() {
    setState(() {
      _showCalendar = !_showCalendar;
    });
  }

  void _onDaySelected(DateTime selectedDay) {
    setState(() {
      _selectedDate = selectedDay;
      _updateSelectedDateSchedules();
    });
  }

  // 일정 추가 화면 열기
  Future<void> _openScheduleForm({Schedule? schedule, DateTime? selectedDate}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleFormScreen(
          schedule: schedule,
          selectedDate: selectedDate,
        ),
      ),
    );

    // 일정이 추가/수정/삭제되었으면 새로고침
    if (result == true) {
      await _loadSchedules();
    }
  }

  // 완료 상태 토글
  Future<void> _toggleScheduleComplete(Schedule schedule) async {
    try {
      await ApiService.updateSchedule(
        scheduleId: schedule.id,
        isCompleted: !schedule.isCompleted,
      );
      
      // 스케줄 목록 새로고침
      await _loadSchedules();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('완료 상태 변경 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('데이터를 불러오는데 실패했습니다'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadAllDataParallel,
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await _loadSchedules();
                      await _loadWordBookStats();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          // 날짜 헤더 (드래그 가능)
                          GestureDetector(
                            onTap: _toggleCalendar,
                            onVerticalDragEnd: (details) {
                              if (details.primaryVelocity! > 0) {
                                // 아래로 드래그
                                setState(() {
                                  _showCalendar = true;
                                });
                              } else {
                                // 위로 드래그
                                setState(() {
                                  _showCalendar = false;
                                });
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _getCurrentDate(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _showCalendar
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 캘린더 (접었다 폈다 가능)
                          if (_showCalendar) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: CalendarWidget(
                                onDaySelected: _onDaySelected,
                                onDayLongPressed: (date) {
                                  // 날짜 길게 누르면 일정 추가
                                  _openScheduleForm(selectedDate: date);
                                },
                                schedules: _schedules,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // 선택된 날짜의 스케줄 목록
                            ScheduleListWidget(
                              selectedDate: _selectedDate,
                              schedules: _selectedDateSchedules,
                              onScheduleTap: (schedule) {
                                // 일정 탭하면 수정 화면으로
                                _openScheduleForm(schedule: schedule);
                              },
                              onAddSchedule: () {
                                // + 버튼으로 선택된 날짜에 일정 추가
                                _openScheduleForm(selectedDate: _selectedDate);
                              },
                              onToggleComplete: _toggleScheduleComplete,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // 오늘의 할 일 섹션
                          SectionCard(
                            title: '오늘의 할 일',
                            subtitle: '',
                            customContent: CircularProgressWidget(
                              completed: _getTodayGoalProgress().completed,
                              total: _getTodayGoalProgress().total,
                            ),
                            // 화살표 없음 (상세 페이지 없음)
                          ),

                          // 목표 섹션
                          SectionCard(
                            title: '목표',
                            subtitle: '나의 학습 목표를 관리하세요',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const GoalListScreen(),
                                ),
                              );
                            },
                          ),

                          // 타이머 섹션
                          SectionCard(
                            title: '타이머',
                            subtitle: _homeData?.timerInfo.displayText ?? '',
                            onTap: () {
                              // 포모도로 타이머 화면으로 이동
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PomodoroScreen(),
                                ),
                              );
                            },
                          ),

                          // 단어장 섹션 (API 연동)
                          SectionCard(
                            title: '단어장',
                            subtitle: '쉬움 $_learnedCards · 보통 $_reviewCards · 어려움 $_difficultCards',
                            onTap: () {
                              // 단어장 목록 화면으로 이동
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WordBookListScreen(),
                                ),
                              ).then((_) => _loadWordBookStats()); // 돌아올 때 새로고침
                            },
                          ),

                          // 학습 기록 섹션
                          SectionCard(
                            title: '학습 기록',
                            subtitle: '나의 학습 기록을 확인하세요',
                            onTap: () {
                              // 학습 기록 화면으로 이동
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StudyHistoryScreen(),
                                ),
                              );
                            },
                          ),

                          // 주간 정산 섹션
                          SectionCard(
                            title: '주간 정산',
                            subtitle: _homeData?.weeklyStats.displayText ?? '',
                            onTap: () {
                              // 주간 정산 상세 화면으로 이동
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WeeklySummaryScreen(),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
      ),
      // 하단 네비게이션 바
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),  // 위쪽으로 그림자
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,  // 그림자 제거 (Container에서 이미 처리)
          selectedItemColor: const Color(0xFF6366F1),  // 선택된 아이템 색상
          unselectedItemColor: Colors.grey,  // 미선택 아이템 색상
          currentIndex: 1,  // 현재 홈 화면 (1번 인덱스)
          type: BottomNavigationBarType.fixed,  // 고정 타입 (3개 아이템)
          items: const [
            // 0번: 프로필
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: '',
            ),
            // 1번: 홈
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '',
            ),
            // 2번: 설정
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: '',
            ),
          ],
          // 네비게이션 아이템 탭 시
          onTap: (index) {
            if (index == 0) {
              // 프로필 화면으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              ).then((_) {
                // 프로필에서 돌아올 때 단어장 통계 새로고침
                _loadWordBookStats();
              });
            } else if (index == 1) {
              // 이미 홈 화면이므로 아무 동작 없음
            } else if (index == 2) {
              // 설정 화면으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
