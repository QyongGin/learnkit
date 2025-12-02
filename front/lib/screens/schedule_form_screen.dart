import 'package:flutter/material.dart';
// intl: 날짜/시간 포맷팅 (DateFormat)
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../models/schedule.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/common_widgets.dart';

class ScheduleFormScreen extends StatefulWidget {
  final Schedule? schedule; // null이면 새로운 일정 생성, 있으면 수정
  final DateTime? selectedDate;

  const ScheduleFormScreen({
    super.key,
    this.schedule,
    this.selectedDate,
  });

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _startTime;
  DateTime? _endTime;
  bool _isCompleted = false;
  bool _isLoading = false;
  
  // AuthService 인스턴스
  AuthService? _authService;
  int _userId = 1; // 기본값

  @override
  void initState() {
    super.initState();
    _initAuth();
    _titleController = TextEditingController(text: widget.schedule?.title ?? '');
    _descriptionController = TextEditingController(text: widget.schedule?.description ?? '');

    // 수정 모드면 기존 일정의 시간 사용, 생성 모드면 선택된 날짜 사용
    if (widget.schedule != null) {
      _startTime = widget.schedule!.startTime;
      _endTime = widget.schedule!.endTime;
    } else if (widget.selectedDate != null) {
      // 선택된 날짜를 기본 시작 시간으로 설정
      _startTime = DateTime(
        widget.selectedDate!.year,
        widget.selectedDate!.month,
        widget.selectedDate!.day,
        9, 0, // 기본 시작 시간: 오전 9시
      );
      _endTime = DateTime(
        widget.selectedDate!.year,
        widget.selectedDate!.month,
        widget.selectedDate!.day,
        10, 0, // 기본 종료 시간: 오전 10시
      );
    }

    _isCompleted = widget.schedule?.isCompleted ?? false;
  }

  Future<void> _initAuth() async {
    _authService = await AuthService.getInstance();
    setState(() {
      _userId = _authService!.currentUserId;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        // startTime이 없으면 오늘 날짜 기준, 있으면 그 날짜 기준
        final DateTime baseDate = (isStartTime ? _startTime : _endTime) ?? DateTime.now();
        final DateTime time = DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
          picked.hour,
          picked.minute,
        );
        if (isStartTime) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
    }
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.schedule == null) {
        // 새 일정 생성
        await ApiService.createSchedule(
          userId: _userId,
          title: _titleController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          startTime: _startTime,
          endTime: _endTime,
        );
      } else {
        // 기존 일정 수정
        await ApiService.updateSchedule(
          scheduleId: widget.schedule!.id,
          title: _titleController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          startTime: _startTime,
          endTime: _endTime,
          isCompleted: _isCompleted,
        );
      }

      if (mounted) {
        Navigator.pop(context, true); // true를 반환하여 데이터 새로고침 필요함을 알림
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSchedule() async {
    if (widget.schedule == null) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일정 삭제'),
        content: const Text('이 일정을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.deleteSchedule(widget.schedule!.id);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '시간 선택';
    return DateFormat('HH:mm').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          widget.schedule == null ? '새 일정' : '일정 수정',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.schedule != null)
            IconButton(
              icon: Icon(Icons.delete, color: AppColors.error),
              onPressed: _isLoading ? null : _deleteSchedule,
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 입력
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: '일정 제목',
                          border: InputBorder.none,
                        ),
                        style: AppTextStyles.heading3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '제목을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 설명 입력
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          hintText: '설명 (선택사항)',
                          border: InputBorder.none,
                        ),
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // 시간 선택
                    Text(
                      '시간',
                      style: AppTextStyles.label,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(true),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time, color: AppColors.primary),
                                  const SizedBox(width: AppSpacing.md),
                                  Text(
                                    _formatTime(_startTime),
                                    style: AppTextStyles.body1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                          child: Text('~'),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(false),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time, color: AppColors.primary),
                                  const SizedBox(width: AppSpacing.md),
                                  Text(
                                    _formatTime(_endTime),
                                    style: AppTextStyles.body1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // 완료 체크 (수정 모드에서만)
                    if (widget.schedule != null)
                      CheckboxListTile(
                        title: const Text('완료'),
                        value: _isCompleted,
                        onChanged: (value) {
                          setState(() {
                            _isCompleted = value ?? false;
                          });
                        },
                        activeColor: AppColors.success,
                        contentPadding: EdgeInsets.zero,
                      ),

                    const SizedBox(height: AppSpacing.xxxl),

                    // 저장 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveSchedule,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: Text(
                          widget.schedule == null ? '일정 추가' : '수정 완료',
                          style: AppTextStyles.button,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
