import 'package:gamengine/src/ecs/components/component.dart';

class AnimatedSprite extends Component {
  final int frameWidth;
  final int frameHeight;
  final int frameCount;
  final int firstFrame;
  double framesPerSecond;
  bool loop;
  bool playing;

  int currentFrame = 0;
  double elapsedTime = 0;

  AnimatedSprite({
    required this.frameWidth,
    required this.frameHeight,
    required this.frameCount,
    this.firstFrame = 0,
    this.framesPerSecond = 12,
    this.loop = true,
    this.playing = true,
  });

  void play({bool restart = false}) {
    if (restart) {
      currentFrame = 0;
      elapsedTime = 0;
    }
    playing = true;
  }

  void pause() {
    playing = false;
  }

  void stop({bool resetFrame = true}) {
    playing = false;
    if (resetFrame) {
      currentFrame = 0;
      elapsedTime = 0;
    }
  }
}
