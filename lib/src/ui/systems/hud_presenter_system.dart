import 'package:gamengine/gamengine.dart';

typedef HudProjector<T> = T Function(World world);

class HudPresenterSystem<T> extends System {
  final HudStateStore<T> output;
  final HudProjector<T> project;
  final int _priority;

  HudPresenterSystem({
    required this.output,
    required this.project,
    int priority = 900,
  }) : _priority = priority;

  @override
  int get priority => _priority;

  @override
  void update(double dt, World world, Commands commands) {
    output.setIfChanged(project(world));
  }
}
