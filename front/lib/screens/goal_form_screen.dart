import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/goal.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

/// 목표 생성/수정 화면
class GoalFormScreen extends StatefulWidget {
  final Goal? goal;

  const GoalFormScreen({super.key, this.goal});

  @override
  State<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends State<GoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _targetUnitController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  int _userId = 1;

  bool get isEditMode => widget.goal != null;

  @override
  void initState() {
    super.initState();
    _initAuth();

    if (isEditMode) {
      _titleController.text = widget.goal!.title;
      _targetAmountController.text = widget.goal!.totalTargetAmount.toString();
      _targetUnitController.text = widget.goal!.targetUnit;
      _startDate = widget.goal!.startDate;
      _endDate = widget.goal!.endDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    _targetUnitController.dispose();
    super.dispose();
  }

  Future<void> _initAuth() async {
    final authService = await AuthService.getInstance();
    setState(() {
      _userId = authService.currentUserId;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (isEditMode) {
        await ApiService.updateGoal(
          goalId: widget.goal!.id,
          title: _titleController.text,
          startDate: _startDate,
          endDate: _endDate,
          totalTargetAmount: int.parse(_targetAmountController.text),
          targetUnit: _targetUnitController.text,
        );
      } else {
        await ApiService.createGoal(
          userId: _userId,
          title: _titleController.text,
          startDate: _startDate,
          endDate: _endDate,
          totalTargetAmount: int.parse(_targetAmountController.text),
          targetUnit: _targetUnitController.text,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditMode ? '목표가 수정되었습니다' : '목표가 생성되었습니다'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: Colors.red,
          ),
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
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditMode ? '목표 수정' : '새 목표',
          style: AppTextStyles.heading2,
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('목표 제목', style: AppTextStyles.label),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: '예: 토익 800점 달성',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '목표 제목을 입력하세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // 목표량
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '목표량',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF191F28),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _targetAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '100',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '목표량을 입력하세요';
                              }
                              if (int.tryParse(value) == null) {
                                return '숫자만 입력하세요';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '단위',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF191F28),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _targetUnitController,
                            decoration: InputDecoration(
                              hintText: '문제',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '단위 입력';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 기간 설정
                const Text(
                  '기간 (선택사항)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF191F28),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateButton(
                        label: '시작일',
                        date: _startDate,
                        onTap: () => _selectDate(context, true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateButton(
                        label: '종료일',
                        date: _endDate,
                        onTap: () => _selectDate(context, false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 저장 버튼
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveGoal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            isEditMode ? '수정 완료' : '목표 생성',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
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

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: date != null ? Colors.black87 : Colors.grey.shade400,
                ),
                const SizedBox(width: 8),
                Text(
                  date != null
                      ? '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}'
                      : '선택',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: date != null ? Colors.black87 : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
