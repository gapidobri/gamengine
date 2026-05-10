import 'package:gamengine/gamengine.dart';

class Engine {
  final World world;
  final EventBus eventBus;
  final Commands _commands = Commands();
  final List<System> _systems = <System>[];

  bool paused = false;

  Engine({World? world, EventBus? eventBus})
    : world = world ?? World(),
      eventBus = eventBus ?? EventBus();

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
    system.dispose();
    _systems.remove(system);
  }

  void update(double dt) {
    if (paused) dt = 0;
    eventBus.beginFrame();
    for (final system in _systems) {
      if (paused && !system.runWhenPaused) continue;
      system.update(dt, world, _commands);
    }
    _commands.flush(world);
    eventBus.endFrame();
  }

  void dispose() {
    for (final system in systems) {
      system.dispose();
    }
  }
}
