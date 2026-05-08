import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

/// Handles sharing a zikr as plain text or as a rendered image card.
class ShareService {
  ShareService._();

  /// Share the current zikr as formatted Arabic text.
  static Future<void> shareAsText({
    required String arabicText,
    required int repeatCount,
    required String categoryAr,
    required bool isArabic,
  }) async {
    final repeatLine = isArabic
        ? '📿 كرر $repeatCount مرة'
        : '📿 Repeat $repeatCount times';
    final sourceLine = isArabic ? '📖 حصن المسلم' : '📖 Hisn al-Muslim';
    final categoryLine = '🌙 $categoryAr';
    const watermark = '— ضياء · Diyaa';

    final text = '$arabicText\n\n$repeatLine\n$sourceLine\n$categoryLine\n\n$watermark';
    await Share.share(text);
  }

  /// Capture a [RepaintBoundary] widget keyed by [repaintKey] as a PNG and share it.
  static Future<void> shareAsImage(GlobalKey repaintKey) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('[ShareService] RepaintBoundary not found');
        return;
      }

      // Render at 3× pixel ratio for a crisp image
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save to temp directory
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/diyaa_zikr_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: 'ضياء · Diyaa',
      );
    } catch (e) {
      debugPrint('[ShareService] Error sharing as image: $e');
    }
  }
}
