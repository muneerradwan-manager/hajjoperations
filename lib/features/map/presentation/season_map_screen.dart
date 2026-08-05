import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/animations/animations.dart';
import '../../../core/l10n/error_text.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/states.dart';
import '../../incidents/data/incidents_repository.dart';
import '../../incidents/domain/incident.dart';
import '../../modules/presentation/module_detail_screen.dart';
import '../application/season_map_cubit.dart';
import '../data/season_map_repository.dart';
import '../domain/map_place.dart';

/// The season on one map.
///
/// Every fact in this app has been tied to a place since the beginning — a برج
/// is a hotel with an address, a مخيم has coordinates somebody pinned, an
/// arrival records where the phone was — and none of it has ever been drawn
/// together. The map library has been in the project since 0021 and had only
/// ever been used to pick one point at a time.
///
/// What the operations room asks during the five days is a question about a
/// picture: where are our places, who is in them, and where is something wrong.
/// Asked of three lists on three screens, it is a question nobody finishes.
class SeasonMapScreen extends StatelessWidget {
  const SeasonMapScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => SeasonMapCubit(SeasonMapRepository(), IncidentsRepository()),
    child: const _MapView(),
  );
}

class _MapView extends StatefulWidget {
  const _MapView();

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  final _controller = MapController();

  /// Where the map opens when the season has nothing pinned yet — the Haram.
  /// The same fallback the location picker uses, for the same reason: a map
  /// centred on the null island is a map that looks broken.
  static const _fallback = LatLng(21.422510, 39.826168);

  /// Set once the first fit has been done, so that a refresh does not yank the
  /// view back while somebody is reading a corner of it.
  bool _framed = false;

  /// Whether the backdrop could not be fetched.
  ///
  /// Worth saying out loud. A map with no tiles looks exactly like a map that
  /// is broken, and the difference matters to whoever is standing in front of
  /// it: the pins ARE right, the positions ARE right, and it is the pictures
  /// of the streets underneath them that did not arrive.
  bool _tilesFailed = false;

