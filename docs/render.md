# Render Module

Import:

```dart
import 'package:gamengine/render.dart';
```

## What It Contains

- Components: `Sprite`, `TiledSprite`, `AnimatedSprite`
- Systems: `RenderSystem`, `SpriteAnimationSystem`, `DebugSystem`
- Runtime: `RenderQueue`, `RenderMetrics`, `CameraState`, `CameraFollowSystem`, `RenderPass`
- Flutter bridge: `GameView` + `Painter`

## Basic Setup

```dart
final queue = RenderQueue();
final camera = CameraState();

engine.addSystem(SpriteAnimationSystem(world: world), 950);
engine.addSystem(
  RenderSystem(
    queue: queue,
    camera: camera,
  ),
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

## Custom Render Passes

`RenderSystem` owns the main render pipeline, but you can inject custom drawing
through `RenderPass` implementations. Passes write into the shared
`RenderQueue`, so they use the same ordering and painter as the built-in world
renderer.

```dart
class OffscreenIndicatorPass extends RenderPass {
  const OffscreenIndicatorPass();

  @override
  int get priority => 100;

  @override
  RenderPassStage get stage => RenderPassStage.afterWorld;

  @override
  void write(
    World world, {
    required CameraState camera,
    required RenderQueue queue,
  }) {
    final viewRect = camera.worldViewRect;
    final center = viewRect.center;
    final edgeRect = viewRect.deflate(24);

    for (final entity in world.query1<Transform>()) {
      final transform = entity.get<Transform>();
      final target = Offset(transform.position.x, transform.position.y);
      if (viewRect.contains(target)) {
        continue;
      }

      final dx = target.dx - center.dx;
      final dy = target.dy - center.dy;
      if (dx == 0 && dy == 0) {
        continue;
      }

      final scaleX = dx == 0
          ? double.infinity
          : (edgeRect.width * 0.5) / dx.abs();
      final scaleY = dy == 0
          ? double.infinity
          : (edgeRect.height * 0.5) / dy.abs();
      final t = scaleX < scaleY ? scaleX : scaleY;

      queue.add(
        DrawCircleCommand(
          center: Offset(center.dx + dx * t, center.dy + dy * t),
          radius: 8,
          z: 10_000,
        ),
      );
    }
  }
}

final renderSystem = RenderSystem(
  queue: queue,
  camera: camera,
  passes: const [OffscreenIndicatorPass()],
);
```

Use `RenderPassStage.beforeWorld` for background-style passes and
`RenderPassStage.afterWorld` for overlays such as indicators or debug markers.
