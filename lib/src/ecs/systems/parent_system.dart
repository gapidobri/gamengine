import 'package:gamengine/gamengine.dart';

class ParentSystem extends System {
  @override
  void update(double dt, World world, Commands commands) {
    for (final entity in world.query<Parent>()) {
      final parent = entity.get<Parent>();
      if (!world.entities.contains(parent.parent)) {
        commands.despawn(entity);
      }
    }
  }
}
