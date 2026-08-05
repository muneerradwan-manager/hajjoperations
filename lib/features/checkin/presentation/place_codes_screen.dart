import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/animations/animations.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass.dart';
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
/// The FILE itself is offered first and is not a formality: a flat file with no
/// towers still has people arriving at it, and a file whose sectors have not
/// been drawn yet still wants its people counted.
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

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  l.checkInQrHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              _PlaceTile(
                title: moduleName,
                subtitle: l.checkInPlaceUnknown,
                onTap: () => open(
                  CheckInCode(moduleId: moduleId),
                  moduleName,
                ),
              ),
              for (final node in state.nodes)
                if (state.placeOf(node.id) case final place?)
                  _PlaceTile(
                    title: place.of(context),
                    onTap: () => open(
                      CheckInCode(moduleId: moduleId, nodeId: node.id),
                      place.of(context),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.title, required this.onTap, this.subtitle});

  final String title;
  final String? subtitle;
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  if (subtitle case final text?)
                    Text(
                      text,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const NavChevron(),
          ],
        ),
      ),
    ),
  );
}
