import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/l10n_extension.dart';
import '../theme/app_icons.dart';
import '../theme/glass_tokens.dart';
import 'attachment.dart';

export 'attachment.dart';

/// Where a file is being taken from. Not the same thing as [AttachmentKind]:
/// a photo may come from the camera or the roll, and either way it is an image.
enum _AttachSource { camera, photo, video, audio, file }

/// Asks what to attach, then attaches it. Null when the user backs out of
/// either step.
///
/// One implementation for the whole app: a report and a notification pick files
/// the same way, and the menu — camera first, because on a phone that is the
/// common case — should not drift between them.
Future<PendingAttachment?> pickAttachment(BuildContext context) async {
  final source = await _chooseSource(context);
  if (source == null) return null;

  final picked = await switch (source) {
    _AttachSource.camera => _pickImage(ImageSource.camera),
    _AttachSource.photo => _pickImage(ImageSource.gallery),
    _AttachSource.video => _pickVideo(),
    _AttachSource.audio => _pickFile(AttachmentKind.audio),
    _AttachSource.file => _pickFile(AttachmentKind.file),
  };
  if (picked == null) return null;

  if (!await _isWithinSizeLimit(picked)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(context.l10n.attachmentTooLarge(_readableSizeLimit)),
          ),
        );
    }
    return null;
  }
  return picked;
}

/// The most an attachment may weigh.
///
/// A photo is already held under this by the bounds in [_pickImage]; a video, a
/// voice note and a document are not bounded by anything, and a minute of 4K
/// off a current phone is well past a hundred megabytes. Two things then go
/// wrong at once: the upload cannot finish on a field network, and the storage
/// bucket refuses it at 50MiB anyway (`supabase/config.toml`) with an error
/// that says nothing useful to the man holding the phone.
///
/// So the refusal is made here, before the upload starts, in words. Set well
/// under the server's ceiling rather than at it: a file that only just fits is
/// a file that will not arrive from Mina.
const _maxAttachmentBytes = 25 * 1024 * 1024;
const _readableSizeLimit = '25 MB';

Future<bool> _isWithinSizeLimit(PendingAttachment attachment) async {
  try {
    return await attachment.file.length() <= _maxAttachmentBytes;
  } on FileSystemException {
    // Unreadable here does not mean too large. Let the upload be the thing
    // that fails, and fail with its own reason.
    return true;
  }
}

Future<_AttachSource?> _chooseSource(BuildContext context) {
  final l = context.l10n;
  return showModalBottomSheet<_AttachSource>(
    context: context,
    // Over the rail as well as the page — see [showAppSheet].
    useRootNavigator: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (icon, label, source) in <(IconData, String, _AttachSource)>[
            (AppIcons.camera, l.notificationAttachCamera, _AttachSource.camera),
            (AppIcons.image, l.notificationAttachPhoto, _AttachSource.photo),
            (AppIcons.video, l.notificationAttachVideo, _AttachSource.video),
            (AppIcons.audio, l.notificationAttachAudio, _AttachSource.audio),
            (AppIcons.file, l.notificationAttachFile, _AttachSource.file),
          ])
            ListTile(
              leading: Icon(icon),
              title: Text(label),
              onTap: () => Navigator.of(sheetContext).pop(source),
            ),
        ],
      ),
    ),
  );
}

/// The longest edge an attached photo is allowed to keep.
///
/// Deliberately larger than the 1600 a profile portrait is held to: half of
/// what gets attached in the field is a photograph OF WRITING — a decision
/// letter, a bus manifest, a sign on a camp gate — and shrinking that far can
/// take the writing below the point where it can be read at all. 2048 keeps it
/// legible.
const _maxImageEdge = 2048.0;

/// Quality of the re-encode. 80 is where the artefacts stop being visible on a
/// photograph of a page, and the difference between 80 and 95 is most of the
/// file.
const _imageQuality = 80;

/// A photo, from the camera or the roll. Goes through `image_picker` rather
/// than the file browser: on a phone this is the common case and it should take
/// one tap, not a trip through the file system.
///
/// The bounds are not a nicety. Unbounded, a current phone hands back four to
/// six megabytes per shot, and the network these are attached on is the one in
/// Mina during the days of Tashreeq — the worst network of the year carrying
/// the most important attachments of the year. Bounded, the same photograph is
/// a few hundred kilobytes and still says everything it was taken to say.
Future<PendingAttachment?> _pickImage(ImageSource source) async {
  final picked = await ImagePicker().pickImage(
    source: source,
    maxWidth: _maxImageEdge,
    maxHeight: _maxImageEdge,
    imageQuality: _imageQuality,
  );
  if (picked == null) return null;
  return PendingAttachment(
    file: File(picked.path),
    name: picked.name,
    kind: AttachmentKind.image,
    mimeType: picked.mimeType ?? 'image/jpeg',
  );
}

Future<PendingAttachment?> _pickVideo() async {
  final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
  if (picked == null) return null;
  return PendingAttachment(
    file: File(picked.path),
    name: picked.name,
    kind: AttachmentKind.video,
    mimeType: picked.mimeType ?? 'video/mp4',
  );
}

/// Audio and anything else, through the file browser. [kind] is what the person
/// said they were attaching — the reader's app shows a voice note as a voice
/// note because of this, not because of the file extension.
Future<PendingAttachment?> _pickFile(AttachmentKind kind) async {
  final result = await FilePicker.platform.pickFiles(
    type: kind == AttachmentKind.audio ? FileType.audio : FileType.any,
    withData: false,
  );
  final picked = result?.files.singleOrNull;
  if (picked?.path == null) return null;
  return PendingAttachment(
    file: File(picked!.path!),
    name: picked.name,
    kind: kind,
  );
}

/// One file already chosen, with the way to change your mind about it.
class PendingAttachmentRow extends StatelessWidget {
  const PendingAttachmentRow({
    super.key,
    required this.attachment,
    this.onRemove,
  });

  final PendingAttachment attachment;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(attachmentIcon(attachment.kind), size: 18, color: scheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              attachment.name,
              style: text.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: context.l10n.commonDelete,
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
            icon: const Icon(AppIcons.delete, size: 16),
          ),
        ],
      ),
    );
  }
}

IconData attachmentIcon(AttachmentKind kind) => switch (kind) {
  AttachmentKind.image => AppIcons.image,
  AttachmentKind.video => AppIcons.video,
  AttachmentKind.audio => AppIcons.audio,
  AttachmentKind.file => AppIcons.file,
};

String attachmentKindLabel(BuildContext context, AttachmentKind kind) {
  final l = context.l10n;
  return switch (kind) {
    AttachmentKind.image => l.attachmentImage,
    AttachmentKind.video => l.attachmentVideo,
    AttachmentKind.audio => l.attachmentAudio,
    AttachmentKind.file => l.attachmentFile,
  };
}
