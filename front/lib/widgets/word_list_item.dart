import 'package:flutter/material.dart';
import '../models/card.dart' as model;

/// 단어 목록에서 사용하는 작은 카드 아이템
/// 단어장에 100개 이상의 단어를 효율적으로 표시
class WordListItem extends StatelessWidget {
  final String frontText; // 단어/질문
  final String backText; // 뜻/답
  final model.CardDifficulty? difficulty; // 난이도
  final DateTime? nextReviewAt; // 다음 복습 시간
  final VoidCallback? onTap; // 탭하면 상세보기
  final VoidCallback? onEdit; // 수정 버튼
  final VoidCallback? onDelete; // 삭제 버튼

  const WordListItem({
    super.key,
    required this.frontText,
    required this.backText,
    this.difficulty,
    this.nextReviewAt,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 왼쪽: 난이도 인디케이터
            _buildDifficultyIndicator(),
            const SizedBox(width: 12),

            // 중앙: 단어 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 앞면 텍스트 (단어/질문)
                  Text(
                    frontText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // 뒷면 텍스트 (뜻/답) - 미리보기
                  Text(
                    backText,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // 다음 복습 시간 표시
                  if (nextReviewAt != null) ...[
                    const SizedBox(height: 6),
                    _buildNextReviewBadge(),
                  ],
                ],
              ),
            ),

            // 오른쪽: 액션 버튼들
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: onEdit,
                    color: const Color(0xFF4A90E2),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                    color: Colors.red[400],
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 난이도 인디케이터 (왼쪽 색상 바)
  Widget _buildDifficultyIndicator() {
    Color color;
    String emoji;

    switch (difficulty) {
      case model.CardDifficulty.EASY:
        color = const Color(0xFF4CAF50); // 푸른 초록
        emoji = '😊';
        break;
      case model.CardDifficulty.NORMAL:
        color = const Color(0xFF4A90E2); // 파란색
        emoji = '😐';
        break;
      case model.CardDifficulty.HARD:
        color = const Color(0xFF9C27B0); // 보라색
        emoji = '😰';
        break;
      default:
        color = Colors.grey[300]!;
        emoji = '❓';
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  /// 다음 복습 시간 뱃지
  Widget _buildNextReviewBadge() {
    final now = DateTime.now();
    final difference = nextReviewAt!.difference(now);
    final isOverdue = difference.isNegative;

    String displayText;
    Color badgeColor;

    if (isOverdue) {
      displayText = '복습 필요';
      badgeColor = const Color(0xFFE57373); // 연한 빨강
    } else if (difference.inDays > 0) {
      displayText = '${difference.inDays}일 후';
      badgeColor = const Color(0xFF81C784); // 연한 초록
    } else if (difference.inHours > 0) {
      displayText = '${difference.inHours}시간 후';
      badgeColor = const Color(0xFF4A90E2); // 파랑
    } else {
      displayText = '${difference.inMinutes}분 후';
      badgeColor = const Color(0xFFFFB74D); // 주황
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue ? Icons.alarm_on : Icons.schedule,
            size: 12,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            displayText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}
