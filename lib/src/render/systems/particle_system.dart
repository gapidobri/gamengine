import 'dart:math' as math;
import 'dart:ui';

import 'package:gamengine/src/ecs/system.dart';
import 'package:gamengine/src/ecs/components/transform.dart';
import 'package:gamengine/src/ecs/persistence/snapshots/snapshot_participant.dart';
import 'package:gamengine/src/ecs/world.dart';
import 'package:gamengine/src/render/commands/render_commands.dart';
import 'package:gamengine/src/render/components/particle_emitter.dart';
import 'package:gamengine/src/render/core/render_queue.dart';
import 'package:vector_math/vector_math_64.dart';

class ParticleSystem extends System implements SnapshotParticipant {
  final World world;
  final math.Random _rng;
  final int maxParticles;
  final Vector2 globalAcceleration;

  final List<_Particle> _particles = <_Particle>[];
  final Vector2 _tmp = Vector2.zero();

  ParticleSystem({
    required this.world,
    int? randomSeed,
    this.maxParticles = 4000,
    Vector2? globalAcceleration,
  }) : _rng = randomSeed == null ? math.Random() : math.Random(randomSeed),
       globalAcceleration = globalAcceleration ?? Vector2.zero();

  @override
  int get priority => 480;

  int get aliveCount => _particles.length;

  @override
  String get snapshotId => 'render.particleSystem';

  void clearParticles() {
    _particles.clear();
  }

  @override
  void update(double dt) {
    if (dt <= 0) {
      return;
    }

    _emitFromComponents(dt);
    _integrateParticles(dt);
  }

  int writeRenderCommands({
    required RenderQueue queue,
    required Rect cullRect,
  }) {
    var written = 0;
    for (final p in _particles) {
      final radius = _lerp(p.sizeStart, p.sizeEnd, p.normalizedAge);
      if (radius <= 0) {
        continue;
      }

      final bounds = Rect.fromCircle(
        center: Offset(p.position.x, p.position.y),
        radius: radius,
      );
      if (!bounds.overlaps(cullRect)) {
        continue;
      }

      queue.add(
        DrawCircleCommand(
          center: Offset(p.position.x, p.position.y),
          radius: radius,
          color:
              Color.lerp(p.colorStart, p.colorEnd, p.normalizedAge) ??
              p.colorEnd,
          z: p.z,
        ),
      );
      written++;
    }
    return written;
  }

  void _emitFromComponents(double dt) {
    for (final entity in world.query2<Transform, ParticleEmitter>()) {
      final transform = world.get<Transform>(entity);
      final emitter = world.get<ParticleEmitter>(entity);
      if (!emitter.enabled) {
        continue;
      }

      final exactSpawn = (emitter.emissionRate * dt) + emitter.spawnRemainder;
      final count = exactSpawn.floor();
      emitter.spawnRemainder = exactSpawn - count;

      for (var i = 0; i < count; i++) {
        _spawnParticleFromEmitter(transform: transform, emitter: emitter);
      }
    }
  }

  void emitBurst({
    required Vector2 origin,
    required Vector2 direction,
    required int burstCount,
    double spread = 1.1,
    double speedMin = 40,
    double speedMax = 170,
    double lifetimeMin = 0.18,
    double lifetimeMax = 0.55,
    double sizeStartMin = 1.6,
    double sizeStartMax = 3.6,
    double sizeEndMin = 0.2,
    double sizeEndMax = 1.1,
    double dragMin = 0.8,
    double dragMax = 2.8,
    Color colorStart = const Color(0xFFFFE9A6),
    Color colorEnd = const Color(0x00FF5A00),
    int z = 2,
  }) {
    if (burstCount <= 0) {
      return;
    }
    final dir = Vector2.copy(direction);
    if (dir.length2 == 0) {
      dir
        ..x = 0
        ..y = 1;
    } else {
      dir.normalize();
    }

    for (var i = 0; i < burstCount; i++) {
      if (_particles.length >= maxParticles) {
        return;
      }

      final angleOffset = _randRange(-spread, spread);
      final speed = _randRange(speedMin, speedMax);
      final nx = dir.x;
      final ny = dir.y;

      final cosA = math.cos(angleOffset);
      final sinA = math.sin(angleOffset);
      final dx = (nx * cosA) - (ny * sinA);
      final dy = (nx * sinA) + (ny * cosA);

      _particles.add(
        _Particle(
          position: Vector2.copy(origin),
          velocity: Vector2(dx * speed, dy * speed),
          lifetime: _randRange(lifetimeMin, lifetimeMax),
          sizeStart: _randRange(sizeStartMin, sizeStartMax),
          sizeEnd: _randRange(sizeEndMin, sizeEndMax),
          drag: _randRange(dragMin, dragMax),
          colorStart: colorStart,
          colorEnd: colorEnd,
          z: z,
        ),
      );
    }
  }

