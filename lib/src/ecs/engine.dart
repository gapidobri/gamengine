import 'package:gamengine/src/ecs/entity.dart';
import 'package:gamengine/src/ecs/events/event_bus.dart';
import 'package:gamengine/src/ecs/system.dart';
import 'package:gamengine/src/ecs/world.dart';
import 'package:gamengine/src/ui/ui_command_queue.dart';

class Engine {
  final World world;
  final EventBus events;
  final UiCommandQueue uiCommands;
  final _systems = <System>[];

  Engine({World? world, EventBus? events, UiCommandQueue? uiCommands})
    : world = world ?? World(),
      events = events ?? EventBus(),
      uiCommands = uiCommands ?? UiCommandQueue();

  void addEntity(Entity entity) {
    world.addEntity(entity);
  }

  void removeEntity(Entity entity) {
    world.removeEntity(entity);
  }

  void addSystem(System system, int priority) {
    _systems.add(system);
    _systems.sort((a, b) => b.priority.compareTo(a.priority));
  }

  void removeSystem(System system) {
    _systems.remove(system);
  }

  void update(double dt) {
    events.beginFrame();
    uiCommands.beginFrame();
    for (final system in _systems) {
      system.update(dt);
    }
    events.endFrame();
    uiCommands.endFrame();
  }
}
