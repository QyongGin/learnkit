import 'package:flutter/material.dart';
// dart:io - 파일 시스템 접근 (File 클래스)
import 'dart:io';
// image_picker: 갤러리/카메라에서 이미지 선택
import 'package:image_picker/image_picker.dart';
// logger: 콘솔 로깅 (디버깅용)
import 'package:logger/logger.dart';

import '../config/app_theme.dart';
import '../widgets/common_widgets.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

final logger = Logger();

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

  // 이미지 업로드 관련 변수
  File? _selectedImage; // 선택한 이미지 파일
  bool _isUploading = false; // 업로드 상태
  String? _profileImageUrl; // Supabase에서 받은 이미지 URL
  bool _imageLoadError = false; // 이미지 로딩 에러 여부
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
      _imageLoadError = false;
    });

    try {
      // AuthService에서 userId 가져오기
      final authService = await AuthService.getInstance();
      _userId = authService.currentUserId;

      // 사용자 정보 로드
      final user = await ApiService.fetchUserById(_userId);

      // DB에 저장된 프로필 이미지 URL 가져오기
      if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
        _profileImageUrl = user.profileImageUrl;
      }

      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      logger.e('프로필 로드 실패', error: e);
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('프로필', style: AppTextStyles.heading2),
        centerTitle: false,
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserCard(),
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
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: AppDecorations.card,
      child: Column(
        children: [
          _buildProfileImage(),
          const SizedBox(height: AppSpacing.lg),

          Text(
            _user?.nickname ?? '사용자',
            style: AppTextStyles.heading1,
          ),
          const SizedBox(height: AppSpacing.xs),

          Text(
            _user?.email ?? '',
            style: AppTextStyles.body2,
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
            gradient: (_selectedImage == null && _profileImageUrl == null) || _imageLoadError
                ? const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  )
                : null,
          ),
          child: _buildProfileImageContent(),
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

  /// 프로필 이미지 내용 (이미지 또는 이니셜)
  Widget _buildProfileImageContent() {
    // 선택한 이미지가 있으면 표시
    if (_selectedImage != null) {
      return ClipOval(
        child: Image.file(
          _selectedImage!,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      );
    }
    
    // URL 이미지가 있고 에러가 없으면 네트워크 이미지 표시
    if (_profileImageUrl != null && !_imageLoadError) {
      return ClipOval(
        child: Image.network(
          _profileImageUrl!,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            logger.e('이미지 로드 실패', error: error);
            // 에러 발생 시 이니셜 표시
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _imageLoadError = true);
              }
            });
            return _buildInitialAvatar();
          },
        ),
      );
    }
    
    // 이미지가 없으면 이니셜 표시
    return _buildInitialAvatar();
  }

  /// 이니셜 아바타
  Widget _buildInitialAvatar() {
    return Center(
      child: Text(
        _user?.nickname.isNotEmpty == true 
            ? _user!.nickname.substring(0, 1).toUpperCase() 
            : 'U',
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
