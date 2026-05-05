import 'package:gamengine/gamengine.dart';

class DefaultWorldComponentCodecs {
  static void register(WorldStateSerializer serializer) {
    serializer.registerCodec<Transform>(_TransformCodec());
    serializer.registerCodec<LocalTransform>(_LocalTransformCodec());
    serializer.registerCodec<Parent>(_ParentCodec());
    serializer.registerCodec<RigidBody>(_RigidBodyCodec());
    serializer.registerCodec<CircleCollider>(_CircleColliderCodec());
    serializer.registerCodec<RectangleCollider>(_RectangleColliderCodec());
    serializer.registerCodec<GravitySource>(_GravitySourceCodec());
    serializer.registerCodec<Sprite>(_SpriteCodec());
    serializer.registerCodec<AnimatedSprite>(_AnimatedSpriteCodec());
    serializer.registerCodec<TiledSprite>(_TiledSpriteCodec());
    serializer.registerCodec<CameraFollowTarget>(_CameraFollowTargetCodec());
    serializer.registerCodec<CircleShape>(_CircleShapeCodec());
    serializer.registerCodec<RectangleShape>(_RectangleShapeCodec());
  }
}

class _TransformCodec extends ComponentCodec<Transform> {
  @override
  String get typeId => 'ecs.transform';

  @override
  Transform decode(Map<String, Object?> data) {
    return Transform(
      position: decodeVector2(data, 'position'),
      rotation: decodeDouble(data, 'rotation')!,
      scale: decodeVector2(data, 'scale', fallback: Vector2.all(1)),
    );
  }

  @override
  Map<String, Object?> encode(Transform component) {
    return <String, Object?>{
      'position': encodeVector2(component.position),
      'rotation': component.rotation,
      'scale': encodeVector2(component.scale),
    };
  }
}

class _LocalTransformCodec extends ComponentCodec<LocalTransform> {
  @override
  String get typeId => 'ecs.localTransform';

  @override
  LocalTransform decode(Map<String, Object?> data) {
    return LocalTransform(
      position: decodeVector2(data, 'position'),
      rotation: decodeDouble(data, 'rotation')!,
      scale: decodeVector2(data, 'scale', fallback: Vector2.all(1)),
    );
  }

  @override
  Map<String, Object?> encode(LocalTransform component) {
    return <String, Object?>{
      'position': encodeVector2(component.position),
      'rotation': component.rotation,
      'scale': encodeVector2(component.scale),
    };
  }
}

class _ParentCodec extends ComponentCodec<Parent> {
  @override
  String get typeId => 'ecs.parent';

  @override
  Parent decode(Map<String, Object?> data) {
    return Parent(parent: data['parent'] as Entity);
  }

  @override
  Map<String, Object?> encode(Parent component) {
    return <String, Object?>{'parent': component.parent};
  }
}

class _RigidBodyCodec extends ComponentCodec<RigidBody> {
  @override
  String get typeId => 'physics.rigidBody';

  @override
  RigidBody decode(Map<String, Object?> data) {
    final body = RigidBody(
      velocity: decodeVector2(data, 'velocity'),
      mass: decodeDouble(data, 'mass')!,
      angularVelocity: decodeDouble(data, 'angularVelocity')!,
      linearDamping: decodeDouble(data, 'linearDamping')!,
      angularDamping: decodeDouble(data, 'angularDamping')!,
      gravityScale: decodeDouble(data, 'gravityScale')!,
      useGravity: decodeBool(data, 'useGravity')!,
      isStatic: decodeBool(data, 'isStatic')!,
      angularAcceleration: decodeDouble(data, 'angularAcceleration')!,
      accumulatedTorque: decodeDouble(data, 'accumulatedTorque')!,
      momentOfInertia: decodeDouble(data, 'momentOfInertia')!,
      lockRotation: decodeBool(data, 'lockRotation')!,
    );

    body.acceleration.setFrom(
      decodeVector2(data, 'acceleration', fallback: Vector2.zero()),
    );
    body.accumulatedForce.setFrom(
      decodeVector2(data, 'accumulatedForce', fallback: Vector2.zero()),
    );

    return body;
  }

