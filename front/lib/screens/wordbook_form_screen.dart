import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/wordbook.dart';
import '../services/api_service.dart';

/// 단어장 생성/수정 화면
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

  // 난이도별 복습 간격 (분) - 기본값: 어려움 3분, 보통 10분, 쉬움 20분
  int _easyInterval = 20;
  int _normalInterval = 10;
  int _hardInterval = 3;

  final int _userId = 1; // TODO: 실제 로그인한 사용자 ID로 변경
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 수정 모드인 경우 기존 데이터로 초기화
    if (widget.wordBook != null) {
      _titleController.text = widget.wordBook!.title;
      _easyInterval = widget.wordBook!.easyIntervalMinutes;
      _normalInterval = widget.wordBook!.normalIntervalMinutes;
      _hardInterval = widget.wordBook!.hardIntervalMinutes;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// 저장 버튼 클릭
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.wordBook == null) {
        // 생성 모드
        await ApiService.createWordBook(
          userId: _userId,
          title: _titleController.text,
          easyIntervalMinutes: _easyInterval,
          normalIntervalMinutes: _normalInterval,
          hardIntervalMinutes: _hardInterval,
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
          easyIntervalMinutes: _easyInterval,
          normalIntervalMinutes: _normalInterval,
          hardIntervalMinutes: _hardInterval,
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

  /// 간격 수정 다이얼로그 표시
  Future<void> _showIntervalEditDialog(
    String difficultyName,
    int currentValue,
    Function(int) onChanged,
  ) async {
    final controller = TextEditingController(text: currentValue.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$difficultyName 복습 간격'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            hintText: '분 단위로 입력하세요',
            suffixText: '분',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (_) {
            final value = int.tryParse(controller.text);
            Navigator.of(context).pop(value);
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
              Navigator.of(context).pop(value);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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

                    const SizedBox(height: 16),

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

                    const SizedBox(height: 32),

                    // 복습 간격 설정 섹션
                    Row(
                      children: [
                        Text(
                          '복습 간격 설정',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('복습 간격이란?'),
                                content: const Text(
                                  '단어 학습 후 난이도에 따라 다음 복습 시간이 자동으로 설정됩니다.\n\n'
                                  '• 쉬움: 오래 기억할 수 있는 단어\n'
                                  '• 보통: 적당히 기억할 수 있는 단어\n'
                                  '• 어려움: 자주 복습이 필요한 단어',
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
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 난이도별 간격 버튼
                    _buildIntervalButton(
                      '쉬움',
                      _easyInterval,
                      Colors.green.shade100,
                      Colors.green.shade700,
                      () => _showIntervalEditDialog(
                        '쉬움',
                        _easyInterval,
                        (value) => _easyInterval = value,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildIntervalButton(
                      '보통',
                      _normalInterval,
                      Colors.blue.shade100,
                      Colors.blue.shade700,
                      () => _showIntervalEditDialog(
                        '보통',
                        _normalInterval,
                        (value) => _normalInterval = value,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildIntervalButton(
                      '어려움',
                      _hardInterval,
                      Colors.red.shade100,
                      Colors.red.shade700,
                      () => _showIntervalEditDialog(
                        '어려움',
                        _hardInterval,
                        (value) => _hardInterval = value,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// 간격 설정 버튼 위젯
  Widget _buildIntervalButton(
    String label,
    int minutes,
    Color bgColor,
    Color textColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Row(
              children: [
                Text(
                  '$minutes분',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.edit, size: 20, color: textColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
