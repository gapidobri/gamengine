# Gamengine Docs

This folder documents all public engine modules exported by `lib/gamengine.dart`.

## Modules

- [Core ECS](./ecs.md)
- [Physics](./physics.md)
- [Render](./render.md)
- [Assets](./asset.md)
- [UI Hooks](./ui.md)
- [Persistence](./persistence.md)

## Quick Start

```dart
import 'package:gamengine/gamengine.dart';

final world = World();
final engine = Engine(world: world);

engine.addSystem(
  PhysicsSystem(world: world),
  500,
);

engine.update(1 / 60);
```

## Notes

- Entities are lightweight component containers.
- Systems hold behavior and run by priority (higher runs first).
- Use persistence for save/load and optional system snapshots.