  @override
  Map<String, Object?> encode(RigidBody component) {
    return <String, Object?>{
      'velocity': encodeVector2(component.velocity),
      'acceleration': encodeVector2(component.acceleration),
      'accumulatedForce': encodeVector2(component.accumulatedForce),
      'mass': component.mass,
      'angularVelocity': component.angularVelocity,
      'angularAcceleration': component.angularAcceleration,
      'accumulatedTorque': component.accumulatedTorque,
      'momentOfInertia': component.momentOfInertia,
      'lockRotation': component.lockRotation,
      'linearDamping': component.linearDamping,
      'angularDamping': component.angularDamping,
      'gravityScale': component.gravityScale,
      'useGravity': component.useGravity,
      'isStatic': component.isStatic,
    };
  }
}

class _CircleColliderCodec extends ComponentCodec<CircleCollider> {
  @override
  String get typeId => 'physics.circleCollider';

  @override
  CircleCollider decode(Map<String, Object?> data) {
    return CircleCollider(
      radius: decodeDouble(data, 'radius')!,
      collisionLayer: decodeInt(data, 'collisionLayer')!,
      collisionMask: decodeInt(data, 'collisionMask')!,
      restitution: decodeDouble(data, 'restitution')!,
      staticFriction: decodeDouble(data, 'staticFriction')!,
      dynamicFriction: decodeDouble(data, 'dynamicFriction')!,
      enabled: decodeBool(data, 'enabled')!,
    );
  }

  @override
  Map<String, Object?> encode(CircleCollider component) {
    return <String, Object?>{
      'radius': component.radius,
      'collisionLayer': component.collisionLayer,
      'collisionMask': component.collisionMask,
      'restitution': component.restitution,
      'staticFriction': component.staticFriction,
      'dynamicFriction': component.dynamicFriction,
      'enabled': component.enabled,
    };
  }
}

class _RectangleColliderCodec extends ComponentCodec<RectangleCollider> {
  @override
  String get typeId => 'physics.rectangleCollider';

  @override
  RectangleCollider decode(Map<String, Object?> data) {
    return RectangleCollider(
      halfWidth: decodeDouble(data, 'halfWidth')!,
      halfHeight: decodeDouble(data, 'halfHeight')!,
      collisionLayer: decodeInt(data, 'collisionLayer')!,
      collisionMask: decodeInt(data, 'collisionMask')!,
      restitution: decodeDouble(data, 'restitution')!,
      staticFriction: decodeDouble(data, 'staticFriction')!,
      dynamicFriction: decodeDouble(data, 'dynamicFriction')!,
      enabled: decodeBool(data, 'enabled')!,
    );
  }

  @override
  Map<String, Object?> encode(RectangleCollider component) {
    return <String, Object?>{
      'halfWidth': component.halfWidth,
      'halfHeight': component.halfHeight,
      'collisionLayer': component.collisionLayer,
      'collisionMask': component.collisionMask,
      'restitution': component.restitution,
      'staticFriction': component.staticFriction,
      'dynamicFriction': component.dynamicFriction,
      'enabled': component.enabled,
    };
  }
}

class _GravitySourceCodec extends ComponentCodec<GravitySource> {
  @override
  String get typeId => 'physics.gravitySource';

  @override
  GravitySource decode(Map<String, Object?> data) {
    return GravitySource(
      mass: decodeDouble(data, 'mass')!,
      minDistance: decodeDouble(data, 'minDistance')!,
      enabled: decodeBool(data, 'enabled')!,
    );
  }

  @override
  Map<String, Object?> encode(GravitySource component) {
    return <String, Object?>{
      'mass': component.mass,
      'minDistance': component.minDistance,
      'enabled': component.enabled,
    };
  }
}

class _SpriteCodec extends ComponentCodec<Sprite> {
  @override
  String get typeId => 'render.sprite';

  @override
  Sprite decode(Map<String, Object?> data) {
    return Sprite(
      visible: decodeBool(data, 'visible')!,
      image: decodeImage(data, 'image'),
      sourceRect: decodeRect(data, 'sourceRect'),
      paint: decodePaint(data, 'paint'),
      z: decodeInt(data, 'z')!,
    );
  }

  @override
  Map<String, Object?> encode(Sprite component) {
    return {
      'visible': component.visible,
      'image': encodeImage(component.image),
      'sourceRect': encodeRect(component.sourceRect),
      'paint': encodePaint(component.paint),
      'z': component.z,
    };
  }
}

