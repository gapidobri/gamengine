import 'package:gamengine/src/ecs/components/component.dart';

class Entity {
  static int _nextId = 0;

  Entity({int? id}) : _id = id ?? _nextId++ {
    if (_id > _nextId) {
      _nextId = _id + 1;
    }
  }

  final int _id;
  final _components = <Type, Component>{};

  int get id => _id;

  Iterable<Component> get components => _components.values;

  void add(Component component) {
    _components[component.runtimeType] = component;
  }

  void remove<T>() {
    _components.remove(T);
  }

  T get<T extends Component>() {
    return _components[T]! as T;
  }

  T? tryGet<T extends Component>() {
    return _components[T] as T?;
  }

  bool has<T extends Component>() {
    return tryGet<T>() != null;
  }
}
