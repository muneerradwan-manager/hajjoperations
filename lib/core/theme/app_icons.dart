import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// Single source of truth for iconography (Iconsax). Semantic names so screens
/// don't hard-code icon choices.
class AppIcons {
  const AppIcons._();

  /// Iconsax declares every glyph without `matchTextDirection`, so an arrow it
  /// draws pointing right keeps pointing right in Arabic — a "log out" arrow
  /// aims back into the layout, a "send" plane flies against the reading
  /// direction. Material's own arrows carry the flag and flip themselves; these
  /// are re-declared with it so [Icon] mirrors them under an RTL
  /// [Directionality] too.
  ///
  /// Re-declared rather than derived because the code points have to survive in
  /// a `const` expression — `Iconsax.logout.codePoint` is not one. The Iconsax
  /// name is named beside each, and `test/rtl_icons_test.dart` fails if the
  /// package ever renumbers them.
  static const _iconsaxFont = 'FlutterIconsax';
  static const _iconsaxPackage = 'iconsax_flutter';

  /// Iconsax.logout
  static const logout = IconData(
    0xed3b,
    fontFamily: _iconsaxFont,
    fontPackage: _iconsaxPackage,
    matchTextDirection: true,
  );

  /// Iconsax.send_2
  static const send = IconData(
    0xef3d,
    fontFamily: _iconsaxFont,
    fontPackage: _iconsaxPackage,
    matchTextDirection: true,
  );

  /// Iconsax.export_1
  static const upload = IconData(
    0xebbd,
    fontFamily: _iconsaxFont,
    fontPackage: _iconsaxPackage,
    matchTextDirection: true,
  );

  // Auth / account
  static const email = Iconsax.sms;
  static const password = Iconsax.lock;
  static const settings = Iconsax.setting_2;

  // A tick, for stating that something is done or present — a file has been
  // chosen, an inbox has been read. NOT for the selected half of a pair of
  // states: that is `SelectionIndicator`, which draws both halves so the empty
  // one is visibly empty. There is no `unselected` glyph here on purpose; it
  // used to be `Iconsax.record`, a filled disc, which is what SELECTED looks
  // like everywhere else in the world.
  static const selected = Iconsax.tick_circle;

  // Media
  static const camera = Iconsax.camera;
  static const gallery = Iconsax.gallery;
  static const addPhoto = Iconsax.gallery_add;
  static const image = Iconsax.gallery;
  static const view = Iconsax.eye;

  // Attachments. `attach` is the act; the rest name what was attached, so a
  // recipient can tell a voice note from a document without opening either.
  static const attach = Iconsax.paperclip_2;
  static const video = Iconsax.video_play;
  static const audio = Iconsax.musicnote;
  static const file = Iconsax.document_text;
  static const download = Iconsax.import_1;

  // Settings
  static const language = Iconsax.language_square;
  static const theme = Iconsax.moon;

  // Profile fields
  static const firstName = Iconsax.user;
  static const fatherName = Iconsax.profile_2user;
  static const surname = Iconsax.personalcard;
  static const jobTitle = Iconsax.briefcase;
  static const gender = Iconsax.man;
  static const mission = Iconsax.people;
  static const dateOfBirth = Iconsax.cake;
  static const phoneSy = Iconsax.call;
  static const phoneSa = Iconsax.mobile;

  // Documents
  static const document = Iconsax.document_text;
  static const documentEmpty = Iconsax.document;
  static const brokenImage = Iconsax.gallery_slash;

  // Approvals / actions
  static const search = Iconsax.search_normal_1;
  static const permissions = Iconsax.security_user;
  static const approvals = Iconsax.user_tick;

  // Notifications
  static const notifications = Iconsax.notification;

  // Seasons
  static const seasons = Iconsax.calendar_1;
  static const participants = Iconsax.people;
  static const current = Iconsax.star_1;
  static const manageParticipants = Iconsax.user_edit;

  // Operational modules
  static const modules = Iconsax.folder_2;
  static const moduleType = Iconsax.category;
  static const tasks = Iconsax.task_square;
  static const roles = Iconsax.user_octagon;
  static const pdf = Iconsax.document_download;
  static const referenceData = Iconsax.data;
  static const location = Iconsax.location;
  static const myLocation = Iconsax.gps;
  static const map = Iconsax.map_1;
  static const activate = Iconsax.flash_1;
  static const add = Iconsax.add;
  static const delete = Iconsax.trash;

  // Employees management
  static const employees = Iconsax.profile_2user;
  static const addUser = Iconsax.user_add;
  static const external = Iconsax.buildings_2;
  static const organization = Iconsax.buildings;
  static const suspend = Iconsax.slash;
  static const myProfile = Iconsax.user;
  static const shield = Iconsax.shield_tick;
  static const approve = Iconsax.tick_circle;
  static const reject = Iconsax.close_circle;
  static const edit = Iconsax.edit_2;
  static const emptyInbox = Iconsax.box;

  // Status
  static const pending = Iconsax.timer_1;
  static const rejected = Iconsax.close_circle;

  // Brand
  static const brand = Iconsax.moon;
}

/// A trailing chevron that points toward the navigation direction, mirrored
/// correctly for RTL locales.
class NavChevron extends StatelessWidget {
  const NavChevron({super.key, this.color});
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // Material's chevron rather than an Iconsax arrow: the Iconsax variants are
    // solid triangles that read as "play", and their LTR/RTL pair have visibly
    // different weights.
    //
    // Always the RIGHT chevron, in both directions. Material declares this glyph
    // with `matchTextDirection: true`, so Flutter already flips it under an RTL
    // Directionality — picking the left chevron for Arabic mirrored it a second
    // time and pointed it back the way it came.
    return Icon(
      Icons.chevron_right_rounded,
      size: 24,
      color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}