class _AnimatedSpriteCodec extends ComponentCodec<AnimatedSprite> {
  @override
  String get typeId => 'render.animatedSprite';

  @override
  AnimatedSprite decode(Map<String, Object?> data) {
    final animatedSprite = AnimatedSprite(
      frameWidth: decodeInt(data, 'frameWidth')!,
      frameHeight: decodeInt(data, 'frameHeight')!,
      frameCount: decodeInt(data, 'frameCount')!,
      firstFrame: decodeInt(data, 'firstFrame')!,
      framesPerSecond: decodeDouble(data, 'framesPerSecond')!,
      loop: decodeBool(data, 'loop')!,
      playing: decodeBool(data, 'playing')!,
    );

    animatedSprite.currentFrame = decodeInt(data, 'currentFrame')!;
    animatedSprite.elapsedTime = decodeDouble(data, 'elapsedTime')!;
    return animatedSprite;
  }

  @override
  Map<String, Object?> encode(AnimatedSprite component) {
    return {
      'frameWidth': component.frameWidth,
      'frameHeight': component.frameHeight,
      'frameCount': component.frameCount,
      'firstFrame': component.firstFrame,
      'framesPerSecond': component.framesPerSecond,
      'loop': component.loop,
      'playing': component.playing,
      'currentFrame': component.currentFrame,
      'elapsedTime': component.elapsedTime,
    };
  }
}

class _TiledSpriteCodec extends ComponentCodec<TiledSprite> {
  @override
  String get typeId => 'render.tiledSprite';

  @override
  TiledSprite decode(Map<String, Object?> data) {
    return TiledSprite(
      image: decodeImage(data, 'image'),
      tileSize: decodeSize(data, 'tileSize')!,
      areaSize: decodeSize(data, 'areaSize')!,
      extendInfinitely: decodeBool(data, 'extendInfinitely')!,
      visible: decodeBool(data, 'visible')!,
      anchor: decodeOffset(data, 'anchor')!,
      paint: decodePaint(data, 'paint'),
      z: decodeInt(data, 'z')!,
    );
  }

  @override
  Map<String, Object?> encode(TiledSprite component) {
    return {
      'image': encodeImage(component.image),
      'tileSize': encodeSize(component.tileSize),
      'areaSize': encodeSize(component.areaSize),
      'extendInfinitely': component.extendInfinitely,
      'visible': component.visible,
      'anchor': encodeOffset(component.anchor),
      'paint': encodePaint(component.paint),
      'z': component.z,
    };
  }
}

class _CameraFollowTargetCodec extends ComponentCodec<CameraFollowTarget> {
  @override
  String get typeId => 'render.cameraFollowTarget';

  @override
  CameraFollowTarget decode(Map<String, Object?> data) {
    return CameraFollowTarget();
  }

  @override
  Map<String, Object?> encode(CameraFollowTarget component) {
    return {};
  }
}

class _CircleShapeCodec extends ComponentCodec<CircleShape> {
  @override
  String get typeId => 'render.circleShape';

  @override
  CircleShape decode(Map<String, Object?> data) {
    return CircleShape(
      radius: decodeDouble(data, 'radius')!,
      paint: decodePaint(data, 'paint'),
      z: decodeInt(data, 'z')!,
    );
  }

  @override
  Map<String, Object?> encode(CircleShape component) {
    return {
      'radius': component.radius,
      'paint': component.paint != null ? encodePaint(component.paint!) : null,
      'z': component.z,
    };
  }
}

class _RectangleShapeCodec extends ComponentCodec<RectangleShape> {
  @override
  String get typeId => 'render.rectangleShape';

  @override
  RectangleShape decode(Map<String, Object?> data) {
    return RectangleShape(
      size: decodeSize(data, 'size')!,
      anchor: decodeOffset(data, 'anchor')!,
      paint: decodePaint(data, 'paint'),
      z: decodeInt(data, 'z')!,
    );
  }

  @override
  Map<String, Object?> encode(RectangleShape component) {
    return {
      'size': encodeSize(component.size),
      'anchor': encodeOffset(component.anchor),
      'paint': component.paint != null ? encodePaint(component.paint!) : null,
      'z': component.z,
    };
  }
}
