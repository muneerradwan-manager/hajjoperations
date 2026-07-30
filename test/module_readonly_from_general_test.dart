import 'package:flutter_test/flutter_test.dart';
import 'package:hajjoperations/features/modules/presentation/module_detail_screen.dart';

/// A file is reached down two corridors. Under إدارة الملفات it is the season's
/// paperwork and the point is to run it; under عام it is a man's own posting,
/// the same file every other member of it sees, and the point is to read it.
///
/// The permission alone answered the wrong question. A manager who is also
/// assigned to a tower held `modules.manage`, so Edit, Deactivate and Delete
/// appeared on his own posting too — three ways to alter the season's paperwork
/// from a list that never claimed to be about managing it, one of them a tap
/// from destroying it.
void main() {
  test('a file opens read-only unless it was opened from the office', () {
    // The default, which is what every caller that does not think about this
    // gets: the employee page opening somebody's assignment, and any route
    // added later.
    expect(const ModuleDetailScreen(moduleId: 'x').fromOffice, isFalse);

    // Reading another employee's assignment from their page — a viewer, however
    // senior, is looking at what THAT person is responsible for.
    expect(
      const ModuleDetailScreen(moduleId: 'x', viewAsProfileId: 'y').fromOffice,
      isFalse,
    );

    // Only إدارة الملفات says otherwise, and it has to say so out loud.
    expect(
      const ModuleDetailScreen(moduleId: 'x', fromOffice: true).fromOffice,
      isTrue,
    );
  });
}
