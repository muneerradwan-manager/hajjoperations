class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    this.body,
    this.readAt,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? body;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
    id: map['id'] as String,
    title: map['title'] as String,
    body: map['body'] as String?,
    readAt: map['read_at'] == null
        ? null
        : DateTime.parse(map['read_at'] as String),
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}
