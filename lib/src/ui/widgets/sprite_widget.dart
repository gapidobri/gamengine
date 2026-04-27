import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gamengine/src/assets/asset_manager.dart';

/// Paints a sprite from a decoded [ui.Image], optionally using an atlas slice.
///
/// For frequently updated HUD/gameplay visuals, prefer passing a preloaded image
/// from [AssetManager] instead of loading by asset path inside a widget tree.
class SpriteWidget extends StatelessWidget {
  const SpriteWidget({
    super.key,
    required this.image,
    this.sourceRect,
    this.width,
    this.height,
    this.fit = BoxFit.fill,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.none,
    this.paint,
  });

  final ui.Image image;
  final Rect? sourceRect;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final Paint? paint;

  @override
  Widget build(BuildContext context) {
    final src = _resolvedSourceRect(image, sourceRect);
    final resolvedSize = _resolvedSize(src, width: width, height: height);

    return SizedBox(
      width: resolvedSize.width,
      height: resolvedSize.height,
      child: CustomPaint(
        painter: _SpritePainter(
          image: image,
          sourceRect: src,
          outputSize: resolvedSize,
          fit: fit,
          alignment: alignment,
          filterQuality: filterQuality,
          spritePaint: paint,
        ),
      ),
    );
  }

  static Rect _resolvedSourceRect(ui.Image image, Rect? src) {
    final full = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    if (src == null) {
      return full;
    }

    final clipped = src.intersect(full);
    if (clipped.width <= 0 || clipped.height <= 0) {
      return full;
    }
    return clipped;
  }

  static Size _resolvedSize(
    Rect sourceRect, {
    required double? width,
    required double? height,
  }) {
    if (width != null && height != null) {
      return Size(width, height);
    }

    if (width != null) {
      final ratio = sourceRect.height / sourceRect.width;
      return Size(width, width * ratio);
    }

    if (height != null) {
      final ratio = sourceRect.width / sourceRect.height;
      return Size(height * ratio, height);
    }

    return sourceRect.size;
  }
}

/// Convenience wrapper that loads an asset image via [AssetManager].
///
/// This is useful for low-frequency UI; for hot update paths, prefer preloading
/// with [AssetManager] and using [SpriteWidget] directly.
class AssetSpriteWidget extends StatefulWidget {
  const AssetSpriteWidget({
    super.key,
    required this.assetManager,
    required this.assetPath,
    this.package,
    this.sourceRect,
    this.width,
    this.height,
    this.fit = BoxFit.fill,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.none,
    this.paint,
    this.placeholder,
  });

  final AssetManager assetManager;
  final String assetPath;
  final String? package;
  final Rect? sourceRect;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final Paint? paint;
  final Widget? placeholder;

  @override
  State<AssetSpriteWidget> createState() => _AssetSpriteWidgetState();
}

class _AssetSpriteWidgetState extends State<AssetSpriteWidget> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant AssetSpriteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath ||
        oldWidget.package != widget.package ||
        oldWidget.assetManager != widget.assetManager) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final image = await widget.assetManager.loadImage(
      widget.assetPath,
      package: widget.package,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _image = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.placeholder,
      );
    }

    return SpriteWidget(
      image: image,
      sourceRect: widget.sourceRect,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      filterQuality: widget.filterQuality,
      paint: widget.paint,
    );
  }
}

class _SpritePainter extends CustomPainter {
  _SpritePainter({
    required this.image,
    required this.sourceRect,
    required this.outputSize,
    required this.fit,
    required this.alignment,
    required this.filterQuality,
    required this.spritePaint,
  });

  final ui.Image image;
  final Rect sourceRect;
  final Size outputSize;
  final BoxFit fit;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final Paint? spritePaint;

  @override
  void paint(Canvas canvas, Size size) {
    final inputSize = Size(sourceRect.width, sourceRect.height);
    final fitted = applyBoxFit(fit, inputSize, size);

    final src = alignment.inscribe(fitted.source, sourceRect);
    final dst = alignment.inscribe(fitted.destination, Offset.zero & size);

    final resolvedPaint = spritePaint ?? Paint();
    resolvedPaint.filterQuality = filterQuality;

    canvas.drawImageRect(image, src, dst, resolvedPaint);
  }

  @override
  bool shouldRepaint(covariant _SpritePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.sourceRect != sourceRect ||
        oldDelegate.outputSize != outputSize ||
        oldDelegate.fit != fit ||
        oldDelegate.alignment != alignment ||
        oldDelegate.filterQuality != filterQuality ||
        oldDelegate.spritePaint != spritePaint;
  }
}
