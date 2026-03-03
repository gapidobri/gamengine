# Render Module

Import:

```dart
import 'package:gamengine/render.dart';
```

## What It Contains

- Components: `Sprite`, `AnimatedSprite`, `ParticleEmitter`
- Systems: `RenderSystem`, `SpriteAnimationSystem`, `ParticleSystem`, `DebugSystem`
- Runtime: `RenderQueue`, `RenderMetrics`, `CameraState`, `CameraFollowSystem`
- Flutter bridge: `GameView` + `Painter`

## Basic Setup

```dart
final queue = RenderQueue();
final camera = CameraState();
final particles = ParticleSystem(world: world);

engine.addSystem(SpriteAnimationSystem(world: world), 950);
engine.addSystem(particles, 480);
engine.addSystem(
  RenderSystem(
    world: world,
    queue: queue,
    camera: camera,
    particleSystem: particles,
  ),
  1000,
);
```

## Widget Usage

```dart
GameView(
  engine: engine,
  queue: queue,
  camera: camera,
);
```

## Atlas Batching

`Painter` automatically batches eligible sprite draw calls through Flutter atlas rendering when:

- same `Image`
- same `z`
- uniform positive scale (`scaleX ~= scaleY`)

Non-eligible sprites fall back to per-sprite drawing.
