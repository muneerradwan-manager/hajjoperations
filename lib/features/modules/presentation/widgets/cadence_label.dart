import 'package:flutter/widgets.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../domain/operational_module.dart';

/// What a reporting cadence is called. Its own file because both the editor
/// (choosing one) and the file page (showing it) need the same words.
String cadenceLabel(BuildContext context, ReportCadence cadence) {
  final l = context.l10n;
  return switch (cadence) {
    ReportCadence.none => l.cadenceNone,
    ReportCadence.daily => l.cadenceDaily,
    ReportCadence.weekly => l.cadenceWeekly,
    ReportCadence.once => l.cadenceOnce,
  };
}
