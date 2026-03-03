import 'package:gamengine/src/ecs/components/component.dart';

class Entity {
  final _components = <Type, Component>{};

  Iterable<Component> get components => _components.values;

  void add(Component component) {
    _components[component.runtimeType] = component;
  }

  void remove(Type componentType) {
    _components.remove(componentType);
  }

  T? get<T extends Component>() {
    return _components[T] as T?;
  }
}
