import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_accents.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/glass_tokens.dart';
import '../../../../core/utils/hijri_utils.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/profile_avatar.dart';

/// How much room the greeting has, which decides whether the face sits beside
/// the name or above it, and where the badges go.
enum GreetingLayout {
  /// A phone's width: face beside name, badges on their own line below.
  stacked,

  /// A wide single column: badges move up onto the name's line, because a
  /// thousand-pixel row with a name at one end and nothing at the other is the
  /// emptiness this whole layout exists to remove.
  wide,

  /// A tall, narrow panel beside the tiles: face above name, everything
  /// centred.
  column,
}

/// The screen's anchor: who you are, what you do, and what day it is.
///
/// It is also the way into your own profile — a card showing your face and your
/// name is where anyone reaches for that, so a separate tile below would be a
/// second door to the same room.
class GreetingPanel extends StatelessWidget {
  const GreetingPanel({
    super.key,
    required this.name,
    required this.subtitle,
    required this.photoUrl,
    required this.isAdmin,
    required this.onTap,
    required this.layout,
  });

  final String name;
  final String? subtitle;
  final String? photoUrl;

  /// Whether this person runs the Administration — written into the job title
  /// line rather than worn as a badge of its own. See [_Identity].
  final bool isAdmin;

  final VoidCallback onTap;

  final GreetingLayout layout;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.xl),
      onTap: onTap,
      child: switch (layout) {
        GreetingLayout.column => _column(context),
        _ => _row(context),
      },
    );
  }

  Widget _row(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final inlineBadges = layout == GreetingLayout.wide;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Ring(photoUrl: photoUrl, name: name, radius: 28),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: _Identity(
                name: name,
                subtitle: subtitle,
                isAdmin: isAdmin,
              ),
            ),
            if (inlineBadges) ...[
              const SizedBox(width: AppSpacing.lg),
              const DateBadges(),
              const SizedBox(width: AppSpacing.lg),
            ] else
              const SizedBox(width: AppSpacing.sm),
            const NavChevron(),
          ],
        ),
        if (!inlineBadges) ...[
          const SizedBox(height: AppSpacing.lg),
          Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.md),
          const DateBadges(),
        ],
      ],
    );
  }

  Widget _column(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: _Ring(photoUrl: photoUrl, name: name, radius: 40),
        ),
        const SizedBox(height: AppSpacing.lg),
        _Identity(
          name: name,
          subtitle: subtitle,
          isAdmin: isAdmin,
          align: CrossAxisAlignment.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
        const SizedBox(height: AppSpacing.md),
        const DateBadges(alignment: WrapAlignment.center),
      ],
    );
  }
}

/// The avatar in its brand-gradient ring, which reads as a status halo.
class _Ring extends StatelessWidget {
  const _Ring({
    required this.photoUrl,
    required this.name,
    required this.radius,
  });

  final String? photoUrl;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.secondary],
        ),
      ),
      child: ProfileAvatar(photoUrl: photoUrl, name: name, radius: radius),
    );
  }
}

/// The name, the job title, and — in the row forms — the line that says where
/// tapping the card goes, now that the tile which used to say it is gone.
class _Identity extends StatelessWidget {
  const _Identity({
    required this.name,
    required this.subtitle,
    required this.isAdmin,
    this.align = CrossAxisAlignment.start,
  });

  final String name;
  final String? subtitle;

  /// Whether this person runs the Administration.
  ///
  /// It used to be a badge of its own, standing beside the season's on the row
  /// below. It reads better in parentheses after the job title, because that is
  /// what it IS — a second thing this person is called, not a fact about the
  /// day — and it left the badge row to the two dates alone.
  final bool isAdmin;

  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final centred = align == CrossAxisAlignment.center;
    final textAlign = centred ? TextAlign.center : TextAlign.start;

    final job = subtitle != null && subtitle!.isNotEmpty ? subtitle : null;

    // The job title in the grey the rest of this line is written in, and the
    // rank after it in a colour of its own — "مشرف ميداني (مدير)", where only
    // the bracketed half is coloured. Two spans rather than two widgets so the
    // pair ellipsises as one line and wraps as one line.
    //
    // Red, from the family this palette gives to people and to what they are
    // answerable for. Neither the green on the Gregorian badge below nor the
    // gold on the Hijri one: a rank that borrows a date's colour reads as
    // belonging to the date.
    //
    // An admin with no job title on file gets "مدير" with no brackets — a lone
    // "(مدير)" is punctuation with nothing to qualify.
    final rank = !isAdmin
        ? null
        : job == null
        ? l.profileBadgeAdmin
        : l.profileTitleBadgeSuffix(l.profileBadgeAdmin);

    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          l.homeWelcome(name),
          style: text.titleLarge,
          textAlign: textAlign,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (job != null || rank != null) ...[
          const SizedBox(height: 3),
          Text.rich(
            TextSpan(
              children: [
                if (job != null) TextSpan(text: rank == null ? job : '$job '),
                if (rank != null)
                  TextSpan(
                    text: rank,
                    style: TextStyle(
                      color: Accent.red.of(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: textAlign,
            maxLines: centred ? 2 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (!centred) ...[
          const SizedBox(height: 4),
          Text(
            l.navMyProfile,
            style: text.labelSmall?.copyWith(color: scheme.primary),
          ),
        ],
      ],
    );
  }
}

/// Today's date, in both calendars, side by side.
///
/// Two badges rather than one line, because they are two answers to the same
/// question and a reader wants whichever one they think in — the mission runs
/// on the Hijri date and the rest of the world writes the other on a form.
/// Neither is a subtitle of the other, so neither is set below the other.
///
/// The pair replaced the season's Hijri YEAR, which used to stand here and was
/// a different kind of fact: which year the Administration is working through
/// is a setting, not the day it is, and a bare "1447 هـ" beside a man's name
/// read as today's date to everyone who saw it. The season lives on its own
/// screen, where it can be changed — and this card no longer asks the server
/// for it on every open.
///
/// Gold and green rather than two of a kind: the calendar is the gold family
/// everywhere else in this app, and the two badges still have to be told apart
/// when the words in them run to the same length.
class DateBadges extends StatelessWidget {
  const DateBadges({super.key, this.alignment = WrapAlignment.start});

  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    // The language the reader chose, not the device's: the app carries its own
    // locale setting, and a phone set to English with the app set to Arabic
    // must not print half the card in each.
    final language = Localizations.localeOf(context).languageCode;

    // Read at build time rather than held in state. A greeting card is rebuilt
    // on every session change, every refresh and every theme flip; a date that
    // was captured once in initState would be the day the app was opened, which
    // for a phone left running on a bedside table in Mina is yesterday.
    final now = DateTime.now();

    return Wrap(
      alignment: alignment,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        GlassBadge(
          label: l.homeHijriDate(HijriUtils.todayInWords(language)),
          color: scheme.secondary,
          icon: AppIcons.hijriDate,
        ),
        GlassBadge(
          // `d MMMM y`, not the numeric form: the badge beside it spells its
          // month out, and "صفر" against "2026-08-04" is two different habits
          // of writing on one card.
          label: l.homeGregorianDate(
            DateFormat('d MMMM y', language).format(now),
          ),
          color: scheme.primary,
          icon: AppIcons.gregorianDate,
        ),
      ],
    );
  }
}
