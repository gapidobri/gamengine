import 'package:gamengine/gamengine.dart';

abstract class Drawable extends Component {
  int z;
  PaintConfig? paint;

  Drawable({this.z = 0, this.paint});
}
