import 'dart:ui';

import 'package:gamengine/src/ecs/components/component.dart';

class Sprite extends Component {
  bool visible;
  Image? image;
  Rect? sourceRect;

  Sprite({this.visible = true, this.image, this.sourceRect});
}