  void _spawnParticleFromEmitter({
    required Transform transform,
    required ParticleEmitter emitter,
  }) {
    if (_particles.length >= maxParticles) {
      return;
    }

    final sinR = math.sin(transform.rotation);
    final cosR = math.cos(transform.rotation);

    final ox = emitter.localOffset.x;
    final oy = emitter.localOffset.y;
    final rotatedOffsetX = (ox * cosR) - (oy * sinR);
    final rotatedOffsetY = (ox * sinR) + (oy * cosR);

    _tmp.setValues(emitter.localDirection.x, emitter.localDirection.y);
    if (_tmp.length2 == 0) {
      _tmp
        ..x = 0
        ..y = 1;
    } else {
      _tmp.normalize();
    }

    if (emitter.alignToRotation) {
      final dx = _tmp.x;
      final dy = _tmp.y;
      _tmp
        ..x = (dx * cosR) - (dy * sinR)
        ..y = (dx * sinR) + (dy * cosR);
    }

    final angle =
        math.atan2(_tmp.y, _tmp.x) +
        _randRange(-emitter.spread, emitter.spread);
    final speed = _randRange(emitter.speedMin, emitter.speedMax);

    _particles.add(
      _Particle(
        position: Vector2(
          transform.position.x + rotatedOffsetX,
          transform.position.y + rotatedOffsetY,
        ),
        velocity: Vector2(math.cos(angle) * speed, math.sin(angle) * speed),
        lifetime: _randRange(emitter.lifetimeMin, emitter.lifetimeMax),
        sizeStart: _randRange(emitter.sizeStartMin, emitter.sizeStartMax),
        sizeEnd: _randRange(emitter.sizeEndMin, emitter.sizeEndMax),
        drag: emitter.drag,
        colorStart: emitter.colorStart,
        colorEnd: emitter.colorEnd,
        z: emitter.z,
      ),
    );
  }

  void _integrateParticles(double dt) {
    var i = 0;
    while (i < _particles.length) {
      final p = _particles[i];
      p.age += dt;
      if (p.age >= p.lifetime) {
        _particles[i] = _particles.last;
        _particles.removeLast();
        continue;
      }

      if (p.drag > 0) {
        final damping = math.max(0.0, 1.0 - (p.drag * dt));
        p.velocity.scale(damping);
      }

      p.velocity.addScaled(globalAcceleration, dt);
      p.position.addScaled(p.velocity, dt);
      i++;
    }
  }

  double _randRange(double min, double max) {
    if (max <= min) {
      return min;
    }
    return min + ((max - min) * _rng.nextDouble());
  }

  double _lerp(double a, double b, double t) => a + ((b - a) * t);

  Map<String, Object?> exportState() {
    final particles = <Object?>[];
    for (final p in _particles) {
      particles.add(<String, Object?>{
        'position': <Object?>[p.position.x, p.position.y],
        'velocity': <Object?>[p.velocity.x, p.velocity.y],
        'lifetime': p.lifetime,
        'age': p.age,
        'sizeStart': p.sizeStart,
        'sizeEnd': p.sizeEnd,
        'drag': p.drag,
        'colorStart': p.colorStart.toARGB32(),
        'colorEnd': p.colorEnd.toARGB32(),
        'z': p.z,
      });
    }

    return <String, Object?>{'schemaVersion': 1, 'particles': particles};
  }

  void importState(Map<String, Object?> state, {bool clearExisting = true}) {
    if (clearExisting) {
      _particles.clear();
    }

    final rawParticles = state['particles'];
    if (rawParticles is! List) {
      return;
    }

    for (final raw in rawParticles) {
      if (_particles.length >= maxParticles) {
        return;
      }
      if (raw is! Map) {
        continue;
      }

      final entry = Map<String, Object?>.from(raw);
      final position = _readVector2(entry, 'position');
      final velocity = _readVector2(entry, 'velocity');
      final lifetime = _readDouble(entry, 'lifetime', fallback: 0);
      if (lifetime <= 0) {
        continue;
      }

      final particle = _Particle(
        position: position,
        velocity: velocity,
        lifetime: lifetime,
        sizeStart: _readDouble(entry, 'sizeStart', fallback: 1),
        sizeEnd: _readDouble(entry, 'sizeEnd', fallback: 0),
        drag: _readDouble(entry, 'drag', fallback: 0),
        colorStart: Color(_readInt(entry, 'colorStart', fallback: 0xFFFFFFFF)),
        colorEnd: Color(_readInt(entry, 'colorEnd', fallback: 0x00FFFFFF)),
        z: _readInt(entry, 'z', fallback: 1),
      );

      final age = _readDouble(entry, 'age', fallback: 0);
      particle.age = age.clamp(0, lifetime);
      _particles.add(particle);
    }
  }

  @override
  Object? exportSnapshot() => exportState();

  @override
  void importSnapshot(Object? snapshot) {
    if (snapshot == null) {
      clearParticles();
      return;
    }
    if (snapshot is Map<String, Object?>) {
      importState(snapshot);
      return;
    }
    if (snapshot is Map) {
      importState(Map<String, Object?>.from(snapshot));
      return;
    }
    clearParticles();
  }
}

class _Particle {
  final Vector2 position;
  final Vector2 velocity;
  final double lifetime;
  final double sizeStart;
  final double sizeEnd;
  final double drag;
  final Color colorStart;
  final Color colorEnd;
  final int z;

  double age = 0;

  _Particle({
    required this.position,
    required this.velocity,
    required this.lifetime,
    required this.sizeStart,
    required this.sizeEnd,
    required this.drag,
    required this.colorStart,
    required this.colorEnd,
    required this.z,
  });

  double get normalizedAge {
    if (lifetime <= 0) {
      return 1;
    }
    final t = age / lifetime;
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    return t;
  }
}

Vector2 _readVector2(Map<String, Object?> data, String key) {
  final value = data[key];
  if (value is List && value.length >= 2) {
    final x = (value[0] as num?)?.toDouble();
    final y = (value[1] as num?)?.toDouble();
    if (x != null && y != null) {
      return Vector2(x, y);
    }
  }
  return Vector2.zero();
}

double _readDouble(
  Map<String, Object?> data,
  String key, {
  required double fallback,
}) {
  final value = data[key];
  return value is num ? value.toDouble() : fallback;
}

int _readInt(Map<String, Object?> data, String key, {required int fallback}) {
  final value = data[key];
  return value is num ? value.toInt() : fallback;
}
