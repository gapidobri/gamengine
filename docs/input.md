# Input

The input module converts raw hardware events into gameplay-facing actions.

## Overview

- `RawInputEvent`: physical input events captured by the view layer.
- `InputKeymap<T>`: maps physical keys to actions of type `T`.
- `InputActionState<T>`: frame-based action state (`isPressed`, `justPressed`, `justReleased`).
- `InputEvent<T>`: optional event stream for action transitions.
- `InputSystem<T>`: updates `InputActionState` and emits `InputEvent` from `RawInputEvent`.

## Recommended Flow

1. Emit `RawInputEvent` from the platform/view layer.
2. Run `InputSystem<T>` early in the frame.
3. Gameplay systems read `InputActionState<T>` directly.
4. Optional: consume `InputEvent<T>` for one-shot reactions (UI/audio).

## Example

```dart
final inputState = InputActionState<PlayerAction>();

engine.addSystem(
  InputSystem<PlayerAction>(
    eventBus: engine.events,
    actionState: inputState,
    keymap: InputKeymap<PlayerAction>()
      ..registerAction(action: PlayerAction.moveLeft, keys: [LogicalKeyboardKey.keyA])
      ..registerAction(action: PlayerAction.moveRight, keys: [LogicalKeyboardKey.keyD]),
  ),
);

if (inputState.isPressed(PlayerAction.moveLeft)) {
  // apply movement this frame
}
```
