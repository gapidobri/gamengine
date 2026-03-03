# Core ECS Module

Import:

```dart
import 'package:gamengine/ecs.dart';
```

## What It Contains

- `Engine`: runs systems in priority order.
- `World`: stores entities and queries component sets.
- `Entity`: component container.
- `System`: update behavior (`update(double dt)`).
- `Transform`: shared position/rotation/scale component.
- `EventBus`: frame-buffered gameplay events (`emit`, `read<T>()`).

## Minimal Example

```dart
class Health extends Component {
  double value;
  Health(this.value);
}

class RegenSystem extends System {
  final World world;
  RegenSystem(this.world);

  @override
  int get priority => 100;

  @override
  void update(double dt) {
    for (final e in world.query2<Transform, Health>()) {
      final hp = world.get<Health>(e);
      hp.value += 1.0 * dt;
    }
  }
}

final world = World();
final engine = Engine(world: world);
final entity = Entity()
  ..add(Transform())
  ..add(Health(10));

engine.addEntity(entity);
engine.addSystem(RegenSystem(world), 100);
engine.update(1 / 60);
```

## Events Example

```dart
class HitEvent extends GameEvent {
  final Entity target;
  HitEvent(this.target);
}

engine.events.emit(HitEvent(entity));

for (final hit in engine.events.read<HitEvent>()) {
  // read events from previous frame
}
```
