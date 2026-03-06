import 'package:gamengine/src/render/components/drawable.dart';

class CircleShape extends Drawable {
  double radius;

  CircleShape({required this.radius, required super.paint, super.z});
}
