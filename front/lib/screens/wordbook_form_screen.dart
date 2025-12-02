import 'package:flutter/material.dart';
// flutter/services: 플랫폼 서비스 (키보드 입력 포맷팅 등)
import 'package:flutter/services.dart';
import '../config/app_theme.dart';
import '../models/wordbook.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/common_widgets.dart';

/// 단어장 생성/수정 화면 (빈도 비율 방식)
class WordBookFormScreen extends StatefulWidget {
  final WordBook? wordBook; // null이면 생성, 있으면 수정

  const WordBookFormScreen({super.key, this.wordBook});

  @override
  State<WordBookFormScreen> createState() => _WordBookFormScreenState();
}

class _WordBookFormScreenState extends State<WordBookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // 난이도별 빈도 비율 - 기본값: 쉬움 x1, 보통 x3, 어려움 x6
  int _easyRatio = 1;
  int _normalRatio = 3;
  int _hardRatio = 6;

  int _userId = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initAuth();
    // 수정 모드인 경우 기존 데이터로 초기화
    if (widget.wordBook != null) {
      _titleController.text = widget.wordBook!.title;
      _descriptionController.text = widget.wordBook!.description ?? '';
      _easyRatio = widget.wordBook!.easyFrequencyRatio;
      _normalRatio = widget.wordBook!.normalFrequencyRatio;
      _hardRatio = widget.wordBook!.hardFrequencyRatio;
    }
  }

  Future<void> _initAuth() async {
    final authService = await AuthService.getInstance();
    setState(() {
      _userId = authService.currentUserId;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// 빈도 비율 유효성 검증
  bool _validateRatios() {
    // 최소값 검증
    if (_easyRatio < 1) {
      _showErrorSnackBar('쉬움 빈도는 최소 1배 이상이어야 합니다');
      return false;
    }
    if (_normalRatio < 2) {
      _showErrorSnackBar('보통 빈도는 최소 2배 이상이어야 합니다');
      return false;
    }
    if (_hardRatio < 3) {
      _showErrorSnackBar('어려움 빈도는 최소 3배 이상이어야 합니다');
      return false;
    }

    // 순서 검증: 쉬움 < 보통 < 어려움
    if (_easyRatio >= _normalRatio) {
      _showErrorSnackBar('보통 빈도는 쉬움보다 커야 합니다');
      return false;
    }
    if (_normalRatio >= _hardRatio) {
      _showErrorSnackBar('어려움 빈도는 보통보다 커야 합니다');
      return false;
    }

    return true;
  }

  /// 에러 스낵바 표시
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 저장 버튼 클릭
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 빈도 비율 유효성 검증
    if (!_validateRatios()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.wordBook == null) {
        // 생성 모드
        await ApiService.createWordBook(
          userId: _userId,
          title: _titleController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          easyFrequencyRatio: _easyRatio,
          normalFrequencyRatio: _normalRatio,
          hardFrequencyRatio: _hardRatio,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('단어장이 생성되었습니다')),
          );
        }
      } else {
        // 수정 모드
        await ApiService.updateWordBook(
          wordBookId: widget.wordBook!.id,
          title: _titleController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          easyFrequencyRatio: _easyRatio,
          normalFrequencyRatio: _normalRatio,
          hardFrequencyRatio: _hardRatio,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('단어장이 수정되었습니다')),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true); // true를 반환하여 목록 새로고침
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
        setState(() => _isLoading = false);
      }
    }
  }

  /// 삭제 버튼 클릭
  Future<void> _handleDelete() async {
    if (widget.wordBook == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('단어장 삭제'),
        content: Text('\'${widget.wordBook!.title}\' 단어장을 삭제하시겠습니까?\n모든 단어가 함께 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await ApiService.deleteWordBook(widget.wordBook!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('단어장이 삭제되었습니다')),
        );
        Navigator.of(context).pop(true); // true를 반환하여 목록 새로고침
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 빈도 비율 수정 다이얼로그 표시
  Future<void> _showRatioEditDialog(
    String difficultyName,
    int currentValue,
    Function(int) onChanged, {
    required int minValue,
  }) async {
    final controller = TextEditingController(text: currentValue.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$difficultyName 빈도 비율'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: '빈도 비율을 입력하세요',
            helperText: '최소 $minValue배 이상',
            suffixText: '배',
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (_) {
            final value = int.tryParse(controller.text);
            if (value != null && value >= minValue) {
              Navigator.of(context).pop(value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value >= minValue) {
                Navigator.of(context).pop(value);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('최소 $minValue배 이상이어야 합니다'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (result != null && result >= minValue) {
      setState(() => onChanged(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.wordBook != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? '단어장 수정' : '새 단어장'),
        centerTitle: true,
        actions: [
          // 삭제 버튼 (수정 모드일 때만)
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _isLoading ? null : _handleDelete,
              tooltip: '삭제',
            ),
          // 저장 버튼
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _handleSave,
            tooltip: '저장',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          // 빈 화면 탭 시 키보드 내리기
          FocusScope.of(context).unfocus();
        },
        child: _isLoading
            ? const LoadingIndicator()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // 이름 입력
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: '이름',
                        hintText: '단어장 이름을 입력하세요',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '단어장 이름을 입력해주세요';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 설명 입력
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: '설명',
                        hintText: '단어장 설명을 입력하세요 (선택)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: AppSpacing.xxxl),

                    // 복습 빈도 설정 섹션
                    Row(
                      children: [
                        Text(
                          '복습 빈도 설정',
                          style: AppTextStyles.heading3,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('복습 빈도란?'),
                                content: const Text(
                                  '학습 세션에서 난이도별로 얼마나 자주 등장할지를 설정합니다.\n\n'
                                  '• 쉬움 (x1): 가장 적게 등장\n'
                                  '• 보통 (x3): 쉬움의 3배 등장\n'
                                  '• 어려움 (x6): 쉬움의 6배 등장\n\n'
                                  '예: 쉬움을 1번 볼 때, 어려움은 6번 등장합니다.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('확인'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Icon(
                            Icons.help_outline,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // 최소 배율 안내
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              '최소 배율: 쉬움 1배 이상, 보통 2배 이상, 어려움 3배 이상\n쉬움 < 보통 < 어려움 순서를 지켜주세요',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 난이도별 빈도 버튼
                    _buildRatioButton(
                      '쉬움 (최소 1배)',
                      _easyRatio,
                      AppColors.difficultyEasy.withValues(alpha: 0.2),
                      AppColors.difficultyEasy,
                      () => _showRatioEditDialog(
                        '쉬움',
                        _easyRatio,
                        (value) => _easyRatio = value,
                        minValue: 1,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    _buildRatioButton(
                      '보통 (최소 2배)',
                      _normalRatio,
                      AppColors.difficultyNormal.withValues(alpha: 0.2),
                      AppColors.difficultyNormal,
                      () => _showRatioEditDialog(
                        '보통',
                        _normalRatio,
                        (value) => _normalRatio = value,
                        minValue: 2,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    _buildRatioButton(
                      '어려움 (최소 3배)',
                      _hardRatio,
                      AppColors.difficultyHard.withValues(alpha: 0.2),
                      AppColors.difficultyHard,
                      () => _showRatioEditDialog(
                        '어려움',
                        _hardRatio,
                        (value) => _hardRatio = value,
                        minValue: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  /// 빈도 비율 설정 버튼 위젯
  Widget _buildRatioButton(
    String label,
    int ratio,
    Color bgColor,
    Color textColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: textColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.body1.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Row(
              children: [
                Text(
                  'x$ratio배',
                  style: AppTextStyles.heading3.copyWith(
                    color: textColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.edit, size: 20, color: textColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
