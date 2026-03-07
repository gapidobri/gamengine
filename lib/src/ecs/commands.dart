import 'package:gamengine/gamengine.dart';

abstract class _Command {
  void apply(World world);
}

class _SpawnCommand implements _Command {
  const _SpawnCommand(this.entity);

  final Entity entity;

  @override
  void apply(World world) => world.addEntity(entity);
}

class _DespawnCommand implements _Command {
  const _DespawnCommand(this.entity);

  final Entity entity;

  @override
  void apply(World world) => world.removeEntity(entity);
}

class _AddComponentCommand implements _Command {
  const _AddComponentCommand(this.entity, this.component);

  final Entity entity;
  final Component component;

  @override
  void apply(World world) => entity.add(component);
}

class _RemoveComponentCommand<T extends Component> implements _Command {
  const _RemoveComponentCommand(this.entity);

  final Entity entity;

  @override
  void apply(World world) => entity.remove<T>();
}

class Commands {
  final List<_Command> _queue = <_Command>[];

  void spawn(Entity entity) => _queue.add(_SpawnCommand(entity));

  void despawn(Entity entity) => _queue.add(_DespawnCommand(entity));

  void addComponent<T extends Component>(Entity entity, T component) =>
      _queue.add(_AddComponentCommand(entity, component));

  void removeComponent<T extends Component>(Entity entity) =>
      _queue.add(_RemoveComponentCommand<T>(entity));

  void flush(World world) {
    for (final cmd in _queue) {
      cmd.apply(world);
    }
    _queue.clear();
  }

  bool get isEmpty => _queue.isEmpty;
}
