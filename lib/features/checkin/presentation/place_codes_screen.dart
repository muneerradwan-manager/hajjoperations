import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/animations/animations.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/states.dart';
import '../../modules/application/module_detail_cubit.dart';
import '../domain/check_in.dart';
import 'place_code_screen.dart';

/// Every place in this file that can carry a code, in one list.
///
/// One screen rather than a code hidden behind each node in the tree, because
/// of what actually happens: somebody sits down once, before the season, and
/// prints forty stickers to be walked out and fixed to forty gates. Making them
/// tap into each tower to reach its code would turn a half-hour job into an
/// afternoon, and an afternoon job is one that gets half-finished.
///
/// **Only the levels that are places** — البرج/الفندق, المخيم — and neither the
/// arrangements above and below them nor the file itself.
///
/// A code is a physical object screwed to a physical place. A قطاع is an
/// arrangement on paper with no gate to fix one to, and a تكتل is a bloc of
/// pilgrims INSIDE a tower that already has its own. Printing for either
/// produces sheets that never go up, or go up on a tower — and then two places
/// answer to one code and the register records people as standing somewhere
/// they are not.
///
/// Which levels those are is READ from the level (`is_place`, 0089) and never
/// inferred. Every available inference is wrong somewhere, and one of them was
/// shipped here first: "the deepest level" quietly dropped every hotel in مكة,
/// because the تكتل was added below the tower in 0061 and is deeper than it.
class PlaceCodesScreen extends StatelessWidget {
  const PlaceCodesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Scaffold(
      appBar: GlassAppBar(title: Text(l.checkInQrTitle)),
      body: BlocBuilder<ModuleDetailCubit, ModuleDetailState>(
        builder: (context, state) {
          final moduleId = context.read<ModuleDetailCubit>().moduleId;
          final moduleName =
              state.type?.name.of(context) ??
              state.module?.moduleTypeName?.of(context) ??
              '';

          void open(CheckInCode code, String placeName) {
            Navigator.of(context).push(
              fadeThroughRoute(
                (_) => PlaceCodeScreen(
                  code: code,
                  placeName: placeName,
                  moduleName: moduleName,
                ),
              ),
            );
          }

          // Only the levels that ARE places — see the class comment and 0089.
          final placeLevels = {
            for (final level in state.type?.placeLevels ?? const [])
              level.id,
          };
          final places = [
            for (final node in state.nodes)
              if (placeLevels.contains(node.levelId)) node,
          ];

          if (places.isEmpty) {
            return EmptyState(
              icon: AppIcons.qrCode,
              title: l.checkInNoPlaces,
              message: l.checkInNoPlacesHint,
            );
          }

          return ResponsivePage(
            builder: (context, size) => SinglePaneLayout(
              gutter: size.gutter,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    l.checkInQrHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                for (final node in places)
                  if (state.placeOf(node.id) case final place?)
                    _PlaceTile(
                      title: place.of(context),
                      onTap: () => open(
                        CheckInCode(moduleId: moduleId, nodeId: node.id),
                        place.of(context),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: GlassCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(AppIcons.qrCode, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const NavChevron(),
          ],
        ),
      ),
    ),
  );
}
