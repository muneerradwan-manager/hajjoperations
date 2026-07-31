import '../../../core/attachments/attachment.dart';

export '../../../core/attachments/attachment.dart';

/// A photo, a video, a voice note or a document sent with a notification.
///
/// The same shape everything attached in this app has: [path] points into the
/// private `notifications` bucket, and nothing is readable from it without a
/// signed URL, minted on demand for the recipient.
typedef NotificationAttachment = StoredAttachment;

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    this.body,
    this.readAt,
    required this.createdAt,
    required this.groupId,
    this.attachments = const [],
    this.data = const {},
  });

  final String id;

  /// The send this row belongs to. One id shared by every recipient of a
  /// broadcast, and what its attachments hang off.
  final String groupId;

  final String title;
  final String? body;
  final DateTime? readAt;
  final DateTime createdAt;

  /// What came with it. Fetched alongside rather than embedded: the inbox is a
  /// realtime stream, and a stream cannot carry a joined table.
  final List<NotificationAttachment> attachments;

  /// What the notification was ABOUT, as the trigger that raised it wrote it:
  /// a `type` and whatever identifies the thing — `module_id`, `node_id`,
  /// `role_id`. Carried through so a tap can open it. Empty for a notification
  /// that points nowhere, which a plain broadcast does.
  final Map<String, dynamic> data;

  /// The file this notification is about, when it is about one.
  ///
  /// Both an assignment ('you were put into this file') and a broadcast to a
  /// file's members are about the same place, so both open it. A general
  /// broadcast names nothing and returns null.
  String? get moduleId {
    final type = data['type'];
    if (type != 'module_assigned' && type != 'module_broadcast') return null;
    final id = data['module_id'];
    return id is String && id.isNotEmpty ? id : null;
  }

  /// Whether tapping this has anywhere to go.
  bool get hasTarget => moduleId != null;

  bool get isRead => readAt != null;

  List<NotificationAttachment> get images =>
      attachments.where((a) => a.kind == AttachmentKind.image).toList();

  List<NotificationAttachment> get others =>
      attachments.where((a) => a.kind != AttachmentKind.image).toList();

  /// The same notification, read now. Used to show the change before the write
  /// comes back: the server is the truth, but a tap should not look ignored for
  /// three seconds while it says so.
  AppNotification markedRead() => AppNotification(
    id: id,
    groupId: groupId,
    title: title,
    body: body,
    readAt: readAt ?? DateTime.now(),
    createdAt: createdAt,
    attachments: attachments,
    data: data,
  );

  AppNotification withAttachments(List<NotificationAttachment> attachments) =>
      AppNotification(
        id: id,
        groupId: groupId,
        title: title,
        body: body,
        readAt: readAt,
        createdAt: createdAt,
        attachments: attachments,
        data: data,
      );

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
    id: map['id'] as String,
    groupId: (map['group_id'] as String?) ?? map['id'] as String,
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
    data: Map<String, dynamic>.from(
      (map['data'] as Map?) ?? const <String, dynamic>{},
    ),
  );
}
