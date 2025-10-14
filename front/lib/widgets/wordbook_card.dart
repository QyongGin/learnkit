import 'package:flutter/material.dart';
import '../models/wordbook.dart';

/// 단어장 카드 위젯 - 토스 스타일
class WordBookCard extends StatelessWidget {
  final WordBook wordBook;
  final VoidCallback onTap;
  final VoidCallback? onMenuTap;

  const WordBookCard({
    super.key,
    required this.wordBook,
    required this.onTap,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final statistics = wordBook.statistics;
    final totalCount = statistics?.totalCount ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 헤더: 제목과 메뉴
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        wordBook.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onMenuTap != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onMenuTap,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.more_vert,
                            size: 18,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 32),

                // 통계 - 간결한 스타일
                if (totalCount > 0) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (statistics!.easyCount > 0)
                        _buildStatBadge(
                          statistics.easyCount,
                          '쉬움',
                          const Color(0xFF20C997),
                        ),
                      if (statistics.normalCount > 0)
                        _buildStatBadge(
                          statistics.normalCount,
                          '보통',
                          const Color(0xFF3182F6),
                        ),
                      if (statistics.hardCount > 0)
                        _buildStatBadge(
                          statistics.hardCount,
                          '어려움',
                          const Color(0xFFFF6B6B),
                        ),
                    ],
                  ),
                ] else ...[
                  Text(
                    '단어를 추가해보세요',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 간결한 통계 뱃지
  Widget _buildStatBadge(int count, String label, Color color) {
    if (count == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
