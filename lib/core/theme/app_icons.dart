import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// Single source of truth for iconography (Iconsax). Semantic names so screens
/// don't hard-code icon choices.
class AppIcons {
  const AppIcons._();

  // Auth / account
  static const email = Iconsax.sms;
  static const password = Iconsax.lock;
  static const logout = Iconsax.logout;
  static const settings = Iconsax.setting_2;

  // Selection
  static const selected = Iconsax.tick_circle;
  static const unselected = Iconsax.record;

  // Media
  static const camera = Iconsax.camera;
  static const gallery = Iconsax.gallery;
  static const addPhoto = Iconsax.gallery_add;
  static const image = Iconsax.gallery;
  static const upload = Iconsax.export_1;
  static const view = Iconsax.eye;

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
  static const send = Iconsax.send_2;

  // Seasons
  static const seasons = Iconsax.calendar_1;
  static const participants = Iconsax.people;
  static const current = Iconsax.star_1;
  static const manageParticipants = Iconsax.user_edit;

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
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // Material's chevron rather than an Iconsax arrow: the Iconsax variants are
    // solid triangles that read as "play", and their LTR/RTL pair have visibly
    // different weights.
    return Icon(
      rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
      size: 24,
      color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}
