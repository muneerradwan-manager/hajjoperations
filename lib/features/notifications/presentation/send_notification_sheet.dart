import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../data/notifications_repository.dart';
import '../domain/app_notification.dart';
import 'widgets/attachment_view.dart';

/// Compose + send a notification to a single recipient.
Future<void> showSendNotificationSheet(
  BuildContext context, {
  required String recipientId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _Form(recipientId: recipientId),
    ),
  );
}

class _Form extends StatefulWidget {
  const _Form({required this.recipientId});
  final String recipientId;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _repo = NotificationsRepository();
  final _attachments = <PendingAttachment>[];
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _add(PendingAttachment attachment) =>
      setState(() => _attachments.add(attachment));

  /// A photo, from the camera or the roll. Goes through `image_picker` rather
  /// than the file browser: on a phone this is the common case and it should
  /// take one tap, not a trip through the file system.
  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return;
    _add(
      PendingAttachment(
        file: File(picked.path),
        name: picked.name,
        kind: AttachmentKind.image,
        mimeType: picked.mimeType ?? 'image/jpeg',
      ),
    );
  }

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    _add(
      PendingAttachment(
        file: File(picked.path),
        name: picked.name,
        kind: AttachmentKind.video,
        mimeType: picked.mimeType ?? 'video/mp4',
      ),
    );
  }

  /// Audio and anything else, through the file browser. [kind] is what the
  /// sender said they were attaching — the recipient's app shows a voice note
  /// as a voice note because of this, not because of the file extension.
  Future<void> _pickFile(AttachmentKind kind) async {
    final result = await FilePicker.platform.pickFiles(
      type: kind == AttachmentKind.audio ? FileType.audio : FileType.any,
      withData: false,
    );
    final picked = result?.files.singleOrNull;
    if (picked?.path == null) return;
    _add(
      PendingAttachment(
        file: File(picked!.path!),
        name: picked.name,
        kind: kind,
      ),
    );
  }

  Future<void> _showAttachMenu() async {
    final l = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (icon, label, action) in <(IconData, String, VoidCallback)>[
              (
                AppIcons.camera,
                l.notificationAttachCamera,
                () => _pickImage(ImageSource.camera),
              ),
              (
                AppIcons.image,
                l.notificationAttachPhoto,
                () => _pickImage(ImageSource.gallery),
              ),
              (AppIcons.video, l.notificationAttachVideo, _pickVideo),
              (
                AppIcons.audio,
                l.notificationAttachAudio,
                () => _pickFile(AttachmentKind.audio),
              ),
              (
                AppIcons.file,
                l.notificationAttachFile,
                () => _pickFile(AttachmentKind.file),
              ),
            ])
              ListTile(
                leading: Icon(icon),
                title: Text(label),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  action();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await _repo.send(
        recipientId: widget.recipientId,
        title: _title.text.trim(),
        body: _body.text.trim().isEmpty ? null : _body.text.trim(),
        attachments: _attachments,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.l10n.notificationSent)));
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.notificationSend,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              decoration: InputDecoration(
                labelText: l.notificationTitleField,
                prefixIcon: const Icon(AppIcons.notifications),
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l.commonRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _body,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l.notificationBodyField,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: _busy ? null : _showAttachMenu,
                icon: const Icon(AppIcons.attach, size: 18),
                label: Text(l.notificationAttach),
              ),
            ),
            for (var i = 0; i < _attachments.length; i++)
              _PendingRow(
                attachment: _attachments[i],
                onRemove: _busy
                    ? null
                    : () => setState(() => _attachments.removeAt(i)),
              ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _busy ? null : _send,
              icon: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(AppIcons.send),
              label: Text(l.notificationSend),
            ),
          ],
        ),
      ),
    );
  }
}

/// One file already chosen, with the way to change your mind about it.
class _PendingRow extends StatelessWidget {
  const _PendingRow({required this.attachment, this.onRemove});

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
          Icon(
            attachmentIcon(attachment.kind),
            size: 18,
            color: scheme.primary,
          ),
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
