import '../media_plugin_data.dart';
import '../storecamera_plugin_media.dart';

typedef PluginThumbnailLoaderCallback = void Function(
    PluginBitmap? bitmap, Object? e);

abstract class PluginThumbnailLoader {
  PluginBitmap? loadAsync(String? id, int? width, int? height,
      PluginThumbnailLoaderCallback callback);

  void cancelAsync(PluginThumbnailLoaderCallback callback);
}

class PluginThumbnailCacheLoader extends PluginThumbnailLoader {
  static final PluginThumbnailCacheLoader _instance =
      PluginThumbnailCacheLoader._();

  factory PluginThumbnailCacheLoader() => _instance;

  PluginThumbnailCacheLoader._();

  int maximumSize = 64;
  int coincident = 8;

  int _loadingCount = 0;

  final Map<_LoadKey, PluginBitmap> _cache = {};
  final List<_LoadKey> _cacheKeys = [];
  final List<_LoadItem> _pending = [];

  @override
  PluginBitmap? loadAsync(String? id, int? width, int? height,
      PluginThumbnailLoaderCallback callback) {
    final key = _LoadKey(id, width, height);

    PluginBitmap? bitmap = _cache[key];
    if (bitmap != null) {
      _cacheKeys.remove(key);
      _cacheKeys.add(key);
      return bitmap;
    }

    if (_loadingCount < coincident) {
      _loadAsync(
        key,
        callback,
      );
    } else {
      _pending.add(_LoadItem(
        key,
        callback,
      ));
    }
    return null;
  }

  void _loadAsync(_LoadKey key, PluginThumbnailLoaderCallback callback) async {
    _loadingCount++;
    try {
      PluginBitmap? bitmap = await StoreCameraPluginMedia.getImageThumbnail(
          key.id,
          width: key.width,
          height: key.height);
      if (bitmap != null) {
        if (_cacheKeys.length >= maximumSize) {
          _LoadKey _key = _cacheKeys.removeAt(0);
          _cache.remove(_key);
        }
        _cacheKeys.add(key);
        _cache[key] = bitmap;
        _loadingCount--;
        callback(bitmap, null);
        loadPending();
        return;
      }
      throw Exception('PluginThumbnailCacheLoader Thumbnail load failed');
    } catch (e) {
      _loadingCount--;
      callback(null, e);
      loadPending();
    }
  }

  void loadPending() {
    if (_pending.isNotEmpty && _loadingCount < coincident) {
      _LoadItem loadItem = _pending.removeLast();

      PluginBitmap? bitmap = _cache[loadItem.key];
      if (bitmap != null) {
        _cacheKeys.remove(loadItem.key);
        _cacheKeys.add(loadItem.key);
        loadItem.callback(bitmap, null);
      } else {
        _loadAsync(
          loadItem.key,
          loadItem.callback,
        );
      }
    }
  }

  // Future<ui.Image> decodeImageFromPixels(PluginBitmap pluginBitmap) {
  //   Completer<ui.Image> c = Completer();
  //   ui.decodeImageFromPixels(pluginBitmap.buffer, pluginBitmap.width,
  //       pluginBitmap.height, ui.PixelFormat.rgba8888, (results) {
  //     c.complete(results);
  //   });
  //
  //   return c.future;
  // }

  @override
  void cancelAsync(PluginThumbnailLoaderCallback callback) {
    Iterator<_LoadItem> iterator = _pending.iterator;
    while (iterator.moveNext()) {
      if (iterator.current.callback == callback) {
        _pending.remove(iterator.current);
        break;
      }
    }
  }

  void evict() {
    print('KKH _pending ${_pending.length} _cache ${_cache.length}');
    _pending.clear();
    _cache.clear();
  }
}

// class ThumbnailCacheImage {
//   final ui.Image image;
//   int _referenceCount = 1;
//
//   ThumbnailCacheImage(this.image);
//
//   void _ref() => _referenceCount++;
//
//   void dispose() {
//     _referenceCount--;
//     if(_referenceCount <= 0) {
//       image.dispose();
//     }
//   }
// }

class _LoadKey {
  final String? id;
  final int? width;
  final int? height;

  _LoadKey(this.id, this.width, this.height);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _LoadKey &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => id.hashCode ^ width.hashCode ^ height.hashCode;
}

class _LoadItem {
  final _LoadKey key;
  final PluginThumbnailLoaderCallback callback;

  _LoadItem(this.key, this.callback);
}
