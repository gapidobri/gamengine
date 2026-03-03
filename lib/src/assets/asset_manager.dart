import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// Loads and caches game assets from Flutter's [AssetBundle].
///
/// This manager is intentionally small and explicit:
/// - bytes/text for generic resources
/// - decoded [ui.Image] for render-ready sprites/textures
class AssetManager {
  final AssetBundle _bundle;
  final String? _defaultPackage;

  final Map<String, Uint8List> _byteCache = <String, Uint8List>{};
  final Map<String, String> _textCache = <String, String>{};
  final Map<String, ui.Image> _imageCache = <String, ui.Image>{};
  final Map<String, Future<ui.Image>> _pendingImages =
      <String, Future<ui.Image>>{};

  bool _isDisposed = false;

  AssetManager({AssetBundle? bundle, String? defaultPackage})
    : _bundle = bundle ?? rootBundle,
      _defaultPackage = defaultPackage;

  bool get isDisposed => _isDisposed;
  int get cachedByteCount => _byteCache.length;
  int get cachedTextCount => _textCache.length;
  int get cachedImageCount => _imageCache.length;

  Uint8List? bytes(String assetPath, {String? package}) {
    return _byteCache[_resolveKey(assetPath, package: package)];
  }

  String? text(String assetPath, {String? package}) {
    return _textCache[_resolveKey(assetPath, package: package)];
  }

  ui.Image? image(String assetPath, {String? package}) {
    return _imageCache[_resolveKey(assetPath, package: package)];
  }

  Future<Uint8List> loadBytes(String assetPath, {String? package}) async {
    _ensureNotDisposed();
    final key = _resolveKey(assetPath, package: package);
    final cached = _byteCache[key];
    if (cached != null) {
      return cached;
    }

    final data = await _bundle.load(key);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    _byteCache[key] = bytes;
    return bytes;
  }

  Future<String> loadText(String assetPath, {String? package}) async {
    _ensureNotDisposed();
    final key = _resolveKey(assetPath, package: package);
    final cached = _textCache[key];
    if (cached != null) {
      return cached;
    }

    final value = await _bundle.loadString(key);
    _textCache[key] = value;
    return value;
  }

  Future<ui.Image> loadImage(String assetPath, {String? package}) async {
    _ensureNotDisposed();
    final key = _resolveKey(assetPath, package: package);

    final cachedImage = _imageCache[key];
    if (cachedImage != null) {
      return cachedImage;
    }

    final pending = _pendingImages[key];
    if (pending != null) {
      return pending;
    }

    final future = _decodeImage(key);
    _pendingImages[key] = future;
    try {
      final image = await future;
      _imageCache[key] = image;
      return image;
    } finally {
      _pendingImages.remove(key);
    }
  }

  Future<void> preloadImages(
    Iterable<String> assetPaths, {
    String? package,
  }) async {
    await Future.wait(
      assetPaths.map((path) => loadImage(path, package: package)),
    );
  }

  void unloadBytes(String assetPath, {String? package}) {
    final key = _resolveKey(assetPath, package: package);
    _byteCache.remove(key);
  }

  void unloadText(String assetPath, {String? package}) {
    final key = _resolveKey(assetPath, package: package);
    _textCache.remove(key);
  }

  void unloadImage(
    String assetPath, {
    String? package,
    bool disposeImage = true,
  }) {
    final key = _resolveKey(assetPath, package: package);
    final image = _imageCache.remove(key);
    if (disposeImage && image != null) {
      image.dispose();
    }
  }

  void clear({bool disposeImages = true}) {
    _byteCache.clear();
    _textCache.clear();

    if (disposeImages) {
      for (final image in _imageCache.values) {
        image.dispose();
      }
    }
    _imageCache.clear();
    _pendingImages.clear();
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }
    clear();
    _isDisposed = true;
  }

  String _resolveKey(String assetPath, {String? package}) {
    final pkg = package ?? _defaultPackage;
    if (pkg == null || assetPath.startsWith('packages/')) {
      return assetPath;
    }
    return 'packages/$pkg/$assetPath';
  }

  Future<ui.Image> _decodeImage(String key) async {
    final data = await _bundle.load(key);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _ensureNotDisposed() {
    if (_isDisposed) {
      throw StateError('AssetManager is disposed.');
    }
  }
}
