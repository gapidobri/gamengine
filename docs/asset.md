# Asset Module

Import:

```dart
import 'package:gamengine/asset.dart';
```

## What It Contains

- `AssetManager`: cached loading for bytes (`loadBytes`), text (`loadText`), and images (`loadImage`)

## App Assets Example

```dart
final assets = AssetManager();

final rocket = await assets.loadImage('assets/demo/rocket.png');
final config = await assets.loadText('assets/demo/config.json');
```

## Package Assets Example

```dart
final assets = AssetManager(defaultPackage: 'gamengine');
final icon = await assets.loadImage('assets/ui/icon.png');
```

## Lifecycle

```dart
assets.unloadImage('assets/demo/rocket.png');
assets.clear();   // clear all caches
assets.dispose(); // marks manager unusable
```

## Notes

- Concurrent image requests are deduplicated internally.
- Use `preloadImages([...])` to warm up assets before gameplay.
