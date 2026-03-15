import 'package:gamengine/gamengine.dart';

class Engine {
  final World world;
  final EventBus events;
  final Commands _commands = Commands();
  final List<System> _systems = <System>[];

  Engine({World? world, EventBus? events})
    : world = world ?? World(),
      events = events ?? EventBus();

  List<System> get systems => _systems;

  void addEntity(Entity entity) {
    world.addEntity(entity);
  }

  void removeEntity(Entity entity) {
    world.removeEntity(entity);
  }

  void addSystem(System system) {
    _systems.add(system);
    _systems.sort((a, b) => b.priority.compareTo(a.priority));
  }

  void removeSystem(System system) {
    _systems.remove(system);
  }

  void update(double dt) {
    events.beginFrame();
    for (final system in _systems) {
      system.update(dt, world, _commands);
    }
    _commands.flush(world);
    events.endFrame();
  }
}
