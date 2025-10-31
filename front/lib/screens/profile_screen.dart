import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

/// 프로필 화면 (Toss 스타일)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;
  int _userId = 1;

  // 통계 데이터
  int _totalWordBooks = 0;
  int _totalCards = 0;
  int _easyCards = 0;
  int _normalCards = 0;
  int _hardCards = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // AuthService에서 userId 가져오기
      final authService = await AuthService.getInstance();
      _userId = authService.currentUserId;

      // 사용자 정보 로드
      final user = await ApiService.fetchUserById(_userId);

      // 단어장 통계 로드
      final wordBooks = await ApiService.fetchWordBooks(_userId);

      int totalCards = 0;
      int easy = 0;
      int normal = 0;
      int hard = 0;

      for (var wordBook in wordBooks) {
        final stats = await ApiService.fetchWordBookStatistics(wordBook.id);
        totalCards += stats.totalCount;
        easy += stats.easyCount;
        normal += stats.normalCount;
        hard += stats.hardCount;
      }

      setState(() {
        _user = user;
        _totalWordBooks = wordBooks.length;
        _totalCards = totalCards;
        _easyCards = easy;
        _normalCards = normal;
        _hardCards = hard;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필을 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '프로필',
          style: TextStyle(
            color: Color(0xFF191F28),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 사용자 정보 카드
                    _buildUserCard(),
                    const SizedBox(height: 24),

                    // 학습 통계 섹션
                    const Text(
                      '학습 통계',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF191F28),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 단어장/카드 통계
                    _buildStatsCard(),
                    const SizedBox(height: 12),

                    // 난이도별 통계
                    _buildDifficultyStats(),
                  ],
                ),
              ),
            ),
    );
  }

  /// 사용자 정보 카드
  Widget _buildUserCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 프로필 아이콘
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _user?.nickname.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 닉네임
          Text(
            _user?.nickname ?? '사용자',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF191F28),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),

          // 이메일
          Text(
            _user?.email ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// 단어장/카드 통계 카드
  Widget _buildStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              label: '단어장',
              value: '$_totalWordBooks',
              color: const Color(0xFF6366F1),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade200,
          ),
          Expanded(
            child: _buildStatItem(
              label: '총 카드',
              value: '$_totalCards',
              color: const Color(0xFF8B5CF6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  /// 난이도별 통계
  Widget _buildDifficultyStats() {
    return Column(
      children: [
        _buildDifficultyCard(
          label: '쉬움',
          count: _easyCards,
          color: const Color(0xFF20C997),
          icon: Icons.sentiment_satisfied_alt,
        ),
        const SizedBox(height: 12),
        _buildDifficultyCard(
          label: '보통',
          count: _normalCards,
          color: const Color(0xFF3182F6),
          icon: Icons.sentiment_neutral,
        ),
        const SizedBox(height: 12),
        _buildDifficultyCard(
          label: '어려움',
          count: _hardCards,
          color: const Color(0xFFFF6B6B),
          icon: Icons.sentiment_dissatisfied,
        ),
      ],
    );
  }

  Widget _buildDifficultyCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    final percentage = _totalCards > 0
        ? (count / _totalCards * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // 아이콘
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // 라벨과 카운트
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count개 · $percentage%',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),

          // 진행 바
          SizedBox(
            width: 60,
            child: LinearProgressIndicator(
              value: _totalCards > 0 ? count / _totalCards : 0,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              borderRadius: BorderRadius.circular(4),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