  void _frame(SeasonMapState state) {
    if (_framed || state.status != SeasonMapStatus.ready) return;
    final bounds = MapBounds.around([
      for (final place in state.places) place.position,
      for (final incident in state.incidents)
        LatLng(incident.latitude!, incident.longitude!),
    ]);
    if (bounds == null) return;
    _framed = true;

    // After the frame, not during it: the map has no size until it is laid out,
    // and fitting to a box of zero puts the camera somewhere arbitrary.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(bounds.southWest, bounds.northEast),
          padding: const EdgeInsets.all(AppSpacing.xl),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(title: Text(l.seasonMapTitle)),
      body: BlocConsumer<SeasonMapCubit, SeasonMapState>(
        listener: (context, state) => _frame(state),
        builder: (context, state) {
          if (state.status == SeasonMapStatus.loading) {
            return const Center(child: AppLoader());
          }
          if (state.status == SeasonMapStatus.error) {
            return EmptyState(
              icon: AppIcons.warning,
              title: friendlyError(context, state.error),
            );
          }
          // A blank map is indistinguishable from a broken one. Said in words
          // instead, with the reason: a place appears here when somebody pins
          // it on the file, and until then there is nothing to draw.
          if (state.places.isEmpty && state.incidents.isEmpty) {
            return EmptyState(
              icon: AppIcons.checkIn,
              title: l.seasonMapEmptyState,
              message: l.seasonMapEmptyStateHint,
            );
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _controller,
                options: const MapOptions(
                  initialCenter: _fallback,
                  initialZoom: 11,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    // OpenStreetMap's tile policy asks for an identifying agent.
                    userAgentPackageName: 'com.shud.hajjoperations',
                    maxZoom: 19,
                    // Tiles that will not come are not a failure of this
                    // screen. The pins are drawn over whatever backdrop there
                    // is — including none — so the map still answers the
                    // question it was opened for: where the places are
                    // relative to each other, and which of them wants
                    // attention. A blank canvas with the right pins on it
                    // beats an error page.
                    errorTileCallback: (_, _, _) {
                      if (_tilesFailed) return;
                      // One rebuild, not one per tile: a screenful is a
                      // hundred of these inside a second.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _tilesFailed = true);
                      });
                    },
                  ),
                  MarkerLayer(
                    markers: [
                      for (final place in state.drawnPlaces)
                        Marker(
                          point: place.position,
                          width: 40,
                          height: 40,
                          child: _PlacePin(
                            place: place,
                            onTap: () => _openPlace(place),
                          ),
                        ),
                      // Drawn AFTER the places, so an emergency is never
                      // underneath the camp it happened next to.
                      for (final incident in state.drawnIncidents)
                        Marker(
                          point: LatLng(
                            incident.latitude!,
                            incident.longitude!,
                          ),
                          width: 40,
                          height: 40,
                          child: _IncidentPin(
                            incident: incident,
                            onTap: () => _openIncident(incident),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (_tilesFailed)
                Positioned(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.lg,
                  child: SafeArea(
                    child: _MapPanel(
                      child: Row(
                        children: [
                          const Icon(AppIcons.warning, size: 16),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              l.seasonMapNoTiles,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.lg,
                child: SafeArea(child: _Legend(state: state)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openPlace(MapPlace place) {
    // A hotel that is not a node in any file has nothing to open — most of
    // المدينة is in that position, since the Madinah file organises people by
    // service company and not by building. It still says what it is, because a
    // pin that does nothing at all reads as broken.
    final moduleId = place.moduleId;
    if (moduleId == null) {
      _say(place.placeName, place.groupName.of(context));
      return;
    }

    // Otherwise the file, opened the way عام opens it: this is a map of the
    // season being run, not of the catalogue being edited.
    Navigator.of(context).push(
      fadeThroughRoute((_) => ModuleDetailScreen(moduleId: moduleId)),
    );
  }

  void _say(String title, String subtitle) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(sheetContext).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle, style: Theme.of(sheetContext).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  void _openIncident(Incident incident) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              incident.body,
              style: Theme.of(sheetContext).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              incident.reporterName,
              style: Theme.of(sheetContext).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// A panel that sits ON the map, and is legible whatever is under it.
///
/// Deliberately not a [GlassCard]. Glass is a content pane: it takes its
/// character from the page behind it, which everywhere else in this app is a
/// known backdrop in a known theme. Here what is behind it is a photograph of
/// Mina at some zoom — pale roads, dark hillside, a white sheet where the tiles
/// did not arrive — and a translucent panel over that reads as nothing at all,
/// which is exactly what happened.
///
/// So it is opaque, and it carries its own border and shadow rather than
/// borrowing contrast from a background it cannot predict.
class _MapPanel extends StatelessWidget {
  const _MapPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      // A surface from the theme rather than a fixed colour, so it stays
      // right in both the light theme and the dark one this app defaults to.
      color: scheme.surfaceContainerHighest,
      elevation: 6,
      shadowColor: Colors.black45,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: scheme.outlineVariant),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
  }
}

/// One place, coloured by what is true of it.
///
/// Colour before words: the whole reason to draw the season rather than list it
/// is that a reader takes the shape of it in before he has read anything.
class _PlacePin extends StatelessWidget {
  const _PlacePin({required this.place, required this.onTap});

  final MapPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colour = switch (place.condition) {
      PlaceCondition.incident => scheme.error,
      PlaceCondition.unmanned => scheme.tertiary,
      PlaceCondition.manned => scheme.primary,
      PlaceCondition.empty => scheme.outline,
    };

    return Tooltip(
      message: '${place.placeName} · ${place.moduleName}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: colour,
            shape: BoxShape.circle,
            // A white ring, so a pin stays legible over a dark satellite roof
            // or a pale road — the tiles are somebody else's and we do not get
            // to choose what is underneath.
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(blurRadius: 4, color: Colors.black38),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            // The number of people reported present, which is the one figure
            // worth carrying on the pin itself.
            '${place.present}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _IncidentPin extends StatelessWidget {
  const _IncidentPin({required this.incident, required this.onTap});

  final Incident incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: incident.body,
      child: GestureDetector(
        onTap: onTap,
        child: Icon(
          AppIcons.warning,
          color: scheme.error,
          size: 32,
          shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
        ),
      ),
    );
  }
}

/// What the colours mean, and the two switches that thin the map out.
class _Legend extends StatelessWidget {
  const _Legend({required this.state});

  final SeasonMapState state;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<SeasonMapCubit>();

    return _MapPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // The groups first, because narrowing the map is what a reader came
          // to do — "just the camps of Mina" — and the colour key is what he
          // reads afterwards to interpret what is left.
          if (state.groups.length > 1) ...[
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final group in state.groups)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: AppSpacing.xs,
                      ),
                      child: FilterChip(
                        selected: !state.hiddenGroups.contains(group.key),
                        label: Text(
                          '${group.name.of(context)} · ${group.count}',
                        ),
                        onSelected: (_) => cubit.toggleGroup(group.key),
                        // A long press is the shortcut for the gesture the
                        // filter exists for: switching the other four off one
                        // at a time is the work the map was meant to save.
                        tooltip: l.seasonMapOnlyThis,
                      ),
                    ),
                  if (state.hiddenGroups.isNotEmpty)
                    TextButton(
                      onPressed: cubit.showAllGroups,
                      child: Text(l.seasonMapShowAll),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _Key(colour: scheme.primary, label: l.seasonMapManned),
              _Key(colour: scheme.tertiary, label: l.seasonMapUnmanned),
              _Key(colour: scheme.error, label: l.seasonMapIncident),
              _Key(colour: scheme.outline, label: l.seasonMapEmpty),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.seasonMapCounts(state.places.length, state.incidents.length),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              _Toggle(
                label: l.seasonMapPlaces,
                value: state.showPlaces,
                onChanged: cubit.setShowPlaces,
              ),
              _Toggle(
                label: l.seasonMapIncidents,
                value: state.showIncidents,
                onChanged: cubit.setShowIncidents,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.colour, required this.label});

  final Color colour;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(
        color: colour, shape: BoxShape.circle)),
      const SizedBox(width: AppSpacing.xs),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      Switch(
        value: value,
        onChanged: onChanged,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ],
  );
}
