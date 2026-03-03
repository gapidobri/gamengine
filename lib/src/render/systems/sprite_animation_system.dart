import 'dart:ui';

import 'package:gamengine/src/ecs/system.dart';
import 'package:gamengine/src/ecs/world.dart';
import 'package:gamengine/src/render/components/animated_sprite.dart';
import 'package:gamengine/src/render/components/sprite.dart';

class SpriteAnimationSystem extends System {
  final World world;

  SpriteAnimationSystem({required this.world});

  @override
  int get priority => 950;

  @override
  void update(double dt) {
    _syncInternal(dt: dt, advanceTime: true);
  }

  /// Applies source rects for all animated sprites immediately without
  /// advancing animation time.
  void syncNow() {
    _syncInternal(dt: 0, advanceTime: false);
  }

  void _syncInternal({required double dt, required bool advanceTime}) {
    for (final entity in world.query2<Sprite, AnimatedSprite>()) {
      final sprite = world.get<Sprite>(entity);
      final animation = world.get<AnimatedSprite>(entity);
      final image = sprite.image;

      if (image == null) {
        continue;
      }

      if (animation.frameWidth <= 0 ||
          animation.frameHeight <= 0 ||
          animation.frameCount <= 0) {
        continue;
      }

      final fps = animation.framesPerSecond;
      if (advanceTime && animation.playing && fps > 0 && dt > 0) {
        final frameDuration = 1.0 / fps;
        animation.elapsedTime += dt;

        var advance = animation.elapsedTime ~/ frameDuration;
        if (advance > 0) {
          animation.elapsedTime -= advance * frameDuration;

          while (advance > 0) {
            animation.currentFrame += 1;
            if (animation.currentFrame >= animation.frameCount) {
              if (animation.loop) {
                animation.currentFrame = 0;
              } else {
                animation.currentFrame = animation.frameCount - 1;
                animation.playing = false;
                break;
              }
            }
            advance -= 1;
          }
        }
      }

      _applyFrame(sprite: sprite, animation: animation, image: image);
    }
  }

  void _applyFrame({
    required Sprite sprite,
    required AnimatedSprite animation,
    required Image image,
  }) {
    final columns = image.width ~/ animation.frameWidth;
    if (columns <= 0) {
      return;
    }

    var frame = animation.currentFrame;
    if (frame < 0) {
      frame = 0;
    } else if (frame >= animation.frameCount) {
      frame = animation.frameCount - 1;
    }

    final frameIndex = animation.firstFrame + frame;
    final col = frameIndex % columns;
    final row = frameIndex ~/ columns;

    final left = col * animation.frameWidth;
    final top = row * animation.frameHeight;

    sprite.sourceRect = Rect.fromLTWH(
      left.toDouble(),
      top.toDouble(),
      animation.frameWidth.toDouble(),
      animation.frameHeight.toDouble(),
    );
  }
}
