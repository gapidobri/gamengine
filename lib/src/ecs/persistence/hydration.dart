import 'package:gamengine/gamengine.dart';

Future<void> hydrateSprites(World world, AssetManager assetManager) async {
  for (final entity in world.entities) {
    final sprite = entity.tryGet<Sprite>();
    if (sprite != null) {
      if (sprite.image == null) continue;
      final image = await assetManager.loadImage(
        sprite.image!.path,
        package: sprite.image!.package,
      );
      sprite.image = image;
    }

    final tiledSprite = entity.tryGet<TiledSprite>();
    if (tiledSprite != null) {
      final image = await assetManager.loadImage(
        tiledSprite.image.path,
        package: tiledSprite.image.package,
      );
      tiledSprite.image = image;
    }
  }
}
