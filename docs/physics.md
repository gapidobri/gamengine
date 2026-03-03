# Physics Module

Import:

```dart
import 'package:gamengine/physics.dart';
```

## What It Contains

- Components: `RigidBody`, `Collider`, `GravitySource`
- Systems: `PhysicsSystem`, `CollisionSystem`
- Debug: `PhysicsDebugSystem`, `PhysicsVectorsOverlay`
- Event: `CollisionEvent`

## Basic Setup

```dart
final physics = PhysicsSystem(world: world, gravitationalConstant: 1.0);
final collisions = CollisionSystem(world: world, eventBus: engine.events);

engine.addSystem(physics, 500);
engine.addSystem(collisions, 490);
```

## Entity Setup

```dart
final ship = Entity()
  ..add(Transform())
  ..add(RigidBody(mass: 1.2))
  ..add(Collider(radius: 14));

final planet = Entity()
  ..add(Transform())
  ..add(GravitySource(mass: 420000, minDistance: 60))
  ..add(Collider(radius: 90));
```

## Collision Consumption

```dart
for (final event in engine.events.read<CollisionEvent>()) {
  // react to impacts (particles, damage, sound)
}
```
