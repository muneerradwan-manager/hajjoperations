import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/responsive.dart';
import '../../export/data/pdf_writer.dart';
import '../domain/check_in.dart';

/// The code for one place, on screen and on paper.
///
/// On paper is the point. This is a sticker for the gate of a camp, and the
/// whole feature is worth nothing until somebody has printed it and walked out
/// to fix it there — so the screen exists mainly to reach the print sheet.
///
/// The page carries the place's NAME in large type beside the code. Whoever is
/// putting forty of these up needs to tell them apart at a glance, and a wall of
/// identical black squares is how a code ends up on the wrong gate — which is
/// the one mistake that makes the whole register lie.
class PlaceCodeScreen extends StatelessWidget {
  const PlaceCodeScreen({
    super.key,
    required this.code,
    required this.placeName,
    required this.moduleName,
  });

  final CheckInCode code;
  final String placeName;
  final String moduleName;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final payload = code.encode();

    return Scaffold(
      appBar: GlassAppBar(title: Text(l.checkInQrTitle)),
      // Capped narrow: the code is a fixed 220 square, and a card stretched
      // across a monitor around it would put the print button a long way from
      // the thing it prints.
      body: ResponsivePage(
        maxWidth: 520,
        builder: (context, size) => SinglePaneLayout(
          gutter: size.gutter,
          children: [
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Text(
                    placeName,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // White behind the code always, in both themes. A QR is read
                  // by contrast, and a dark-mode card would hand the printer a
                  // negative that no phone can scan.
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: QrImageView(
                      data: payload,
                      size: 220,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l.checkInQrHint,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () => Printing.layoutPdf(
              onLayout: (format) => _sheet(format, payload),
              name: 'place-code',
            ),
            icon: const Icon(AppIcons.qrCode),
            label: Text(l.checkInQrPrint),
          ),
          ],
        ),
      ),
    );
  }

  /// One code, one A4 page, as large as the paper allows.
  ///
  /// Deliberately not a sheet of many: these go up one per gate, in different
  /// places, often by different people, and a page holding four codes is a page
  /// somebody cuts up wrongly at two in the morning.
  ///
  /// The place's name is printed **above** the code, large. Whoever is putting
  /// forty of these up is holding a stack of near-identical black squares, and
  /// a code on the wrong gate is the one mistake that makes the entire register
  /// lie — it would record people as present somewhere they have never been.
  /// The name is what stops that, so it is the largest thing on the page after
  /// the code itself.
  Future<Uint8List> _sheet(PdfPageFormat format, String payload) async {
    // The app's own Arabic font, converted to TrueType for exactly this — see
    // PdfWriter. Without it these names print as empty boxes.
    final theme = await PdfWriter.arabicTheme();
    final document = pw.Document(theme: theme);

    document.addPage(
      pw.Page(
        pageFormat: format,
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        build: (context) => pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              placeName,
              style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              moduleName,
              style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 28),
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: payload,
              width: 320,
              height: 320,
              drawText: false,
            ),
            pw.SizedBox(height: 20),
            // The payload in small print underneath. If a code is ever damaged
            // or unreadable in the sun, this is what lets somebody work out
            // which gate the sheet belonged to.
            pw.Text(
              payload,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              textDirection: pw.TextDirection.ltr,
            ),
          ],
        ),
      ),
    );
    return document.save();
  }
}
