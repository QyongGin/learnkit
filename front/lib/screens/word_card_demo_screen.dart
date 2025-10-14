import 'package:flutter/material.dart';
import '../models/card.dart' as model;
import '../widgets/word_card.dart';

/// 단어 카드 데모 화면
/// WordCard 위젯의 사용 예제를 보여줍니다
class WordCardDemoScreen extends StatefulWidget {
  const WordCardDemoScreen({super.key});

  @override
  State<WordCardDemoScreen> createState() => _WordCardDemoScreenState();
}

class _WordCardDemoScreenState extends State<WordCardDemoScreen> {
  // 샘플 카드 데이터
  final List<Map<String, dynamic>> _cards = [
    {
      'title': 'Photosynthesis',
      'description': 'The process by which green plants use sunlight to synthesize nutrients from carbon dioxide and water.',
      'difficulty': model.CardDifficulty.EASY,
    },
    {
      'title': '광합성 (Photosynthesis) - 식물이 빛 에너지를 화학 에너지로 변환하는 과정',
      'description': '광합성은 식물, 조류 및 일부 박테리아가 빛 에너지를 사용하여 이산화탄소와 물을 포도당과 산소로 변환하는 과정입니다. 이 과정은 엽록소가 있는 엽록체에서 일어나며, 지구상의 거의 모든 생명체에게 에너지를 제공하는 가장 중요한 생물학적 과정 중 하나입니다.',
      'difficulty': model.CardDifficulty.NORMAL,
    },
    {
      'title': 'What is the Heisenberg Uncertainty Principle?',
      'description': 'The Heisenberg Uncertainty Principle states that it is impossible to simultaneously know both the exact position and exact momentum of a particle. This is a fundamental concept in quantum mechanics, showing that at the quantum level, there are inherent limits to the precision with which certain pairs of physical properties can be known. The more precisely one property is measured, the less precisely the other can be controlled or determined.',
      'difficulty': model.CardDifficulty.HARD,
    },
    {
      'title': 'Hello',
      'description': 'A common greeting',
      'difficulty': null, // 난이도가 설정되지 않은 경우
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('단어 카드 예제'),
        backgroundColor: const Color(0xFF6B4FA0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: _cards.length,
        itemBuilder: (context, index) {
          final card = _cards[index];
          return WordCard(
            title: card['title'],
            description: card['description'],
            difficulty: card['difficulty'],
            onTap: () {
              _showCardDetail(context, card);
            },
            onDifficultyChanged: (newDifficulty) {
              setState(() {
                _cards[index]['difficulty'] = newDifficulty;
              });
              _showSnackBar('난이도가 변경되었습니다: ${_getDifficultyLabel(newDifficulty)}');
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewCard,
        backgroundColor: const Color(0xFF6B4FA0),
        icon: const Icon(Icons.add),
        label: const Text('새 카드'),
      ),
    );
  }

  /// 카드 상세 정보 다이얼로그
  void _showCardDetail(BuildContext context, Map<String, dynamic> card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('카드 상세'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '제목:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(card['title']),
            const SizedBox(height: 16),
            Text(
              '설명:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(card['description']),
            const SizedBox(height: 16),
            if (card['difficulty'] != null) ...[
              Text(
                '난이도:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              DifficultyBadge(difficulty: card['difficulty']),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  /// 새 카드 추가 (예제)
  void _addNewCard() {
    setState(() {
      _cards.add({
        'title': 'New Card ${_cards.length + 1}',
        'description': 'This is a new card description',
        'difficulty': model.CardDifficulty.NORMAL,
      });
    });
    _showSnackBar('새 카드가 추가되었습니다');
  }

  /// 스낵바 표시
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 난이도 라벨 가져오기
  String _getDifficultyLabel(model.CardDifficulty difficulty) {
    switch (difficulty) {
      case model.CardDifficulty.EASY:
        return '쉬움';
      case model.CardDifficulty.NORMAL:
        return '보통';
      case model.CardDifficulty.HARD:
        return '어려움';
    }
  }
}
