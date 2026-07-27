/// What an attachment is, decided when it is attached rather than guessed from
/// the file name afterwards. Mirrors the `attachment_kind` enum (0031).
enum AttachmentKind {
  image,
  video,
  audio,
  file;

  static AttachmentKind fromDb(String? value) => switch (value) {
    'image' => AttachmentKind.image,
    'video' => AttachmentKind.video,
    'audio' => AttachmentKind.audio,
    _ => AttachmentKind.file,
  };

  /// Whether the app can show this itself. An image it can; a video, a voice
  /// note and a document are handed to whatever the device plays them with.
  bool get isViewableInApp => this == AttachmentKind.image;
}

/// A photo, a video, a voice note or a document sent with a notification.
///
/// [path] points into the private `notifications` bucket; nothing is readable
/// from it without a signed URL, minted on demand for the recipient.
class NotificationAttachment {
  const NotificationAttachment({
    required this.id,
    required this.kind,
    required this.path,
    required this.name,
    this.mimeType,
    this.sizeBytes,
  });

  final String id;
  final AttachmentKind kind;
  final String path;
  final String name;
  final String? mimeType;
  final int? sizeBytes;

  /// "1.4 MB". Null when the size was not recorded, which reads better as
  /// nothing at all than as "0 B".
  String? get readableSize {
    final bytes = sizeBytes;
    if (bytes == null || bytes <= 0) return null;
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
  }

  factory NotificationAttachment.fromMap(Map<String, dynamic> map) =>
      NotificationAttachment(
        id: map['id'] as String,
        kind: AttachmentKind.fromDb(map['kind'] as String?),
        path: map['path'] as String,
        name: map['name'] as String,
        mimeType: map['mime_type'] as String?,
        sizeBytes: (map['size_bytes'] as num?)?.toInt(),
      );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    this.body,
    this.readAt,
    required this.createdAt,
    this.attachments = const [],
  });

  final String id;
  final String title;
  final String? body;
  final DateTime? readAt;
  final DateTime createdAt;

  /// What came with it. Fetched alongside rather than embedded: the inbox is a
  /// realtime stream, and a stream cannot carry a joined table.
  final List<NotificationAttachment> attachments;

  bool get isRead => readAt != null;

  List<NotificationAttachment> get images =>
      attachments.where((a) => a.kind == AttachmentKind.image).toList();

  List<NotificationAttachment> get others =>
      attachments.where((a) => a.kind != AttachmentKind.image).toList();

  AppNotification withAttachments(List<NotificationAttachment> attachments) =>
      AppNotification(
        id: id,
        title: title,
        body: body,
        readAt: readAt,
        createdAt: createdAt,
        attachments: attachments,
      );

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
    id: map['id'] as String,
    title: map['title'] as String,
    body: map['body'] as String?,
    readAt: map['read_at'] == null
        ? null
        : DateTime.parse(map['read_at'] as String),
    createdAt: DateTime.parse(map['created_at'] as String),
    attachments: ((map['notification_attachments'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(NotificationAttachment.fromMap)
        .toList(),
  );
}
