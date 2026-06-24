class NotificationModel {
  final String id;
  final int userId;
  final String title;
  final String content;
  final String type; // success | security | info | warning
  bool isRead;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'content': content,
    'type': type,
    'is_read': isRead ? 1 : 0,
    'created_at': createdAt,
  };

  factory NotificationModel.fromMap(Map<String, dynamic> m) => NotificationModel(
    id: m['id'] as String,
    userId: m['user_id'] as int,
    title: m['title'] as String,
    content: m['content'] as String,
    type: m['type'] as String? ?? 'info',
    isRead: (m['is_read'] as int? ?? 0) == 1,
    createdAt: m['created_at'] as String,
  );

  DateTime get timestamp => DateTime.parse(createdAt);
}
