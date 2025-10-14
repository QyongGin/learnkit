import 'package:flutter/material.dart';
import '../models/card.dart' as model;

/// 단어 카드 위젯
/// 제목(질문), 이미지 영역, 설명(답), 난이도 설정을 포함하는 카드
class WordCard extends StatelessWidget {
  final String title; // 문제/단어 (긴 텍스트 가능)
  final String description; // 설명/답 (긴 텍스트 가능)
  final model.CardDifficulty? difficulty; // 현재 난이도
  final VoidCallback? onTap; // 카드 탭 이벤트
  final Function(model.CardDifficulty)? onDifficultyChanged; // 난이도 변경 콜백
  final Widget? imageWidget; // 커스텀 이미지 위젯 (나중에 사진 기능 구현시 사용)

  const WordCard({
    super.key,
    required this.title,
    required this.description,
    this.difficulty,
    this.onTap,
    this.onDifficultyChanged,
    this.imageWidget,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 제목 + 난이도 설정 버튼
            _buildHeader(context),

            // 이미지 영역 (나중에 사진 기능 추가 예정)
            _buildImageArea(),

            // 하단: 제목과 설명
            _buildContent(),
          ],
        ),
      ),
    );
  }

  /// 헤더 영역: 아바타 + 서브헤더 + 난이도 메뉴
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 왼쪽: 아바타 + 서브헤더
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE8DCFA), // 연한 보라색
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                title.isNotEmpty ? title[0].toUpperCase() : 'A',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B4FA0),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Word Card',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Subhead',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          // 오른쪽: 난이도 설정 메뉴 (점 세 개)
          PopupMenuButton<model.CardDifficulty>(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.black54,
            ),
            offset: const Offset(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (model.CardDifficulty value) {
              onDifficultyChanged?.call(value);
            },
            itemBuilder: (BuildContext context) => [
              _buildDifficultyMenuItem(
                model.CardDifficulty.EASY,
                '쉬움',
                Colors.green,
                '😊',
              ),
              _buildDifficultyMenuItem(
                model.CardDifficulty.NORMAL,
                '보통',
                Colors.orange,
                '😐',
              ),
              _buildDifficultyMenuItem(
                model.CardDifficulty.HARD,
                '어려움',
                Colors.red,
                '😰',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 난이도 선택 메뉴 아이템
  PopupMenuItem<model.CardDifficulty> _buildDifficultyMenuItem(
    model.CardDifficulty value,
    String label,
    Color color,
    String emoji,
  ) {
    final isSelected = difficulty == value;

    return PopupMenuItem<model.CardDifficulty>(
      value: value,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : Colors.black87,
              ),
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check_circle,
              color: color,
              size: 20,
            ),
        ],
      ),
    );
  }

  /// 이미지 영역 (현재는 플레이스홀더, 나중에 실제 이미지 기능 추가)
  Widget _buildImageArea() {
    return Container(
      height: 200,
      width: double.infinity,
      color: const Color(0xFFE8DCF0), // 연한 보라색 배경
      child: imageWidget ?? _buildImagePlaceholder(),
    );
  }

  /// 이미지 플레이스홀더 (아이콘 3개로 구성)
  Widget _buildImagePlaceholder() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 삼각형 아이콘
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFC8B6E2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 톱니바퀴 모양 아이콘
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFC8B6E2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFB8A0D8),
                    width: 8,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
          const SizedBox(width: 16),
          // 사각형 아이콘
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFC8B6E2),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }

  /// 하단 컨텐츠: 제목과 설명
  Widget _buildContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 (문제/단어) - 긴 텍스트 가능
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // 설명 (답/뜻) - 긴 텍스트 가능
          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// 난이도 뱃지 위젯 (다른 곳에서 사용 가능)
class DifficultyBadge extends StatelessWidget {
  final model.CardDifficulty difficulty;

  const DifficultyBadge({
    super.key,
    required this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getDifficultyConfig(difficulty);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config['color'].withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: config['color'].withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            config['emoji'],
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 6),
          Text(
            config['label'],
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: config['color'],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getDifficultyConfig(model.CardDifficulty difficulty) {
    switch (difficulty) {
      case model.CardDifficulty.EASY:
        return {
          'label': '쉬움',
          'color': Colors.green,
          'emoji': '😊',
        };
      case model.CardDifficulty.NORMAL:
        return {
          'label': '보통',
          'color': Colors.orange,
          'emoji': '😐',
        };
      case model.CardDifficulty.HARD:
        return {
          'label': '어려움',
          'color': Colors.red,
          'emoji': '😰',
        };
    }
  }
}
