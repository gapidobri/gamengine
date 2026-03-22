import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Transform;
import 'package:flutter/services.dart';
import 'package:gamengine/gamengine.dart';

void main() {
  runApp(const SpaceGameApp());
}

class SpaceGameApp extends StatelessWidget {
  const SpaceGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: EngineDemoPage(),
    );
  }
}

class EngineDemoPage extends StatefulWidget {
  const EngineDemoPage({super.key});

  @override
  State<EngineDemoPage> createState() => _EngineDemoPageState();
}

class _EngineDemoPageState extends State<EngineDemoPage> {
  static const double _gravityConstant = 1.0;

  late final Engine _engine;
  late final World _world;
  late final Entity _rocketEntity;
  late final RenderQueue _queue;
  late final RenderMetrics _renderMetrics;
  late final HudStateStore<FlightHudState> _hudStore;
  late final CameraState _camera;
  late final WorldStateSerializer _worldSerializer;
  late final EngineSnapshotPersistence<String> _snapshotPersistence;
  late final Map<String, ui.Image> _spriteLibrary;
  late final SpriteAnimationSystem _spriteAnimationSystem;
  late final ParticleSystem _particleSystem;
  CameraFollowSystem? _cameraFollowSystem;
  String? _savedWorld;
  late final Future<void> _setupFuture;

  final FocusNode _focusNode = FocusNode();
  final FlightInputState _flightInput = FlightInputState();
  final math.Random _rng = math.Random(42);

  @override
  void initState() {
    super.initState();
    _world = World();
    _engine = Engine(world: _world);
    _queue = RenderQueue();
    _renderMetrics = RenderMetrics();
    _hudStore = HudStateStore(const FlightHudState.empty());
    _worldSerializer = WorldStateSerializer();
    DefaultWorldComponentCodecs.register(_worldSerializer);
    _worldSerializer.registerCodec<RocketPilot>(_RocketPilotCodec());
    _worldSerializer.registerCodec<SpriteAssetTag>(_SpriteAssetTagCodec());
    _snapshotPersistence = EngineSnapshotPersistence(
      serializer: EngineSnapshotSerializer(worldSerializer: _worldSerializer),
      format: JsonWorldStateFormat(),
    );
    _camera = CameraState()
      ..zoom = 1
      ..cullingPadding = 280
      ..viewportWidth = 1280
      ..viewportHeight = 720;
    _setupFuture = _setupDemo();
  }

