import 'package:flutter/material.dart';
import '../models/wordbook.dart';
import '../models/card.dart' as model;
import '../services/api_service.dart';
import 'card_form_screen.dart';
import 'study_session_screen.dart';

/// 단어장 상세 화면 - 카드 목록
class WordBookDetailScreen extends StatefulWidget {
  final WordBook wordBook;

  const WordBookDetailScreen({
    super.key,
    required this.wordBook,
  });

  @override
  State<WordBookDetailScreen> createState() => _WordBookDetailScreenState();
}

enum SortType {
  difficulty, // 난이도순
  viewCount, // 복습횟수순
}

class _WordBookDetailScreenState extends State<WordBookDetailScreen> {
  List<model.Card> _cards = [];
  bool _isLoading = true;
  SortType _currentSort = SortType.difficulty;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cards = await ApiService.fetchCards(widget.wordBook.id);
      setState(() {
        _cards = cards;
        _sortCards();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sortCards() {
    if (_currentSort == SortType.difficulty) {
      // 난이도순: HARD > NORMAL > EASY (어려운 것부터)
      _cards.sort((a, b) {
        final aValue = _getDifficultyValue(a.difficulty);
        final bValue = _getDifficultyValue(b.difficulty);
        return bValue.compareTo(aValue);
      });
    } else {
      // 복습횟수순: 많이 본 것부터
      _cards.sort((a, b) => b.viewCount.compareTo(a.viewCount));
    }
  }

  int _getDifficultyValue(model.CardDifficulty? difficulty) {
    switch (difficulty) {
      case model.CardDifficulty.HARD:
        return 3;
      case model.CardDifficulty.NORMAL:
        return 2;
      case model.CardDifficulty.EASY:
        return 1;
      default:
        return 0;
    }
  }

  void _changeSortType(SortType newSort) {
    if (_currentSort != newSort) {
      setState(() {
        _currentSort = newSort;
        _sortCards();
      });
    }
  }

  Future<void> _navigateToCardForm([model.Card? card]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardFormScreen(
          wordBookId: widget.wordBook.id,
          card: card,
        ),
      ),
    );

    if (result == true) {
      _loadCards();
    }
  }

  Future<void> _deleteCard(model.Card card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('카드 삭제'),
        content: const Text('이 카드를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteCard(card.id);
        _loadCards();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('카드가 삭제되었습니다')),
          );
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
      }
    }
  }

  Color _getDifficultyColor(model.CardDifficulty? difficulty) {
    switch (difficulty) {
      case model.CardDifficulty.EASY:
        return const Color(0xFF20C997);
      case model.CardDifficulty.NORMAL:
        return const Color(0xFF3182F6);
      case model.CardDifficulty.HARD:
        return const Color(0xFFFF6B6B);
      default:
        return Colors.grey;
    }
  }

  String _getDifficultyLabel(model.CardDifficulty? difficulty) {
    switch (difficulty) {
      case model.CardDifficulty.EASY:
        return '쉬움';
      case model.CardDifficulty.NORMAL:
        return '보통';
      case model.CardDifficulty.HARD:
        return '어려움';
      default:
        return '-';
    }
  }

  /// 학습 세션 시작
  void _startStudySession() {
    if (_cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('학습할 카드가 없습니다')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudySessionScreen(wordBook: widget.wordBook),
      ),
    ).then((_) {
      // 학습 완료 후 카드 목록 새로고침
      _loadCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.wordBook.title,
          style: const TextStyle(
            color: Color(0xFF191F28),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // 학습 시작 버튼
                    _buildStudyButton(),

                    // 정렬 필터
                    _buildSortFilter(),

                    // 카드 목록
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadCards,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                          itemCount: _cards.length,
                          itemBuilder: (context, index) {
                            final card = _cards[index];
                            return _buildCardItem(card);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCardForm(),
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// 정렬 필터 (토스 스타일)
  Widget _buildSortFilter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _buildSortChip(
            label: '난이도순',
            isSelected: _currentSort == SortType.difficulty,
            onTap: () => _changeSortType(SortType.difficulty),
          ),
          const SizedBox(width: 8),
          _buildSortChip(
            label: '복습횟수순',
            isSelected: _currentSort == SortType.viewCount,
            onTap: () => _changeSortType(SortType.viewCount),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF191F28) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF191F28) : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }

  /// 학습 시작 버튼 (토스 스타일)
  Widget _buildStudyButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _startStudySession,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle_filled, size: 26, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    '학습 시작',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_cards.length}개',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.style_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '카드가 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '+ 버튼을 눌러 첫 카드를 추가해보세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(model.Card card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToCardForm(card),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더: 난이도 뱃지 + 복습횟수 뱃지 + 삭제 버튼
                Row(
                  children: [
                    // 난이도 뱃지
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(card.difficulty)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getDifficultyLabel(card.difficulty),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getDifficultyColor(card.difficulty),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 복습횟수 뱃지
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.remove_red_eye_outlined,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${card.viewCount}회',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _deleteCard(card),
                      child: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 앞면 (질문)
                Text(
                  card.frontText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // 뒷면 (답변)
                Text(
                  card.backText,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
