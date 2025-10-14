/// 스케줄/할 일 모델 (백엔드 API 스펙에 맞춤)
class Schedule {
  final int id;
  final int userId;
  final String title;
  final String? description;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Schedule({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.startTime,
    this.endTime,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId: json['userId'] != null
          ? (json['userId'] is int ? json['userId'] : int.parse(json['userId'].toString()))
          : 1, // 기본값
      title: json['title'] ?? '',
      description: json['description'],
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      isCompleted: json['completed'] ?? json['isCompleted'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  /// 백엔드로 보낼 JSON (생성/수정용 - id, userId, timestamps 제외)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }
}
