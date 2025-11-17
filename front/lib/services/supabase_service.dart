// Supabase = 창고 (이미지를 저장하는 곳)
// SupabaseService.dart 배달부 - 이미지를 창고에 넣고 빼는 역할 

// Supabase Flutter SDK (Storage, Auth 포함)
import 'package:supabase_flutter/supabase_flutter.dart';
// 파일 처리
import 'dart:io';

/// Supabase Storage 서비스
/// - 프로필 이미지 업로드
/// - Public URL 생성
/// - 파일 삭제 
class SupabaseService {
  // Supabase 클라이언트 인스턴스
  static final SupabaseClient _client = Supabase.instance.client;

  // Storage 버킷 이름
  static const String _profileBucket = 'learnkit-profile';

  /// 프로필 이미지 업로드
  /// 
  /// 매개변수:
  /// - userId: 사용자 ID (폴더명)
  /// - imageFile: 업로드할 이미지 파일
  /// 
  /// 반환값:
  /// - Public URL (https://xxx.supabase.co/stroage/...)
  static Future<String> uploadProfileImage({
    // Future<String>: 비동기 함수, 완료 시 String(URL) 반환

    required String userId, // required: NotNull. 무조건 값이 필요
    required File imageFile,
  }) async {
    // 파일 경로: userId/profile.jpg
    final String fileName = 'profile.jpg';
    final String filePath = '$userId/$fileName';

    // Supabase Storage에 업로드 
    // upsert: true - 같은 파일명이 있으면 덮어쓰기
    await _client.storage
        .from(_profileBucket)
        .upload(
          filePath,
          imageFile,
          fileOptions: const FileOptions(
            upsert: true,
           ),
        );

    // Public URL 생성 및 반환
    final String publicUrl = _client.storage
        .from(_profileBucket)
        .getPublicUrl(filePath);

    return publicUrl;
  }

  /// 프로필 이미지 삭제
  /// 
  /// 매개변수:
  /// - userId: 사용자 ID
  static Future<void> deleteProfileImage(String userId) async {
    final String filePath = '$userId/profile.jpg';

    await _client.storage
        .from(_profileBucket)
        .remove([filePath]);
  }
}