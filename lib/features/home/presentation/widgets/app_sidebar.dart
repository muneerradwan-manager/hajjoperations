import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/glass_tokens.dart';
import '../../../../core/utils/hijri_utils.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../auth/application/session_cubit.dart';
import '../../domain/home_destinations.dart';
import 'home_pieces.dart';

/// The rail folded down to nothing but its icons.
///
/// 76 is not a round number chosen for looking right. A tile's hit target is
/// the 24-pixel glyph plus the padding around it, and the padding has to be
/// even on both sides or the icons sit off-centre in the column — which is the
/// one thing a reader notices instantly in a vertical strip. 76 = 8 (the tile's
/// own margin) + 18 + 24 + 18 + 8, and the 18 is what the tile's horizontal
/// padding animates TO when it closes.
const kRailCollapsedWidth = 76.0;

/// The rail standing open.
///
/// Wider than [kSidePanelWidth]'s 320 would be excessive and narrower than 260
/// starts ellipsising the longer names — "إدارة الملفات التشغيلية" and
/// "القرارات والتعميمات" are the two that decide this number, and both fit at
/// 288 with the compose button still on the line.
const kRailExpandedWidth = 288.0;

/// How long the fold takes, and the shape of it.
///
/// One duration and one curve for the width, the paddings and the labels'
/// opacity, because they are three implicit animations of the same gesture: run
/// them on different curves and the labels arrive after the column has stopped
/// moving, which reads as the rail stuttering rather than opening.
const _fold = Duration(milliseconds: 220);
const _curve = Curves.easeOutCubic;

/// The tile's inset when open and when closed — see [kRailCollapsedWidth] for
/// where the second number comes from.
///
/// Both are one pixel short of the round numbers they look like they should be,
/// and the missing pixel is [_border]. A tile draws its outline whether or not
/// it is the current one — transparent when it is not, so that becoming current
/// does not shift the label sideways by two pixels — and `Border.all` is one
/// pixel of real geometry on each side either way. Left out of the arithmetic,
/// the folded rail hands its 24-pixel glyph a 22-pixel box and paints a
/// yellow-and-black stripe down the whole column.
const _padOpen = 13.0;
const _padShut = 17.0;

/// The tile's own margin off the rail's edges.
const _tileMargin = AppSpacing.sm;

/// The tile's outline, drawn at every state — see [_padOpen].
const _border = 1.0;

/// What the label is laid out at, whatever the rail's current width.
///
/// Fixed, and that is the trick the whole fold rests on. The label lives in an
/// [OverflowBox] pinned to this width inside a [ClipRect]: the row never
/// re-flows, never re-wraps and never overflows — it is simply revealed, the
/// way a drawer reveals what is in it. Laid out at the live width instead, the
/// text would re-break on every frame of the animation and the last few frames
/// would be a `RenderFlex overflowed` stripe.
const _labelWidth =
    kRailExpandedWidth - _tileMargin * 2 - _border * 2 - _padOpen * 2 - _iconBox;

const _iconBox = 24.0;

