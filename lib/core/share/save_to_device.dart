import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Whether this device can be asked where to put a file.
///
/// Only the desktops. `file_selector` implements `getSaveLocation` on Windows,
/// macOS and Linux; Android and iOS have no such dialog to open, and the way a
/// file is kept there is the share sheet's own "حفظ في الملفات" — which the
/// share action beside this one already reaches.
///
/// So the menu item is simply not drawn on a phone, rather than drawn and then
/// apologising. The same rule as [isPlaceScannerSupported]: a button that
/// cannot work is worse than no button.
bool get isSaveToDeviceSupported {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;
}

/// What came of asking. [SaveOutcome.cancelled] is not a failure and must not
/// be reported as one — closing the dialog is an answer.
enum SaveOutcome { saved, cancelled, failed }

class SaveResult {
  const SaveResult(this.outcome, {this.path});

  const SaveResult.cancelled() : outcome = SaveOutcome.cancelled, path = null;

  final SaveOutcome outcome;

  /// Where it landed, for the message that says so. Null unless [saved].
  final String? path;
}

/// Asks where to put [bytes] and writes them there.
///
/// The suggested name is what the dialog opens with; whatever the person types
/// instead is what is used, extension and all — this does not correct anybody's
/// filename.
Future<SaveResult> saveToDevice(
  Uint8List bytes, {
  required String suggestedName,
  required String label,
  required String extension,
  required String mimeType,
}) async {
  if (!isSaveToDeviceSupported) return const SaveResult(SaveOutcome.failed);
  try {
    final location = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: [
        XTypeGroup(
          label: label,
          extensions: [extension],
          mimeTypes: [mimeType],
        ),
      ],
    );
    // Null is the dialog being closed, which is a decision rather than a fault.
    if (location == null) return const SaveResult.cancelled();

    await File(location.path).writeAsBytes(bytes, flush: true);
    return SaveResult(SaveOutcome.saved, path: location.path);
  } catch (_) {
    return const SaveResult(SaveOutcome.failed);
  }
}
