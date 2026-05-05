import 'dart:ui';

class PaintConfig {
  Color color = Paint().color;
  PaintingStyle style = .fill;
  double strokeWidth = 0;
  MaskFilterConfig? maskFilter;

  Paint toPaint() {
    final paint = Paint();
    paint.color = color;
    paint.strokeWidth = strokeWidth;
    paint.style = style;
    if (maskFilter != null) {
      paint.maskFilter = MaskFilter.blur(
        maskFilter!.blurStyle,
        maskFilter!.sigma,
      );
    }
    return paint;
  }
}

class MaskFilterConfig {
  const MaskFilterConfig.blur(this.blurStyle, this.sigma);

  final BlurStyle blurStyle;
  final double sigma;
}