/// The standing column of doors: everything the home page can open, in one
/// place, folded to icons or open with its labels.
///
/// It draws from the same catalogue the grid of tiles draws from — see
/// [homeDestinations] — so a permission that hides a tile hides a rail entry by
/// construction rather than by two people remembering to make the same edit.
///
/// It is built by [AppShell], ABOVE the navigator every page lives on, so
/// opening a section swaps what is beside the column and leaves the column
/// itself alone — no rebuild, no re-fold, no scroll position lost.
///
/// And it navigates by REPLACING rather than stacking. Its entries are peers:
/// going from الملفات to الموظفون is not going deeper, so nothing is left
/// underneath and nothing draws a back arrow promising there is. Details opened
/// from inside a page still push, still stack, and still keep their arrow —
/// which is exactly the line between a destination and a detail.
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.session,
    required this.location,
    required this.expanded,
    this.onToggle,
    this.onNavigate,
  });

  final SessionState session;

  /// The path currently on screen beside this column.
  ///
  /// It is what makes the rail a rail rather than a menu: exactly one entry is
  /// drawn as current at any moment, and a reader who has been three pages deep
  /// can look left and see where he is without reading a title.
  final String location;

  /// Whether the labels are showing. Always true in the drawer — see
  /// [onToggle].
  final bool expanded;

  /// Folds and unfolds. Null inside the drawer on a narrow window: a panel that
  /// is already overlaying the page has nothing to gain by getting narrower,
  /// and a fold control there would offer to make the menu harder to read.
  final VoidCallback? onToggle;

  /// Called after a destination is chosen — how the drawer closes itself behind
  /// the reader. Null for the standing rail, which does not go anywhere.
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final profile = session.profile;
    final destinations = homeDestinations(session, l);
    final shelves = homeShelves(destinations);

    // `go`, not `push`, and this one line is what makes the whole arrangement
    // work. A rail's destinations are peers: opening الموظفون from الملفات is
    // not going deeper, it is going ELSEWHERE, and stacking them means a reader
    // who has looked at six sections has six pages under him and six presses of
    // back to get out. Replacing means there is nothing to go back to, which is
    // why no page reached from this column draws a back arrow.
    //
    // Anything opened from INSIDE a page still pushes — the employee behind the
    // directory, the file behind the list — and still keeps its arrow. The
    // difference is exactly the difference between a destination and a detail.
    void go(String route) {
      onNavigate?.call();
      context.go(route);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onToggle case final toggle?)
          _FoldButton(expanded: expanded, onPressed: toggle),
        // Who is signed in, and the way to their own page. First rather than
        // last, because it answers the question a shared handset raises before
        // any other — whose account is this? — and because the face is the one
        // thing in this column that is still recognisable when the labels are
        // folded away.
        _RailTile(
          // Radius 12, because [_iconBox] is 24: the face stands in the same
          // box every glyph below it stands in, so the folded column is one
          // straight run of marks rather than a face bulging out of the line.
          leading: ProfileAvatar(
            photoUrl: profile?.photoUrl,
            name: profile?.firstName,
            radius: 12,
          ),
          label: profile?.firstName ?? l.navMyProfile,
          hint: profile?.jobTitleName?.of(context) ?? l.navMyProfile,
          tooltip: l.navMyProfile,
          expanded: expanded,
          selected: location == Routes.myProfile,
          onTap: () => go(Routes.myProfile),
        ),
        // Today, in both calendars, directly under the name.
        //
        // They used to stand on the greeting card in the middle of the page,
        // and under this arrangement there is no greeting card: the face and
        // the name are here, so the dates that belong beside them came here
        // too. It is also the better place for them — the mission runs on the
        // Hijri date, and a fact consulted that often should be on the glass at
        // all times rather than at the top of a page that scrolls.
        _RailDates(expanded: expanded),
        const _RailDivider(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            children: [
              // The way home. It heads the column rather than sitting with the
              // shelves because it is not one of them — the others are places
              // to go and this is the place they are all drawn on.
              _RailTile(
                leading: const Icon(AppIcons.roadmap, size: 20),
                label: l.roadmapTitle,
                tooltip: l.roadmapIntroTitle,
                color: scheme.primary,
                selected: location == Routes.home,
                expanded: expanded,
                onTap: () => go(Routes.home),
              ),
              for (final shelf in shelves) ...[
                _RailGroupLabel(
                  title: shelf.group.title(l),
                  color: shelf.group.accent.of(context),
                  expanded: expanded,
                ),
                for (final destination in shelf.destinations)
                  _RailTile(
                    leading: Icon(destination.icon, size: 20),
                    label: destination.title,
                    tooltip: destination.subtitle,
                    color: destination.colorOf(context),
                    expanded: expanded,
                    // Matched exactly, never by prefix — the same rule the
                    // route guards are written by. `/modules/manage` starts
                    // with `/modules`, and a prefix match would light both the
                    // office's entry and the member's whenever either was open.
                    selected: location == destination.route,
                    onTap: () => go(destination.route),
                    // The compose action, kept on the rail rather than dropped
                    // from it. "مهمة جديدة" is one of the three things anybody
                    // does most often in this app, and a menu that can open the
                    // list but not write on it sends the reader through two
                    // screens to reach what the grid gave them in one tap.
                    //
                    // It goes when the rail folds, and that is not a loss: the
                    // list it opens carries the same button, one tap further.
                    action: destination.action == null
                        ? null
                        : () => go(destination.action!),
                    actionLabel: destination.actionLabel,
                    actionIcon: destination.actionIcon ?? AppIcons.add,
                  ),
              ],
            ],
          ),
        ),
        const _RailDivider(),
        // The foot of the column: how this device behaves, and the way out of
        // it. Settings is the one door here that is about the app rather than
        // about the mission, which is why it stands apart from the shelves
        // instead of being given a shelf of its own.
        _RailTile(
          leading: const Icon(AppIcons.settings, size: 20),
          label: l.commonSettings,
          tooltip: l.commonSettings,
          expanded: expanded,
          selected: location == Routes.settings,
          onTap: () => go(Routes.settings),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

/// The rail, wrapped in its own pane and given the room the app bar is standing
/// in — the standing form, for a window wide enough to keep it open beside the
/// page.
class StandingRail extends StatelessWidget {
  const StandingRail({
    super.key,
    required this.session,
    required this.location,
    required this.expanded,
    required this.onToggle,
    required this.gutter,
  });

  final SessionState session;
  final String location;
  final bool expanded;
  final VoidCallback onToggle;
  final double gutter;

  @override
  Widget build(BuildContext context) {
    // The window's own status bar, and nothing else. The rail stands OUTSIDE
    // the page's scaffold now — beside it rather than under its bar — so it
    // runs from the top of the glass to the bottom while each page's own bar
    // spans only the column it belongs to. That is the shape every desktop
    // application with a rail has: the navigation is the frame, and the header
    // belongs to what is framed.
    final top = MediaQuery.paddingOf(context).top + AppSpacing.md;
    final bottom = MediaQuery.viewPaddingOf(context).bottom + AppSpacing.md;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(gutter, top, 0, bottom),
      child: AnimatedContainer(
        duration: _fold,
        curve: _curve,
        width: expanded ? kRailExpandedWidth : kRailCollapsedWidth,
        child: GlassSurface(
          radius: AppRadius.lg,
          // No backdrop blur: nothing scrolls under this pane. The page beside
          // it has its own column and passes it by, so the save-layer would be
          // paid on every frame of every scroll for a picture identical to not
          // having asked. See [GlassCard.blur].
          blur: false,
          child: AppSidebar(
            session: session,
            location: location,
            expanded: expanded,
            onToggle: onToggle,
          ),
        ),
      ),
    );
  }
}

