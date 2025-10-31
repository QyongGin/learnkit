/// 사용자 모델
class User {
  final int id;
  final String email;
  final String nickname;
  final String? profileImageUrl;

  User({
    required this.id,
    required this.email,
    required this.nickname,
    this.profileImageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      email: json['email'] ?? '',
      nickname: json['nickname'] ?? '',
      profileImageUrl: json['profileImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
    };
  }
}
