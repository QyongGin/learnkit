import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/schedule.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

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
    _startTime = widget.schedule?.startTime;
    _endTime = widget.schedule?.endTime;
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.schedule == null ? '새 일정' : '일정 수정',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.schedule != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _isLoading ? null : _deleteSchedule,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 입력
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: '일정 제목',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 18),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '제목을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 설명 입력
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          hintText: '설명 (선택사항)',
                          border: InputBorder.none,
                        ),
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 시간 선택
                    const Text(
                      '시간',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(true),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time, color: Color(0xFF6366F1)),
                                  const SizedBox(width: 12),
                                  Text(
                                    _formatTime(_startTime),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('~'),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(false),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time, color: Color(0xFF6366F1)),
                                  const SizedBox(width: 12),
                                  Text(
                                    _formatTime(_endTime),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

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
                        activeColor: const Color(0xFF00FF00),
                        contentPadding: EdgeInsets.zero,
                      ),

                    const SizedBox(height: 32),

                    // 저장 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveSchedule,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.schedule == null ? '일정 추가' : '수정 완료',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
