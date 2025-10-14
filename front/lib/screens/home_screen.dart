import 'package:flutter/material.dart';
import '../models/home_data.dart';
import '../models/schedule.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/section_card.dart';
import '../widgets/calendar_widget.dart';
import 'schedule_form_screen.dart';
import 'wordbook_list_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeData? _homeData;
  bool _isLoading = true;
  String _error = '';
  bool _showCalendar = false;
  DateTime _selectedDate = DateTime.now();
  Map<DateTime, List<Schedule>> _schedules = {};
  List<Schedule> _selectedDateSchedules = [];
  
  // AuthService 인스턴스
  AuthService? _authService;
  int _userId = 1; // 기본값

  int _totalCards = 0; // 단어장 총 카드 수
  int _learnedCards = 0; // 학습한 카드 수
  int _reviewCards = 0; // 복습한 카드 수
  int _difficultCards = 0; // 어려운 카드 수

  @override
  void initState() {
    super.initState();
    _initAuth();
    _loadData();
    _loadSchedules();
    _loadWordBookStats();
  }

  Future<void> _initAuth() async {
    _authService = await AuthService.getInstance();
    setState(() {
      _userId = _authService!.currentUserId;
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final data = await ApiService.fetchHomeData();
      setState(() {
        _homeData = data;
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
                          onPressed: _loadData,
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await _loadData();
                      await _loadSchedules();
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
                                    color: Colors.black.withOpacity(0.05),
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

                          // 타이머 섹션
                          SectionCard(
                            title: '타이머',
                            subtitle: _homeData?.timerInfo.displayText ?? '',
                            onTap: () {
                              // 타이머 상세 화면으로 이동
                            },
                          ),

                          // 단어장 섹션 (API 연동)
                          SectionCard(
                            title: '단어장',
                            subtitle: '학습 $_learnedCards · 복습 $_reviewCards · 어려움 $_difficultCards',
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

                          // 오늘의 목표 섹션
                          SectionCard(
                            title: '오늘의 목표',
                            subtitle: '',
                            customContent: CircularProgressWidget(
                              completed: _getTodayGoalProgress().completed,
                              total: _getTodayGoalProgress().total,
                            ),
                            // 화살표 없음 (상세 페이지 없음)
                          ),

                          // 진행 상황 섹션 (나중에 별도 API 연동 예정)
                          SectionCard(
                            title: '진행 상황',
                            subtitle: '',
                            customContent: LinearProgressWidget(
                              percentage: _homeData?.progressInfo.percentage ?? 0,
                            ),
                            onTap: () {
                              // 진행 상황 상세 화면으로 이동
                            },
                          ),

                          // 주간 정산 섹션
                          SectionCard(
                            title: '주간 정산',
                            subtitle: _homeData?.weeklyStats.displayText ?? '',
                            onTap: () {
                              // 주간 정산 상세 화면으로 이동
                            },
                          ),

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF6366F1),
          unselectedItemColor: Colors.grey,
          currentIndex: 1, // 홈 화면이므로 1번 인덱스 선택
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: '',
            ),
          ],
          onTap: (index) {
            // 네비게이션 처리
            // TODO: 다른 화면으로 이동
          },
        ),
      ),
    );
  }
}
