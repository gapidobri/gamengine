import 'package:gamengine/src/ecs/system.dart';
import 'package:gamengine/src/ecs/world.dart';
import 'package:gamengine/src/ui/hud_state_store.dart';

typedef HudProjector<T> = T Function(World world);

class HudPresenterSystem<T> extends System {
  final World world;
  final HudStateStore<T> output;
  final HudProjector<T> project;
  final int _priority;

  HudPresenterSystem({
    required this.world,
    required this.output,
    required this.project,
    int priority = 900,
  }) : _priority = priority;

  @override
  int get priority => _priority;

  @override
  void update(double dt) {
    output.setIfChanged(project(world));
  }
}
