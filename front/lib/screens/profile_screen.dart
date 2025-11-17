import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'package:logger/logger.dart'; // logger 패키지 
import 'dart:io'; // 파일 처리 (이미지 파일 다루기)
import 'package:image_picker/image_picker.dart'; // 이미지 선택 (갤러리/카메라)';
import '../services/supabase_service.dart'; // Supabase 업로드 서비스 

final logger = Logger(); // logger 인스턴스 try-catch 예외용

/// 프로필 화면 
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  // dart에서 "_"는 private을 의미함.
  User? _user;
  bool _isLoading = true;
  int _userId = 1;

  // 통계 데이터
  int _totalWordBooks = 0;
  int _totalCards = 0;
  int _easyCards = 0;
  int _normalCards = 0;
  int _hardCards = 0;

  // 이미지 업로드 관련 변수 추가
  File? _selectedImage; // 선택한 이미지 파일. "?"는 nullable. null을 가질 수 있다는 의미.
  bool _isUploading = false; // 업로드 상태
  String? _profileImageUrl; // Supabase에서 받은 이미지 URL
  final ImagePicker _picker = ImagePicker(); // 갤러리/카메라 열기 도구

  /// 갤러리에서 이미지 선택
  // Future: 끝나지 않는 오래된 작업 진행 시 사용. 앱이 멈추는 현상(UI 멈춤)을 막기 위해서.
  // Future는 async, await을 통해 사용한다.   
  Future<void> _pickImage() async {
    try {
      // 갤러리에서 이미지 선택
      // ImageSource.camera로 변경하면 카메라 사용
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery, // 갤러리 열기)
        maxWidth: 1024, // 최대 너비
        maxHeight: 1024, // 최대 높이
        imageQuality: 85, // 이미지 품질 (0~100)
      );

      // 선택 취소 시 
      if (image == null) return;

      // 선택한 이미지 저장
      setState(() {
        _selectedImage = File(image.path);
      });

      // 이미지 선택 즉시 업로드
      await _uploadImage();
    } catch(e, stackTrace) { // 'e' 에러와 'stackTrace' 에러 위치 받기
      logger.e(
        '이미지 선택 실패', // 무슨 작업하다 실패했는지 메시지 
        error:e,  // error: 잡힌 에러 객체(e)
        stackTrace: stackTrace // stackTrace: 에러 발생 코드 위치 
      );
    }
  }

  /// Supabase에 이미지 업로드
  Future<void> _uploadImage() async {
    // 선택한 이미지 없으면 종료
    if (_selectedImage == null) return;

    // 업로드 시작 (로딩 스피너 표시)
    setState(() {
      _isUploading = true; // 업로드 시작 (로딩 표시)
    });

    try {
      // 1. Supabase Storage에 업로드
      final String imageUrl = await SupabaseService.uploadProfileImage( // Supabase에 업로드 
        userId: _userId.toString(),
        imageFile: _selectedImage!, // '?'의 반대. null-check operator로서, 이 코드 실행 시점에서 무조건 null이라 보장하고 선언한 클래스 타입(File)취급 
      );

      logger.i('업로드 성공 URL: $imageUrl'); // 디버그 콘솔 창에 출력

      // 2. 백엔드 DB에 URL 저장 (기존 updateProfile API 사용)
      final updatedUser = await ApiService.updateProfile(
        userId: _userId,
        profileImageUrl: imageUrl,
      );
      logger.i('백엔드 DB 저장 성공');

      // 3. 업데이트된 사용자 정보 반영
      setState(() {
        _user = updatedUser; // 백엔드에서 받은 최신 사용자 정보로 업데이트
        _profileImageUrl = imageUrl;
      });

      // 3. 성공 메시지 표시
      if (mounted) {
        // ScaffoldMessenger: 화면 하단에 성공/실패 메시지 출력
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필 이미지 업데이트 완료')),
        );
      }

    } catch (e,stackTrace) {
      logger.e(
        '업로드 실패',
        error:e,
        stackTrace: stackTrace
      );
      // 에러 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('업로드 실패: $e')),
        );
      }
    } finally { // 성공/실패 관계없이 로딩 종료
      // 업로드 종료 (로딩 스피너 숨김)
      setState(() {
        _isUploading = false;
      });
    }
  }

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

      // DB에 저장된 프로필 이미지 URL 가져오기
      if (user.profileImageUrl != null) {
        setState(() {
          _profileImageUrl = user.profileImageUrl;
        });
      }

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
          _buildProfileImage(),
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

  /// 프로필 이미지 위젯 (클릭 가능)
Widget _buildProfileImage() {
  return GestureDetector(
    onTap: _isUploading ? null : _pickImage, // 업로드 중엔 비활성화
    child: Stack(
      children: [
        // 프로필 이미지 표시
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _selectedImage == null && _profileImageUrl == null
                ? const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  )
                : null,
            image: _selectedImage != null || _profileImageUrl != null
                ? DecorationImage(
                    image: _selectedImage != null
                        ? FileImage(_selectedImage!) // 선택한 이미지
                        : NetworkImage(_profileImageUrl!) as ImageProvider, // URL 이미지
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _selectedImage == null && _profileImageUrl == null
              ? Center(
                  child: Text(
                    _user?.nickname.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                )
              : null,
        ),
        
        // 업로드 중 로딩 표시
        if (_isUploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        
        // 카메라 아이콘 (편집 가능 표시)
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.camera_alt,
              color: Colors.white,
              size: 16,
            ),
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
