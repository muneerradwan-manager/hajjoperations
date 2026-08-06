import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
// XFile comes through share_plus rather than a direct cross_file dependency,
// the way every other caller in this app gets it.
import 'package:share_plus/share_plus.dart';

/// Bytes made into something the platform's share sheet will take.
///
/// The web has no temporary directory — `path_provider` has no implementation
/// there — so the bytes are handed over as they are and the browser's own share
/// or download takes them from memory. Written as a fallback on the FAILURE
/// rather than as a check on `kIsWeb`, because what matters is whether a
/// directory can be had, not which platform is asking.
///
/// Lifted out of the export cubit when the place-code card needed the same
/// thing. One copy, so the web fallback is not re-derived by somebody who does
/// not know it exists — which is exactly how a feature ends up working
/// everywhere but in a browser.
Future<XFile> asShareable(
  Uint8List bytes, {
  required String name,
  required String mimeType,
}) async {
  try {
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/$name';
    await File(path).writeAsBytes(bytes, flush: true);
    return XFile(path, mimeType: mimeType);
  } catch (_) {
    return XFile.fromData(bytes, name: name, mimeType: mimeType);
  }
}
