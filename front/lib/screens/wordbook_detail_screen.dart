import 'package:flutter/material.dart';
import '../models/wordbook.dart';
import '../models/card.dart' as model;
import '../services/api_service.dart';
import 'card_form_screen.dart';

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

class _WordBookDetailScreenState extends State<WordBookDetailScreen> {
  List<model.Card> _cards = [];
  bool _isLoading = true;

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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
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
          widget.wordBook.title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadCards,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _cards.length,
                    itemBuilder: (context, index) {
                      final card = _cards[index];
                      return _buildCardItem(card);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCardForm(),
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
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
                // 헤더: 난이도 뱃지 + 삭제 버튼
                Row(
                  children: [
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
