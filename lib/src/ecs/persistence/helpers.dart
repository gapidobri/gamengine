import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:gamengine/gamengine.dart';

List<Object?> encodeVector2(Vector2 value) => <Object?>[value.x, value.y];

Vector2 decodeVector2(
  Map<String, Object?> data,
  String key, {
  Vector2? fallback,
}) {
  final value = data[key];
  if (value is List && value.length >= 2) {
    final x = (value[0] as num?)?.toDouble();
    final y = (value[1] as num?)?.toDouble();
    if (x != null && y != null) {
      return Vector2(x, y);
    }
  }
  if (fallback != null) {
    return Vector2.copy(fallback);
  }
  return Vector2.zero();
}

List<double>? encodeColor(Color? color) =>
    color != null ? [color.r, color.g, color.b, color.a] : null;

Color? decodeColor(Object? value) {
  if (value is List && value.length >= 4) {
    final [r, g, b, a] = List<double>.from(value);
    return Color.from(alpha: a, red: r, green: g, blue: b);
  }
  return null;
}

Map<String, dynamic>? encodePaint(PaintConfig? paint) {
  if (paint == null) {
    return null;
  }
  return {
    'color': encodeColor(paint.color),
    'style': paint.style.name,
    'strokeWidth': paint.strokeWidth,
    'maskFilter': paint.maskFilter != null
        ? {
            'blurStyle': paint.maskFilter!.blurStyle.name,
            'sigma': paint.maskFilter!.sigma,
          }
        : null,
  };
}

PaintConfig? decodePaint(Map<String, Object?> data, String key) {
  final value = data[key];
  if (value == null || value is! Map<String, dynamic>) {
    return null;
  }

  final paintConfig = PaintConfig()..strokeWidth = value['strokeWidth'];

  if (value['color'] != null) {
    paintConfig.color = decodeColor(value['color'])!;
  }

  final style = PaintingStyle.values.firstWhereOrNull(
    (v) => v.name == value['style'],
  );
  if (style != null) {
    paintConfig.style = style;
  }

  final maskFilter = value['maskFilter'];
  if (maskFilter != null) {
    paintConfig.maskFilter = MaskFilterConfig.blur(
      BlurStyle.values.firstWhere((v) => v.name == maskFilter['blurStyle']),
      maskFilter['sigma'],
    );
  }

  return paintConfig;
}

List<double>? encodeRect(Rect? rect) =>
    rect != null ? [rect.left, rect.top, rect.right, rect.bottom] : null;

Rect? decodeRect(Map<String, Object?> data, String key) {
  final value = data[key] as List<dynamic>?;
  if (value == null) {
    return null;
  }
  return Rect.fromLTRB(value[0], value[1], value[2], value[3]);
}

List<double> encodeSize(Size size) => [size.width, size.height];

Size? decodeSize(Map<String, Object?> data, String key) {
  final value = data[key] as List<dynamic>?;
  if (value == null) {
    return null;
  }
  final list = List<double>.from(value);
  return Size(list[0], list[1]);
}

List<double>? encodeOffset(Offset? offset) =>
    offset != null ? [offset.dx, offset.dy] : null;

Offset? decodeOffset(Map<String, Object?> data, String key) {
  final value = data[key] as List<dynamic>?;
  if (value == null) {
    return null;
  }
  final list = List<double>.from(value);
  return Offset(list[0], list[1]);
}

double? decodeDouble(Map<String, Object?> data, String key) {
  final value = data[key];
  return value is num ? value.toDouble() : null;
}

int? decodeInt(Map<String, Object?> data, String key) {
  final value = data[key];
  return value is num ? value.toInt() : null;
}

bool? decodeBool(Map<String, Object?> data, String key) {
  final value = data[key];
  return value is bool ? value : null;
}

Map<String, Object?>? encodeImage(Asset<Image>? image) =>
    image != null ? {'path': image.path, 'package': image.package} : null;

Asset<Image> decodeImage(Map<String, Object?> data, String key) {
  final value = data[key] as Map<String, dynamic>;
  return Asset<Image>(
    path: value['path'] as String,
    package: value['package'] as String?,
  );
}
