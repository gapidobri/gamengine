import 'dart:convert';
import 'dart:typed_data';

import 'package:gamengine/src/ecs/persistence/codecs/world_state_binary_codec.dart';

class CompactBinaryWorldStateCodec extends WorldStateBinaryCodec {
  static const int _nullTag = 0;
  static const int _falseTag = 1;
  static const int _trueTag = 2;
  static const int _intTag = 3;
  static const int _doubleTag = 4;
  static const int _stringTag = 5;
  static const int _listTag = 6;
  static const int _mapTag = 7;

  @override
  String get formatId => 'binary-v1';

  @override
  Uint8List encodeBinary(Map<String, Object?> worldState) {
    final writer = _BinaryWriter();
    writer.writeValue(worldState);
    return writer.takeBytes();
  }

  @override
  Map<String, Object?> decodeBinary(Uint8List bytes) {
    final reader = _BinaryReader(bytes);
    final value = reader.readValue();
    if (value is! Map<String, Object?>) {
      throw FormatException('Binary world state root must decode to a map.');
    }
    if (!reader.isAtEnd) {
      throw FormatException('Binary world state contains trailing bytes.');
    }
    return value;
  }
}

class _BinaryWriter {
  final BytesBuilder _builder = BytesBuilder(copy: false);

  Uint8List takeBytes() => _builder.takeBytes();

  void writeValue(Object? value) {
    if (value == null) {
      _writeByte(CompactBinaryWorldStateCodec._nullTag);
      return;
    }

    if (value is bool) {
      _writeByte(
        value
            ? CompactBinaryWorldStateCodec._trueTag
            : CompactBinaryWorldStateCodec._falseTag,
      );
      return;
    }

    if (value is int) {
      _writeByte(CompactBinaryWorldStateCodec._intTag);
      _writeInt64(value);
      return;
    }

    if (value is double) {
      _writeByte(CompactBinaryWorldStateCodec._doubleTag);
      _writeFloat64(value);
      return;
    }

    if (value is num) {
      _writeByte(CompactBinaryWorldStateCodec._doubleTag);
      _writeFloat64(value.toDouble());
      return;
    }

    if (value is String) {
      _writeByte(CompactBinaryWorldStateCodec._stringTag);
      _writeString(value);
      return;
    }

    if (value is List) {
      _writeByte(CompactBinaryWorldStateCodec._listTag);
      _writeUint32(value.length);
      for (final item in value) {
        writeValue(item);
      }
      return;
    }

    if (value is Map) {
      _writeByte(CompactBinaryWorldStateCodec._mapTag);
      _writeUint32(value.length);
      for (final entry in value.entries) {
        _writeString(entry.key.toString());
        writeValue(entry.value);
      }
      return;
    }

    throw FormatException('Unsupported value type for binary serialization: ${value.runtimeType}');
  }

  void _writeByte(int value) {
    _builder.add([value & 0xFF]);
  }

  void _writeUint32(int value) {
    final data = ByteData(4)..setUint32(0, value, Endian.big);
    _builder.add(data.buffer.asUint8List());
  }

  void _writeInt64(int value) {
    final data = ByteData(8)..setInt64(0, value, Endian.big);
    _builder.add(data.buffer.asUint8List());
  }

  void _writeFloat64(double value) {
    final data = ByteData(8)..setFloat64(0, value, Endian.big);
    _builder.add(data.buffer.asUint8List());
  }

  void _writeString(String value) {
    final bytes = utf8.encode(value);
    _writeUint32(bytes.length);
    _builder.add(bytes);
  }
}

class _BinaryReader {
  final Uint8List _bytes;
  int _offset = 0;

  _BinaryReader(this._bytes);

  bool get isAtEnd => _offset == _bytes.length;

  Object? readValue() {
    final tag = _readByte();

    switch (tag) {
      case CompactBinaryWorldStateCodec._nullTag:
        return null;
      case CompactBinaryWorldStateCodec._falseTag:
        return false;
      case CompactBinaryWorldStateCodec._trueTag:
        return true;
      case CompactBinaryWorldStateCodec._intTag:
        return _readInt64();
      case CompactBinaryWorldStateCodec._doubleTag:
        return _readFloat64();
      case CompactBinaryWorldStateCodec._stringTag:
        return _readString();
      case CompactBinaryWorldStateCodec._listTag:
        final length = _readUint32();
        final list = <Object?>[];
        for (var i = 0; i < length; i++) {
          list.add(readValue());
        }
        return list;
      case CompactBinaryWorldStateCodec._mapTag:
        final length = _readUint32();
        final map = <String, Object?>{};
        for (var i = 0; i < length; i++) {
          final key = _readString();
          map[key] = readValue();
        }
        return map;
      default:
        throw FormatException('Unknown binary type tag: $tag at offset ${_offset - 1}.');
    }
  }

  int _readByte() {
    _ensureRemaining(1);
    final value = _bytes[_offset];
    _offset += 1;
    return value;
  }

  int _readUint32() {
    _ensureRemaining(4);
    final data = ByteData.sublistView(_bytes, _offset, _offset + 4);
    final value = data.getUint32(0, Endian.big);
    _offset += 4;
    return value;
  }

  int _readInt64() {
    _ensureRemaining(8);
    final data = ByteData.sublistView(_bytes, _offset, _offset + 8);
    final value = data.getInt64(0, Endian.big);
    _offset += 8;
    return value;
  }

  double _readFloat64() {
    _ensureRemaining(8);
    final data = ByteData.sublistView(_bytes, _offset, _offset + 8);
    final value = data.getFloat64(0, Endian.big);
    _offset += 8;
    return value;
  }

  String _readString() {
    final length = _readUint32();
    _ensureRemaining(length);
    final value = utf8.decode(_bytes.sublist(_offset, _offset + length));
    _offset += length;
    return value;
  }

  void _ensureRemaining(int needed) {
    if ((_offset + needed) > _bytes.length) {
      throw FormatException('Unexpected end of binary world state at offset $_offset.');
    }
  }
}
