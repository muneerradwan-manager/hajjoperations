import 'package:flutter_test/flutter_test.dart';
import 'package:hajjoperations/features/notifications/domain/app_notification.dart';

/// Where a notification takes you when you tap it.
///
/// The `data` payload is written by database triggers — notify_module_assignment
/// and the file broadcast — and read here. The two ends have to agree about the
/// key names, and nothing but a test says so: a trigger that started writing
/// `file_id` instead of `module_id` would silently make every notification
/// unopenable, with no error anywhere.
AppNotification _n(Map<String, dynamic> data) => AppNotification.fromMap({
  'id': 'n1',
  'group_id': 'g1',
  'title': 'تم إسنادك إلى ملف تشغيلي',
  'created_at': '2026-05-03T09:00:00Z',
  'data': data,
});

void main() {
  group('what a notification points at', () {
    test('an assignment opens its file', () {
      // Exactly the shape notify_module_assignment builds.
      final n = _n({
        'type': 'module_assigned',
        'module_id': 'm-42',
        'node_id': 'nd-7',
        'role_id': 'r-3',
      });
      expect(n.moduleId, 'm-42');
      expect(n.hasTarget, isTrue);
    });

    test('a broadcast to a file opens that file', () {
      final n = _n({'type': 'module_broadcast', 'module_id': 'm-9'});
      expect(n.moduleId, 'm-9');
      expect(n.hasTarget, isTrue);
    });

    test('a broadcast to everyone points nowhere', () {
      // It names no place, so the card must not offer to open one.
      final n = _n({'type': 'broadcast'});
      expect(n.moduleId, isNull);
      expect(n.hasTarget, isFalse);
    });

    test('no payload at all is not a crash', () {
      final n = AppNotification.fromMap({
        'id': 'n1',
        'group_id': 'g1',
        'title': 'hello',
        'created_at': '2026-05-03T09:00:00Z',
      });
      expect(n.data, isEmpty);
      expect(n.hasTarget, isFalse);
    });

    test('a known type with no id points nowhere rather than at empty', () {
      expect(_n({'type': 'module_assigned'}).hasTarget, isFalse);
      expect(_n({'type': 'module_assigned', 'module_id': ''}).hasTarget, isFalse);
    });

    test('an unknown type is not followed, whatever it carries', () {
      // A future notification kind must not be opened as if it were a file.
      final n = _n({'type': 'report_filed', 'module_id': 'm-1'});
      expect(n.hasTarget, isFalse);
    });

    test('the payload survives being marked read', () {
      // The card rebuilds from markedRead(); losing the payload there would
      // make a notification openable exactly once.
      final n = _n({'type': 'module_assigned', 'module_id': 'm-42'});
      expect(n.markedRead().moduleId, 'm-42');
      expect(n.withAttachments(const []).moduleId, 'm-42');
    });
  });
}
