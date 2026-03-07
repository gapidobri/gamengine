# UI Hooks Module

Import:

```dart
import 'package:gamengine/ui.dart';
```

## What It Contains

- `HudStateStore<T>`: `ValueNotifier` for UI-facing immutable state.
- `HudPresenterSystem<T>`: projects `World` state into HUD state.

## HUD Projection Example

```dart
class HudData {
  final double speed;
  const HudData(this.speed);
}

final hudStore = HudStateStore(const HudData(0));

engine.addSystem(
  HudPresenterSystem<HudData>(
    world: world,
    output: hudStore,
    project: (w) {
      // compute from ECS
      return const HudData(42);
    },
  ),
  910,
);
```

Flutter side:

```dart
ValueListenableBuilder<HudData>(
  valueListenable: hudStore,
  builder: (context, hud, _) => Text('Speed: ${hud.speed}'),
);
```
