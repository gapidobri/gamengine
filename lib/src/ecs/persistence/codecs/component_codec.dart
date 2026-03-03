import 'package:gamengine/src/ecs/components/component.dart';

abstract class ComponentCodec<T extends Component> {
  String get typeId;

  Map<String, Object?> encode(T component);

  T decode(Map<String, Object?> data);
}