/// The button that folds the rail, sitting where a reader's eye lands first
/// when they want it out of the way: the far corner of the panel.
class _FoldButton extends StatelessWidget {
  const _FoldButton({required this.expanded, required this.onPressed});

  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: AnimatedAlign(
        duration: _fold,
        curve: _curve,
        // Hard against the far edge when open, dead centre when shut — the
        // second is the only position that works in a 76-pixel column, and the
        // first is where every panel in the world keeps this control.
        alignment: expanded
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.center,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
          child: IconButton(
            tooltip: expanded ? l.sidebarCollapse : l.sidebarExpand,
            onPressed: () {
              HapticFeedback.selectionClick();
              onPressed();
            },
            icon: Icon(
              expanded ? AppIcons.sidebarCollapse : AppIcons.sidebarExpand,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

/// The name of one shelf inside the rail — or, folded, the hairline that stands
/// in for it.
///
/// Both are drawn at once and cross-faded rather than swapped, because the
/// swap has to happen DURING the fold: `expanded` flips on the first frame of
/// a 220ms animation, and a widget exchanged on that frame pops in at a width
/// that has not moved yet.
class _RailGroupLabel extends StatelessWidget {
  const _RailGroupLabel({
    required this.title,
    required this.color,
    required this.expanded,
  });

  final String title;
  final Color color;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Room for two lines of the name — see [ShelfHeader.compact]. A shelf in
      // a column cannot always say itself in one, and the sixty pixels this
      // costs across the whole rail buy back four headings that would otherwise
      // end in an ellipsis.
      height: 52,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AnimatedOpacity(
              duration: _fold,
              curve: _curve,
              opacity: expanded ? 0 : 1,
              child: Container(
                width: 22,
                height: 1,
                color: color.withValues(alpha: 0.4),
              ),
            ),
          ),
          ClipRect(
            child: OverflowBox(
              alignment: AlignmentDirectional.centerStart,
              minWidth: kRailExpandedWidth,
              maxWidth: kRailExpandedWidth,
              child: AnimatedOpacity(
                duration: _fold,
                curve: _curve,
                opacity: expanded ? 1 : 0,
                child: Padding(
                  // The same inset the tiles' glyphs stand at, so the shelf's
                  // coloured bar lines up with the column of icons under it.
                  padding: const EdgeInsets.symmetric(
                    horizontal: _tileMargin + _border + _padOpen,
                  ),
                  child: ShelfHeader(
                    title: title,
                    color: color,
                    compact: true,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Today, in both calendars, folded into the width the rail happens to be.
///
/// Open, it is the same pair of pills the greeting card used to carry. Folded,
/// there is no honest way to print "١٢ ذو الحجة ١٤٤٧" in 76 pixels, so what is
/// left is the crescent — and the dates are in the tooltip, where a pointer and
/// a screen reader both find them.
///
/// One fixed height for both states rather than an animated one: the column
/// below it must not jump while the rail folds, and the difference between a
/// two-line stack of pills and one glyph is small enough to absorb.
class _RailDates extends StatelessWidget {
  const _RailDates({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    // The language the reader chose, not the device's — the app carries its own
    // locale, and a phone set to English with the app set to Arabic must not
    // print half the pair in each.
    final language = Localizations.localeOf(context).languageCode;

    // Read at build time rather than held in state: a rail is rebuilt on every
    // session change and every theme flip, and a date captured once in
    // initState is, for a phone left running on a bedside table in Mina,
    // yesterday.
    final hijri = l.homeHijriDate(HijriUtils.todayInWords(language));
    final gregorian = l.homeGregorianDate(
      // `d MMMM y`, not the numeric form: the badge above spells its month out,
      // and "ذو الحجة" against "2026-08-04" is two habits of writing in one
      // column.
      DateFormat('d MMMM y', language).format(DateTime.now()),
    );

    return Tooltip(
      message: '$hijri\n$gregorian',
      child: SizedBox(
        // Two pills, one above the other — see the Column below for why they
        // cannot stand side by side — plus the gap between them and a little
        // air above and below.
        height: 74,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AnimatedOpacity(
                duration: _fold,
                curve: _curve,
                opacity: expanded ? 0 : 1,
                child: Icon(
                  AppIcons.hijriDate,
                  size: 20,
                  color: scheme.secondary,
                ),
              ),
            ),
            ClipRect(
              child: OverflowBox(
                alignment: AlignmentDirectional.centerStart,
                minWidth: kRailExpandedWidth,
                maxWidth: kRailExpandedWidth,
                child: AnimatedOpacity(
                  duration: _fold,
                  curve: _curve,
                  opacity: expanded ? 1 : 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _tileMargin + _border + _padOpen,
                    ),
                    // Stacked, and it is not a preference. On the greeting
                    // card these two stood side by side because a card is as
                    // wide as the page; here they have 244 pixels between them
                    // and they measure 182 and 193 — put in a row they overflow
                    // by 140 and paint a stripe across the top of the rail.
                    //
                    // Neither may be the one that gives way, which is what a
                    // row would have forced: they are two answers to the same
                    // question, and the mission runs on the Hijri one while
                    // every form outside it wants the other.
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GlassBadge(
                          label: hijri,
                          color: scheme.secondary,
                          icon: AppIcons.hijriDate,
                          dense: true,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        GlassBadge(
                          label: gregorian,
                          color: scheme.primary,
                          icon: AppIcons.gregorianDate,
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailDivider extends StatelessWidget {
  const _RailDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: AppSpacing.md,
      endIndent: AppSpacing.md,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(
        alpha: 0.45,
      ),
    );
  }
}

/// One line of the rail: a mark that never moves, and a label that is revealed
/// beside it.
///
/// The icon is the anchor of the whole idea. It has to land on exactly the same
/// x as the icon above it and below it, open or shut, or the folded rail reads
/// as a ragged column rather than as one control — which is why the padding is
/// animated rather than the icon being centred inside a flexible box.
class _RailTile extends StatelessWidget {
  const _RailTile({
    required this.leading,
    required this.label,
    required this.expanded,
    required this.onTap,
    this.hint,
    this.tooltip,
    this.color,
    this.selected = false,
    this.action,
    this.actionLabel,
    this.actionIcon,
  });

  final Widget leading;
  final String label;

  /// A second, quieter line — the profile tile's job title, and nothing else.
  /// A rail of two-line entries is a list, not a rail.
  final String? hint;

  /// What a pointer is told, and what is read aloud. It carries the label
  /// itself when the rail is folded, because then there is nothing else to go
  /// on; open, it carries the one-line explanation the grid prints under the
  /// title and this column has no room for.
  final String? tooltip;

  final Color? color;
  final bool selected;

  /// Whether the label beside the mark is showing.
  final bool expanded;

  final VoidCallback onTap;

  final VoidCallback? action;
  final String? actionLabel;
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tone = color ?? scheme.onSurfaceVariant;
    final height = hint == null ? 46.0 : 58.0;

    final body = Row(
      children: [
        SizedBox(
          width: _iconBox,
          height: _iconBox,
          child: Center(
            child: IconTheme.merge(
              data: IconThemeData(color: tone),
              child: leading,
            ),
          ),
        ),
        // The label, laid out at a width that never changes and clipped to
        // whatever the rail currently is — see [_labelWidth].
        Expanded(
          child: ClipRect(
            child: OverflowBox(
              alignment: AlignmentDirectional.centerStart,
              minWidth: _labelWidth,
              maxWidth: _labelWidth,
              child: AnimatedOpacity(
                duration: _fold,
                curve: _curve,
                opacity: expanded ? 1 : 0,
                child: Row(
                  children: [
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium?.copyWith(
                              color: selected ? tone : scheme.onSurface,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          if (hint case final line?) ...[
                            const SizedBox(height: 2),
                            Text(
                              line,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (action case final act?)
                      IconButton(
                        tooltip: actionLabel,
                        onPressed: expanded ? act : null,
                        icon: Icon(actionIcon, size: 18),
                        color: tone,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 34,
                          height: 34,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );

    final tile = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _tileMargin,
        vertical: 2,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: _fold,
            curve: _curve,
            height: height,
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? _padOpen : _padShut,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              // Current is drawn as a wash in the entry's own colour rather
              // than as a bar down the edge: a bar has to pick a side, and this
              // rail stands on the right half the time.
              color: selected
                  ? tone.withValues(alpha: 0.16)
                  : Colors.transparent,
              // Drawn at every state, transparent when the tile is not the
              // current one: an outline that appears only on selection would
              // push the label two pixels sideways as the reader moves down the
              // column. Its width is spent in [_padOpen] and [_padShut].
              border: Border.all(
                width: _border,
                color: selected
                    ? tone.withValues(alpha: 0.30)
                    : Colors.transparent,
              ),
            ),
            child: body,
          ),
        ),
      ),
    );

    final message = expanded ? (tooltip ?? label) : label;
    return Tooltip(message: message, child: tile);
  }
}
