import 'package:gamengine/src/ecs/commands.dart';
import 'package:gamengine/src/ecs/world.dart';

abstract class System {
  System({this.priority = 0});

  int priority;

  void update(double dt, World world, Commands commands) {}
}