  @override
  void dispose() {
    _hudStore.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final isDown = event is! KeyUpEvent;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.keyA) {
      _flightInput.turnLeft = isDown;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.keyD) {
      _flightInput.turnRight = isDown;
    } else if (event.logicalKey == LogicalKeyboardKey.space) {
      _flightInput.thrust = isDown;
    } else if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
        event.logicalKey == LogicalKeyboardKey.shiftRight) {
      _flightInput.boost = isDown;
    }

    return KeyEventResult.handled;
  }

  Future<void> _setupDemo() async {
    final rocketImage = await _createRocketImage();
    final rockImage = await _createRockImage();

    final planetImages = <ui.Image>[
      await _createPlanetImage(
        radius: 90,
        coreColor: const Color(0xFF2B6CB0),
        rimColor: const Color(0xFF7BC9FF),
      ),
      await _createPlanetImage(
        radius: 72,
        coreColor: const Color(0xFF805AD5),
        rimColor: const Color(0xFFC4B5FD),
      ),
      await _createPlanetImage(
        radius: 110,
        coreColor: const Color(0xFF0F766E),
        rimColor: const Color(0xFF5EEAD4),
      ),
    ];

    _spriteLibrary = <String, ui.Image>{
      'rocket': rocketImage,
      'rock': rockImage,
      'planetA': planetImages[0],
      'planetB': planetImages[1],
      'planetC': planetImages[2],
    };

    _addPlanet(x: 0, y: 0, radius: 90, mass: 420000, spriteKey: 'planetA');
    _addPlanet(x: 920, y: -420, radius: 72, mass: 260000, spriteKey: 'planetB');
    _addPlanet(
      x: -980,
      y: 520,
      radius: 110,
      mass: 550000,
      spriteKey: 'planetC',
    );

    _rocketEntity = _addRocket(
      x: 0,
      y: -250,
      orbitCenterX: 0,
      orbitCenterY: 0,
      orbitMass: 420000,
      spriteKey: 'rocket',
    );
    _snapCameraToEntity(_rocketEntity);

    _spawnDebrisField(
      centerX: 0,
      centerY: 0,
      centerMass: 420000,
      count: 18,
      minRadius: 180,
      maxRadius: 440,
      spriteKey: 'rock',
    );
    _spawnDebrisField(
      centerX: 920,
      centerY: -420,
      centerMass: 260000,
      count: 12,
      minRadius: 150,
      maxRadius: 320,
      spriteKey: 'rock',
    );

    final physicsSystem = PhysicsSystem(
      gravitationalConstant: _gravityConstant,
    );
    final collisionSystem = CollisionSystem(eventBus: _engine.eventBus);
    _particleSystem = ParticleSystem(maxParticles: 6000);

    _engine.addSystem(RocketControlSystem(input: _flightInput));
    _spriteAnimationSystem = SpriteAnimationSystem();
    _engine.addSystem(_spriteAnimationSystem);
    _engine.addSystem(
      HudPresenterSystem<FlightHudState>(
        output: _hudStore,
        project: _buildFlightHudState,
      ),
    );
    _cameraFollowSystem = CameraFollowSystem(camera: _camera);
    _engine.addSystem(_cameraFollowSystem!);
    _engine.addSystem(physicsSystem);
    _engine.addSystem(collisionSystem);
    _engine.addSystem(
      CollisionParticleEffectsSystem(
        eventBus: _engine.eventBus,
        particleSystem: _particleSystem,
      ),
    );
    _engine.addSystem(_particleSystem);
    _engine.addSystem(
      RenderSystem(
        queue: _queue,
        camera: _camera,
        metrics: _renderMetrics,
        particleSystem: _particleSystem,
      ),
    );

    _spriteAnimationSystem.syncNow();
  }

  void _addPlanet({
    required double x,
    required double y,
    required double radius,
    required double mass,
    required String spriteKey,
  }) {
    final entity = Entity();
    final transform = Transform();
    transform.position.x = x;
    transform.position.y = y;

    entity.add(transform);
    entity.add(GravitySource(mass: mass, minDistance: radius * 0.65));
    entity.add(
      CircleCollider(
        radius: radius,
        restitution: 0.1,
        staticFriction: 0.9,
        dynamicFriction: 0.72,
      ),
    );
    entity.add(SpriteAssetTag(spriteKey));
    entity.add(Sprite(image: _spriteLibrary[spriteKey], visible: true));

    _engine.addEntity(entity);
  }

  Entity _addRocket({
    required double x,
    required double y,
    required double orbitCenterX,
    required double orbitCenterY,
    required double orbitMass,
    required String spriteKey,
  }) {
    final entity = Entity();
    final transform = Transform();
    transform.position.x = x;
    transform.position.y = y;
    transform.rotation = 0;

    final dx = x - orbitCenterX;
    final dy = y - orbitCenterY;
    final radius = math.sqrt((dx * dx) + (dy * dy));
    final orbitalSpeed = math.sqrt(orbitMass / radius);
    final tangentX = -dy / radius;
    final tangentY = dx / radius;

    final body = RigidBody(
      mass: 1.2,
      linearDamping: 0.003,
      angularDamping: 3,
      gravityScale: 1,
    );
    body.velocity.x = tangentX * orbitalSpeed;
    body.velocity.y = tangentY * orbitalSpeed;

    entity.add(transform);
    entity.add(body);
    entity.add(
      CircleCollider(
        radius: 14,
        restitution: 0.28,
        staticFriction: 0.62,
        dynamicFriction: 0.5,
      ),
    );
    final boosterEmitter = ParticleEmitter(
      emissionRate: 0,
      spread: 0.32,
      speedMin: 35,
      speedMax: 90,
      lifetimeMin: 0.18,
      lifetimeMax: 0.45,
      sizeStartMin: 1.6,
      sizeStartMax: 3.2,
      sizeEndMin: 0.1,
      sizeEndMax: 1.1,
      drag: 1.8,
      colorStart: const Color(0xFFFFF1B8),
      colorEnd: const Color(0x00FF5D00),
      z: 3,
    );
    boosterEmitter.localOffset
      ..x = 0
      ..y = 24;
    boosterEmitter.localDirection
      ..x = 0
      ..y = 1;
    entity.add(boosterEmitter);
    entity.add(
      RocketPilot(thrustForce: 1050, turnSpeed: 5.0, boostMultiplier: 2.2),
    );
    entity.add(
      AnimatedSprite(
        frameWidth: 34,
        frameHeight: 56,
        frameCount: 4,
        framesPerSecond: 14,
        loop: true,
        playing: false,
      ),
    );
    entity.add(SpriteAssetTag(spriteKey));
    entity.add(Sprite(image: _spriteLibrary[spriteKey], visible: true));

    _engine.addEntity(entity);
    return entity;
  }

  void _spawnDebrisField({
    required double centerX,
    required double centerY,
    required double centerMass,
    required int count,
    required double minRadius,
    required double maxRadius,
    required String spriteKey,
  }) {
    for (var i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final radius = minRadius + (_rng.nextDouble() * (maxRadius - minRadius));

      final entity = Entity();
      final transform = Transform();
      transform.position.x = centerX + (math.cos(angle) * radius);
      transform.position.y = centerY + (math.sin(angle) * radius);

      final scale = 0.55 + (_rng.nextDouble() * 0.95);
      transform.scale.x = scale;
      transform.scale.y = scale;

      final speed =
          math.sqrt(centerMass / radius) * (0.9 + _rng.nextDouble() * 0.25);
      final tangentX = -math.sin(angle);
      final tangentY = math.cos(angle);

      final body = RigidBody(
        mass: 0.4 + _rng.nextDouble() * 0.8,
        linearDamping: 0,
        gravityScale: 1,
      );
      body.velocity.x = tangentX * speed;
      body.velocity.y = tangentY * speed;

      entity.add(transform);
      entity.add(body);
      entity.add(
        CircleCollider(
          radius: 10 * scale,
          restitution: 0.12,
          staticFriction: 0.78,
          dynamicFriction: 0.62,
        ),
      );
      entity.add(SpriteAssetTag(spriteKey));
      entity.add(Sprite(image: _spriteLibrary[spriteKey], visible: true));

      _engine.addEntity(entity);
    }
  }

  Future<ui.Image> _createRocketImage() async {
    const frameWidth = 34.0;
    const frameHeight = 56.0;
    const frames = 4;
    const width = frameWidth * frames;
    const height = frameHeight;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final hullPaint = Paint()..color = const Color(0xFFE2E8F0);
    final accentPaint = Paint()..color = const Color(0xFF38BDF8);
    final finPaint = Paint()..color = const Color(0xFFFF6B6B);
    const flames = <double>[0.0, 6.0, 10.0, 14.0];
    for (var frame = 0; frame < frames; frame++) {
      final dx = frame * frameWidth;
      final flame = flames[frame];

      final bodyRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(dx + 7, 8, frameWidth - 14, frameHeight - 16),
        const Radius.circular(10),
      );
      canvas.drawRRect(bodyRect, hullPaint);

      final nose = Path()
        ..moveTo(dx + (frameWidth / 2), 0)
        ..lineTo(dx + frameWidth - 8, 14)
        ..lineTo(dx + 8, 14)
        ..close();
      canvas.drawPath(nose, accentPaint);

      final leftFin = Path()
        ..moveTo(dx + 7, frameHeight - 10)
        ..lineTo(dx + 1, frameHeight)
        ..lineTo(dx + 11, frameHeight - 3)
        ..close();
      final rightFin = Path()
        ..moveTo(dx + frameWidth - 7, frameHeight - 10)
        ..lineTo(dx + frameWidth - 1, frameHeight)
        ..lineTo(dx + frameWidth - 11, frameHeight - 3)
        ..close();
      canvas.drawPath(leftFin, finPaint);
      canvas.drawPath(rightFin, finPaint);

      if (flame > 0) {
        final flamePath = Path()
          ..moveTo(dx + (frameWidth / 2), frameHeight + flame)
          ..lineTo(dx + frameWidth * 0.62, frameHeight - 4)
          ..lineTo(dx + frameWidth * 0.38, frameHeight - 4)
          ..close();
        canvas.drawPath(flamePath, Paint()..color = const Color(0xFFFFB347));
      }
    }

    final picture = recorder.endRecording();
    return picture.toImage(width.toInt(), height.toInt());
  }

  Future<ui.Image> _createPlanetImage({
    required double radius,
    required Color coreColor,
    required Color rimColor,
  }) async {
    final size = (radius * 2).ceilToDouble();
    final center = Offset(size / 2, size / 2);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final planetPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(center.dx - (radius * 0.3), center.dy - (radius * 0.35)),
        radius * 1.1,
        [rimColor, coreColor],
      );
    canvas.drawCircle(center, radius, planetPaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, radius * 0.06)
      ..color = rimColor.withValues(alpha: 0.6);
    canvas.drawCircle(center, radius * 0.95, ringPaint);

    final picture = recorder.endRecording();
    return picture.toImage(size.toInt(), size.toInt());
  }

  Future<ui.Image> _createRockImage() async {
    const size = 20.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final bodyPaint = Paint()..color = const Color(0xFF8B8F98);
    final detailPaint = Paint()..color = const Color(0xFF5E626A);

    final rock = Path()
      ..moveTo(2, 8)
      ..lineTo(7, 2)
      ..lineTo(15, 3)
      ..lineTo(19, 10)
      ..lineTo(14, 18)
      ..lineTo(6, 17)
      ..close();
    canvas.drawPath(rock, bodyPaint);

    canvas.drawCircle(const Offset(9, 8), 2.2, detailPaint);
    canvas.drawCircle(const Offset(13, 13), 1.6, detailPaint);

    final picture = recorder.endRecording();
    return picture.toImage(size.toInt(), size.toInt());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: SafeArea(
          child: FutureBuilder<void>(
            future: _setupFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              return Stack(
                children: [
                  Positioned(
                    bottom: 14,
                    left: 14,
                    child: _FlightHudPanel(store: _hudStore),
                  ),
                  Positioned.fill(
                    child: GameView(
                      engine: _engine,
                      queue: _queue,
                      camera: _camera,
                    ),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: _SaveLoadPanel(
                      hasSave: _savedWorld != null,
                      onSave: _saveWorld,
                      onLoad: _loadWorld,
                    ),
                  ),
                  const Positioned(
                    right: 14,
                    bottom: 14,
                    child: _ControlHint(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _saveWorld() {
    final serialized = _snapshotPersistence.encodeSnapshot(
      _world,
      participants: <SnapshotParticipant>[_particleSystem],
      throwOnUnregisteredComponent: false,
    );
    setState(() {
      _savedWorld = serialized;
    });
  }

  void _loadWorld() {
    final serialized = _savedWorld;
    if (serialized == null) {
      return;
    }

    _snapshotPersistence.decodeIntoWorld(
      _world,
      serialized,
      participants: <SnapshotParticipant>[_particleSystem],
      clearWorld: true,
      throwOnUnknownComponentType: false,
    );
    _rebuildSpritesFromTags();
    _spriteAnimationSystem.syncNow();
    _retargetCameraFollow(snapToTarget: true);
  }

  void _rebuildSpritesFromTags() {
    for (final entity in _world.entities) {
      final tag = entity.tryGet<SpriteAssetTag>();
      if (tag == null) {
        continue;
      }
      final image = _spriteLibrary[tag.key];
      if (image == null) {
        continue;
      }

      entity.remove<Sprite>();
      entity.add(Sprite(image: image, visible: true));
    }
  }

  void _retargetCameraFollow({bool snapToTarget = false}) {
    Entity? rocket;
    for (final entity in _world.entities) {
      if (entity.has<RocketPilot>()) {
        rocket = entity;
        break;
      }
    }
    if (rocket == null) {
      return;
    }
    if (snapToTarget) {
      _snapCameraToEntity(rocket);
    }

    final oldFollow = _cameraFollowSystem;
    if (oldFollow != null) {
      _engine.removeSystem(oldFollow);
    }
    _cameraFollowSystem = CameraFollowSystem(camera: _camera);
    _engine.addSystem(_cameraFollowSystem!);
  }

  void _snapCameraToEntity(Entity entity) {
    final transform = entity.get<Transform>();
    _camera.position.x = transform.position.x;
    _camera.position.y = transform.position.y;
  }

  FlightHudState _buildFlightHudState(World world) {
    final transform = _rocketEntity.get<Transform>();
    final body = _rocketEntity.get<RigidBody>();

    final speed = body.velocity.length;
    final altitude = _estimateSurfaceAltitude(
      transform.position.x,
      transform.position.y,
    );
    final collisions = _collisionEventsLastFrame();

    return FlightHudState(
      speed: speed,
      altitude: altitude,
      particles: _particleSystem.aliveCount,
      collisions: collisions,
      entities: _world.entityCount,
    );
  }

  double _estimateSurfaceAltitude(double x, double y) {
    double? best;
    for (final entity in _world.entities) {
      final collider = entity.tryGet<CircleCollider>();
      final transform = entity.tryGet<Transform>();
      if (entity.has<GravitySource>() ||
          collider == null ||
          transform == null) {
        continue;
      }

      final dx = x - transform.position.x;
      final dy = y - transform.position.y;
      final centerDistance = math.sqrt((dx * dx) + (dy * dy));
      final surfaceAltitude = centerDistance - collider.radius;
      if (best == null || surfaceAltitude < best) {
        best = surfaceAltitude;
      }
    }
    return best ?? 0.0;
  }

  int _collisionEventsLastFrame() {
    var count = 0;
    for (final _ in _engine.eventBus.read<CollisionEvent>()) {
      count++;
    }
    return count;
  }
}

class _ControlHint extends StatelessWidget {
  const _ControlHint();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x99000000),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          'Left/Right: Rotate\nSpace: Thrust\nShift: Boost',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

class FlightHudState {
  final double speed;
  final double altitude;
  final int particles;
  final int collisions;
  final int entities;

  const FlightHudState({
    required this.speed,
    required this.altitude,
    required this.particles,
    required this.collisions,
    required this.entities,
  });

  const FlightHudState.empty()
    : speed = 0,
      altitude = 0,
      particles = 0,
      collisions = 0,
      entities = 0;

  @override
  bool operator ==(Object other) {
    return other is FlightHudState &&
        other.speed == speed &&
        other.altitude == altitude &&
        other.particles == particles &&
        other.collisions == collisions &&
        other.entities == entities;
  }

  @override
  int get hashCode =>
      Object.hash(speed, altitude, particles, collisions, entities);
}

class _FlightHudPanel extends StatelessWidget {
  final HudStateStore<FlightHudState> store;

  const _FlightHudPanel({required this.store});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x99000000),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: ValueListenableBuilder<FlightHudState>(
          valueListenable: store,
          builder: (context, hud, child) {
            return Text(
              'Speed: ${hud.speed.toStringAsFixed(1)}\n'
              'Altitude: ${hud.altitude.toStringAsFixed(1)}\n'
              'Particles: ${hud.particles}\n'
              'Collisions: ${hud.collisions}\n'
              'Entities: ${hud.entities}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SaveLoadPanel extends StatelessWidget {
  final bool hasSave;
  final VoidCallback onSave;
  final VoidCallback onLoad;

  const _SaveLoadPanel({
    required this.hasSave,
    required this.onSave,
    required this.onLoad,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x99000000),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(onPressed: onSave, child: const Text('Save')),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: hasSave ? onLoad : null,
              child: const Text('Load'),
            ),
          ],
        ),
      ),
    );
  }
}

class FlightInputState {
  bool turnLeft = false;
  bool turnRight = false;
  bool thrust = false;
  bool boost = false;
}

class RocketPilot extends Component {
  final double thrustForce;
  final double turnSpeed;
  final double boostMultiplier;

  RocketPilot({
    required this.thrustForce,
    required this.turnSpeed,
    required this.boostMultiplier,
  });
}

class SpriteAssetTag extends Component {
  final String key;

  SpriteAssetTag(this.key);
}

class _RocketPilotCodec extends ComponentCodec<RocketPilot> {
  @override
  String get typeId => 'demo.rocketPilot';

  @override
  RocketPilot decode(Map<String, Object?> data) {
    return RocketPilot(
      thrustForce: _readDouble(data, 'thrustForce', 1050),
      turnSpeed: _readDouble(data, 'turnSpeed', 5),
      boostMultiplier: _readDouble(data, 'boostMultiplier', 2.2),
    );
  }

  @override
  Map<String, Object?> encode(RocketPilot component) {
    return <String, Object?>{
      'thrustForce': component.thrustForce,
      'turnSpeed': component.turnSpeed,
      'boostMultiplier': component.boostMultiplier,
    };
  }
}

class _SpriteAssetTagCodec extends ComponentCodec<SpriteAssetTag> {
  @override
  String get typeId => 'demo.spriteAssetTag';

  @override
  SpriteAssetTag decode(Map<String, Object?> data) {
    final value = data['key'];
    return SpriteAssetTag(value is String ? value : '');
  }

  @override
  Map<String, Object?> encode(SpriteAssetTag component) {
    return <String, Object?>{'key': component.key};
  }
}

double _readDouble(Map<String, Object?> data, String key, double fallback) {
  final value = data[key];
  return value is num ? value.toDouble() : fallback;
}

class RocketControlSystem extends System {
  final FlightInputState input;

  RocketControlSystem({required this.input});

  @override
  int get priority => 700;

  @override
  void update(double dt, World world, Commands commands) {
    for (final entity in world.query2<Transform, RocketPilot>()) {
      final transform = entity.get<Transform>();
      final body = entity.get<RigidBody>();
      final pilot = entity.get<RocketPilot>();
      final emitter = entity.get<ParticleEmitter>();
      final animation = entity.get<AnimatedSprite>();

      var turnInput = 0.0;
      if (input.turnLeft) {
        turnInput -= 1.0;
      }
      if (input.turnRight) {
        turnInput += 1.0;
      }
      body.angularVelocity = turnInput * pilot.turnSpeed;

      if (!input.thrust) {
        emitter.emissionRate = 0;
        animation
          ..playing = false
          ..currentFrame = 0
          ..elapsedTime = 0;
        continue;
      }

      final boost = input.boost ? pilot.boostMultiplier : 1.0;
      final thrust = pilot.thrustForce * boost;
      emitter.emissionRate = 100.0 * boost;
      animation
        ..playing = true
        ..framesPerSecond = 12.0 * boost;

      final sinR = math.sin(transform.rotation);
      final cosR = math.cos(transform.rotation);

      body.accumulatedForce.x += sinR * thrust;
      body.accumulatedForce.y += -cosR * thrust;
    }
  }
}

class CollisionParticleEffectsSystem extends System {
  final EventBus eventBus;
  final ParticleSystem particleSystem;

  CollisionParticleEffectsSystem({
    required this.eventBus,
    required this.particleSystem,
  });

  @override
  int get priority => 485;

  @override
  void update(double dt, World world, Commands commands) {
    for (final event in eventBus.read<CollisionEvent>()) {
      final isPlanetHit =
          event.entityA.has<GravitySource>() ||
          event.entityB.has<GravitySource>();
      if (!isPlanetHit || event.relativeSpeed < 10) {
        continue;
      }

      final burstCount = 8 + (event.relativeSpeed * 0.08).clamp(0, 18).toInt();
      particleSystem.emitBurst(
        origin: event.point,
        direction: event.normal,
        burstCount: burstCount,
        spread: 1.05,
        speedMin: 35,
        speedMax: 185,
        lifetimeMin: 0.12,
        lifetimeMax: 0.42,
        sizeStartMin: 1.2,
        sizeStartMax: 2.8,
        sizeEndMin: 0.1,
        sizeEndMax: 0.7,
        dragMin: 1.5,
        dragMax: 4.2,
        colorStart: const Color(0xFFFFF1C2),
        colorEnd: const Color(0x00FF6A00),
        z: 2,
      );
    }
  }
}
