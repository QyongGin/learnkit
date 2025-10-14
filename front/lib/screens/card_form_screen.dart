import 'package:flutter/material.dart';
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const Text(
                '쉬움 보통 어려움',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                ),
              ),
              const Divider(height: 32),
              _buildDifficultyOption(
                models.CardDifficulty.EASY,
                '쉬움',
                const Color(0xFF20C997),
              ),
              _buildDifficultyOption(
                models.CardDifficulty.NORMAL,
                '보통',
                const Color(0xFF3182F6),
              ),
              _buildDifficultyOption(
                models.CardDifficulty.HARD,
                '어려움',
                const Color(0xFFFF6B6B),
              ),
              const SizedBox(height: 20),
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
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : null,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? color : Colors.grey.shade700,
          letterSpacing: -0.3,
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
        return const Color(0xFF20C997);
      case models.CardDifficulty.NORMAL:
        return const Color(0xFF3182F6);
      case models.CardDifficulty.HARD:
        return const Color(0xFFFF6B6B);
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.card == null ? '카드 추가' : '카드 수정',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          // 난이도 선택 버튼
          GestureDetector(
            onTap: _showDifficultyMenu,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getDifficultyColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getDifficultyColor().withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    _getDifficultyLabel(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getDifficultyColor(),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 4),
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 앞면 (질문) 입력
                      _buildLabel('앞면'),
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 24),

                      // 뒷면 (답변) 입력
                      _buildLabel('뒷면'),
                      const SizedBox(height: 8),
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
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
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            '저장',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
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
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: Colors.black87,
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
      style: const TextStyle(
        fontSize: 16,
        letterSpacing: -0.3,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 16,
          letterSpacing: -0.3,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
