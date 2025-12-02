import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/card.dart' as models;
import '../services/api_service.dart';

/// 카드(단어) 생성/수정 화면
class CardFormScreen extends StatefulWidget {
  final int wordBookId;
  final models.Card? card; // null이면 생성, 있으면 수정

  const CardFormScreen({
    super.key,
    required this.wordBookId,
    this.card,
  });

  @override
  State<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends State<CardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _frontController = TextEditingController();
  final _backController = TextEditingController();
  models.CardDifficulty _selectedDifficulty = models.CardDifficulty.NORMAL;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.card != null) {
      // 수정 모드
      _frontController.text = widget.card!.frontText;
      _backController.text = widget.card!.backText;
      _selectedDifficulty = widget.card!.difficulty ?? models.CardDifficulty.NORMAL;
    }
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.card == null) {
        // 생성
        await ApiService.createCard(
          wordBookId: widget.wordBookId,
          question: _frontController.text,
          answer: _backController.text,
          difficulty: _selectedDifficulty,
        );
      } else {
        // 수정
        await ApiService.updateCard(
          cardId: widget.card!.id,
          question: _frontController.text,
          answer: _backController.text,
          difficulty: _selectedDifficulty,
        );
      }

      if (mounted) {
        Navigator.pop(context, true); // 성공 시 true 반환
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDifficultyMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Text(
                '난이도 설정',
                style: AppTextStyles.heading3,
              ),
              const Divider(height: AppSpacing.xxxl),
              _buildDifficultyOption(
                models.CardDifficulty.EASY,
                '쉬움',
                AppColors.difficultyEasy,
              ),
              _buildDifficultyOption(
                models.CardDifficulty.NORMAL,
                '보통',
                AppColors.difficultyNormal,
              ),
              _buildDifficultyOption(
                models.CardDifficulty.HARD,
                '어려움',
                AppColors.difficultyHard,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(
    models.CardDifficulty difficulty,
    String label,
    Color color,
  ) {
    final isSelected = _selectedDifficulty == difficulty;

    return ListTile(
      onTap: () {
        setState(() {
          _selectedDifficulty = difficulty;
        });
        Navigator.pop(context);
      },
      leading: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: isSelected
            ? Icon(Icons.check, color: AppColors.surface, size: 16)
            : null,
      ),
      title: Text(
        label,
        style: AppTextStyles.body1.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? color : AppColors.textSecondary,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: color)
          : null,
    );
  }

  Color _getDifficultyColor() {
    switch (_selectedDifficulty) {
      case models.CardDifficulty.EASY:
        return AppColors.difficultyEasy;
      case models.CardDifficulty.NORMAL:
        return AppColors.difficultyNormal;
      case models.CardDifficulty.HARD:
        return AppColors.difficultyHard;
    }
  }

  String _getDifficultyLabel() {
    switch (_selectedDifficulty) {
      case models.CardDifficulty.EASY:
        return '쉬움';
      case models.CardDifficulty.NORMAL:
        return '보통';
      case models.CardDifficulty.HARD:
        return '어려움';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.card == null ? '카드 추가' : '카드 수정',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          // 난이도 선택 버튼
          GestureDetector(
            onTap: _showDifficultyMenu,
            child: Container(
              margin: const EdgeInsets.only(right: AppSpacing.lg),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
              decoration: BoxDecoration(
                color: _getDifficultyColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: _getDifficultyColor().withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    _getDifficultyLabel(),
                    style: AppTextStyles.label.copyWith(
                      color: _getDifficultyColor(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.arrow_drop_down,
                    color: _getDifficultyColor(),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // 빈 공간 탭 시 키보드 닫기
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 앞면 (질문) 입력
                      _buildLabel('앞면'),
                      const SizedBox(height: AppSpacing.sm),
                      _buildTextField(
                        controller: _frontController,
                        hintText: '질문 또는 단어를 입력하세요',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '앞면을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // 뒷면 (답변) 입력
                      _buildLabel('뒷면'),
                      const SizedBox(height: AppSpacing.sm),
                      _buildTextField(
                        controller: _backController,
                        hintText: '답변 또는 뜻을 입력하세요',
                        minLines: 12,
                        maxLines: 20,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '뒷면을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

            // 저장 버튼
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveCard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textPrimary,
                      foregroundColor: AppColors.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.surface,
                            ),
                          )
                        : Text(
                            '저장',
                            style: AppTextStyles.button,
                          ),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.label.copyWith(
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int minLines = 1,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      validator: validator,
      style: AppTextStyles.body1,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.body1.copyWith(
          color: AppColors.textHint,
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.textPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
      ),
    );
  }
}
