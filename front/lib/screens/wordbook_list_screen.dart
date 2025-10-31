import 'package:flutter/material.dart';
import '../models/wordbook.dart';
import '../services/api_service.dart';
import '../widgets/wordbook_card.dart';
import 'wordbook_form_screen.dart';
import 'wordbook_detail_screen.dart';

/// 단어장 목록 화면
class WordBookListScreen extends StatefulWidget {
  const WordBookListScreen({super.key});

  @override
  State<WordBookListScreen> createState() => _WordBookListScreenState();
}

class _WordBookListScreenState extends State<WordBookListScreen> {
  List<WordBook> _wordBooks = [];
  bool _isLoading = true;
  String? _errorMessage;
  final int _userId = 1; // TODO: 실제 로그인한 사용자 ID로 변경

  @override
  void initState() {
    super.initState();
    _loadWordBooks();
  }

  /// 단어장 목록 로드
  Future<void> _loadWordBooks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final wordBooks = await ApiService.fetchWordBooks(_userId);

      // 각 단어장의 통계 데이터 로드
      final wordBooksWithStats = await Future.wait(
        wordBooks.map((wordBook) async {
          final statistics = await ApiService.fetchWordBookStatistics(wordBook.id);
          return wordBook.copyWithStatistics(statistics);
        }),
      );

      setState(() {
        _wordBooks = wordBooksWithStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 새 단어장 추가 화면으로 이동
  Future<void> _showAddWordBookDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const WordBookFormScreen(),
      ),
    );

    // 폼에서 저장/삭제가 완료되면 true 반환, 목록 새로고침
    if (result == true) {
      await _loadWordBooks();
    }
  }

  /// 단어장 메뉴 표시 (수정)
  void _showWordBookMenu(WordBook wordBook) {
    // 수정 화면으로 바로 이동 (폼 화면에서 삭제 버튼도 제공)
    _showEditWordBookDialog(wordBook);
  }

  /// 단어장 수정 화면으로 이동
  Future<void> _showEditWordBookDialog(WordBook wordBook) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => WordBookFormScreen(wordBook: wordBook),
      ),
    );

    // 폼에서 저장/삭제가 완료되면 true 반환, 목록 새로고침
    if (result == true) {
      await _loadWordBooks();
    }
  }

  /// 단어장 카드 탭 (상세 화면으로 이동)
  Future<void> _onWordBookTap(WordBook wordBook) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordBookDetailScreen(wordBook: wordBook),
      ),
    );
    // 상세 화면에서 돌아왔을 때 목록 새로고침
    _loadWordBooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '단어장',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        actions: [
          // 추가 버튼
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black87),
            onPressed: _showAddWordBookDialog,
            tooltip: '단어장 추가',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '오류가 발생했습니다',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadWordBooks,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_wordBooks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              '단어장이 없습니다',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '오른쪽 상단의 + 버튼을 눌러\n새 단어장을 만들어보세요',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWordBooks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _wordBooks.length,
        itemBuilder: (context, index) {
          final wordBook = _wordBooks[index];
          return Padding(
            padding: EdgeInsets.only(bottom: index < _wordBooks.length - 1 ? 12 : 0),
            child: WordBookCard(
              wordBook: wordBook,
              onTap: () => _onWordBookTap(wordBook),
              onMenuTap: () => _showWordBookMenu(wordBook),
            ),
          );
        },
      ),
    );
  }
}
