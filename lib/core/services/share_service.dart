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

  /// Global flag to check if the app is currently showing the sharing interface.
  static bool isSharing = false;

  /// Share the current zikr as formatted Arabic text.
  static Future<void> shareAsText({
    required String arabicText,
    required int repeatCount,
    required String categoryAr,
    required bool isArabic,
  }) async {
    isSharing = true;
    try {
      final repeatLine = isArabic
          ? '📿 كرر $repeatCount مرة'
          : '📿 Repeat $repeatCount times';
      final sourceLine = isArabic ? '📖 حصن المسلم' : '📖 Hisn al-Muslim';
      final categoryLine = '🌙 $categoryAr';
      const watermark = '— ضياء · Diyaa';

      final text = '$arabicText\n\n$repeatLine\n$sourceLine\n$categoryLine\n\n$watermark';
      await Share.share(text).catchError((e) {
        debugPrint('[ShareService] Error sharing text: $e');
        return const ShareResult('', ShareResultStatus.unavailable);
      });
    } finally {
      Future.delayed(const Duration(milliseconds: 500), () {
        isSharing = false;
      });
    }
  }

  /// Captures a [RepaintBoundary] widget keyed by [repaintKey] as a PNG file.
  static Future<File?> captureAsFile(GlobalKey repaintKey) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('[ShareService] RepaintBoundary not found');
        return null;
      }

      // Render at 3× pixel ratio for a crisp image
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save to temp directory
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/diyaa_zikr_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);
      return file;
    } catch (e) {
      debugPrint('[ShareService] Error capturing image: $e');
      return null;
    }
  }

  /// Invokes the native share sheet with the specified image file.
  static Future<void> shareImageFile(File file) async {
    isSharing = true;
    try {
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: 'ضياء · Diyaa',
      ).catchError((e) {
        debugPrint('[ShareService] Error sharing image: $e');
        return const ShareResult('', ShareResultStatus.unavailable);
      });
    } finally {
      Future.delayed(const Duration(milliseconds: 500), () {
        isSharing = false;
      });
    }
  }

  /// Capture a [RepaintBoundary] widget keyed by [repaintKey] as a PNG and share it.
  static Future<void> shareAsImage(GlobalKey repaintKey) async {
    final file = await captureAsFile(repaintKey);
    if (file != null) {
      await shareImageFile(file);
    }
  }
}
