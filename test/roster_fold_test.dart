import 'package:flutter_test/flutter_test.dart';
import 'package:hajjoperations/features/modules/domain/operational_module.dart';
import 'package:hajjoperations/features/modules/presentation/module_detail_screen.dart';

/// A file records one row per POST, not per person.
///
/// On تشكيل فرق المشاعر that is not an edge case, it is the shape of the file:
/// the same supervisor serves منى يوم التروية, عرفات and منى أيام التشريق, so
/// he is three rows — and the roster drew three of him, each with his face, his
/// two telephone numbers and his rating stars, differing only in one small line
/// of role text. A reader scrolling that column cannot tell one man from three
/// men who share a name.
///
/// So the person is the row and the posts ride on it.
ModuleMember _m(String profileId, String roleId) => ModuleMember(
  id: '$profileId-$roleId',
  profileId: profileId,
  roleId: roleId,
);

void main() {
  test('three posts held by one man are one row carrying three', () {
    final entries = foldRoster([
      ('مشرف فريق التروية', _m('p1', 'r1')),
      ('مشرف فريق عرفات', _m('p1', 'r2')),
      ('مشرف فريق التشريق', _m('p1', 'r3')),
    ]);

    expect(entries.length, 1);
    expect(entries.single.member.profileId, 'p1');
    expect(entries.single.roleNames, [
      'مشرف فريق التروية',
      'مشرف فريق عرفات',
      'مشرف فريق التشريق',
    ]);
  });

  test('different people stay different rows', () {
    final entries = foldRoster([
      ('مشرف', _m('p1', 'r1')),
      ('معاون', _m('p2', 'r2')),
    ]);

    expect(entries.map((e) => e.member.profileId), ['p1', 'p2']);
    expect(entries.map((e) => e.roleNames.single), ['مشرف', 'معاون']);
  });

  test('the order is the type\'s, not the people\'s', () {
    // First appearance wins, so the manager still comes before his deputy and
    // the deputy before the members. Sorting by anything else would reorder a
    // roster the reader did not ask to have reordered.
    final entries = foldRoster([
      ('مدير', _m('p3', 'r1')),
      ('معاون', _m('p1', 'r2')),
      ('عضو', _m('p2', 'r3')),
      ('عضو', _m('p3', 'r3')),
    ]);

    expect(entries.map((e) => e.member.profileId), ['p3', 'p1', 'p2']);
    // And the man who is both keeps both, in the order they were declared.
    expect(entries.first.roleNames, ['مدير', 'عضو']);
  });

  test('the same post twice is a duplicate row, not a second duty', () {
    final entries = foldRoster([
      ('مشرف', _m('p1', 'r1')),
      ('مشرف', _m('p1', 'r1')),
    ]);

    expect(entries.single.roleNames, ['مشرف']);
  });

  test('a card that names its own post leaves the tiles unlabelled', () {
    // A group of ONE post is already named by its heading; repeating it on
    // twenty tiles says the same word twenty times.
    final entries = foldRoster([
      (null, _m('p1', 'r1')),
      (null, _m('p2', 'r1')),
    ]);

    expect(entries.length, 2);
    expect(entries.every((e) => e.roleNames.isEmpty), isTrue);
  });

  test('a nameless post does not fold two people together', () {
    // The fold keys on the PERSON. Keying on the label — which is null here —
    // would have merged an entire team into one tile.
    final entries = foldRoster([
      (null, _m('p1', 'r1')),
      ('مشرف', _m('p1', 'r2')),
      (null, _m('p2', 'r1')),
    ]);

    expect(entries.length, 2);
    expect(entries.first.roleNames, ['مشرف']);
  });

  test('nothing in is nothing out', () {
    expect(foldRoster(const []), isEmpty);
  });
}
