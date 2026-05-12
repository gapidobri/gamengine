# Physics Module

Import:

```dart
import 'package:gamengine/physics.dart';
```

## What It Contains

- Components: `RigidBody`, `CircleCollider`, `RectangleCollider`, `GravitySource`
- Systems: `PhysicsSystem`, `CollisionSystem`
- Debug: `PhysicsDebugSettings`, `PhysicsVectorsOverlay`
- Event: `CollisionEvent`

## Basic Setup

```dart
final physics = PhysicsSystem(world: world, gravitationalConstant: 1.0);
final collisions = CollisionSystem(world: world, eventBus: engine.events);

engine.addSystem(physics, 500);
engine.addSystem(collisions, 490);

// Optional (debug): add a render pass and a settings component to enable
// physics vectors overlay.
final renderSystem = engine.systems.whereType<RenderSystem>().first;
renderSystem.addPass(PhysicsVectorsOverlay());

engine.addEntity(
  Entity()..add(PhysicsDebugSettings(enabled: true)),
);
```

## Entity Setup

```dart
final ship = Entity()
  ..add(Transform())
  ..add(RigidBody(mass: 1.2))
  ..add(CircleCollider(radius: 14));

// Optional (debug): override debug visibility per entity.
// - enabled: null  => follow global PhysicsDebugSettings.enabled
// - enabled: true  => force show debug for this entity
// - enabled: false => force hide debug for this entity
ship.add(PhysicsDebugOverride(enabled: false));

final planet = Entity()
  ..add(Transform())
  ..add(GravitySource(mass: 420000, minDistance: 60))
  ..add(CircleCollider(radius: 90));
```

## Collision Filtering

Colliders now support bitmask-based filtering:

- `collisionLayer`: which layer the collider belongs to
- `collisionMask`: which layers it is allowed to collide with

Both colliders must allow the pair for collision resolution to happen.

```dart
const playerLayer = 1 << 0;
const enemyLayer = 1 << 1;
const pickupLayer = 1 << 2;

final player = Entity()
  ..add(Transform())
  ..add(RigidBody())
  ..add(
    CircleCollider(
      radius: 14,
      collisionLayer: playerLayer,
      collisionMask: enemyLayer,
    ),
  );

final pickup = Entity()
  ..add(Transform())
  ..add(
    CircleCollider(
      radius: 8,
      collisionLayer: pickupLayer,
      collisionMask: 0,
    ),
  );
```

In this example, the player can collide with enemies, and the pickup collides
with nothing.

## Collision Consumption

```dart
for (final event in engine.events.read<CollisionEvent>()) {
  // react to impacts (particles, damage, sound)
}
```
