import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'media_map_ext.dart';
import 'media_plugin_config.dart';
import 'media_plugin_data.dart';

class StoreCameraPluginMedia {
  static const MethodChannel _channel =
      MethodChannel(PluginConfig.CHANNEL_NAME);

  static Future<PluginDataSet<PluginFolder>?> getImageFolder() async {
    final result =
        await _channel.invokeMethod(PlatformMethod.GET_IMAGE_FOLDER.method);
    if (result is Map) {
      return PluginDataSet(
          result.get('timeMs') ?? 0,
          result.get('permission') ?? false,
          result.getList('list', (map) {
            return PluginFolder.map(map);
          }));
    }
    return null;
  }

  static Future<int?> getImageFolderCount(String? id) async {
    final result = await _channel.invokeMethod(
        PlatformMethod.GET_IMAGE_FOLDER_COUNT.method, id);
    if (result is int) {
      return result;
    }
    return null;
  }

  static Future<PluginDataSet<PluginImage>?> getImages(String? id,
      {PluginSortOrder? sortOrder, int? offset, int? limit}) async {
    final result =
        await _channel.invokeMethod(PlatformMethod.GET_IMAGE_FILES.method, {
      if (id != null) 'id': id,
      if (sortOrder != null) 'sortOrder': sortOrder.sortOrder,
      if (offset != null) 'offset': offset,
      if (limit != null) 'limit': limit
    });

    if (result is Map) {
      return PluginDataSet(
          result.get('timeMs') ?? 0,
          result.get('permission') ?? false,
          result.getList('list', (map) {
            return PluginImage.factoryMap(map);
          }));
    }
    return null;
  }

  static Future<PluginImage?> getImage(String id) async {
    final result =
        await _channel.invokeMethod(PlatformMethod.GET_IMAGE_FILE.method, {
      'id': id,
    });

    if (result is Map) {
      return PluginImage.factoryMap(result);
    }
    return null;
  }

  static Future<PluginBitmap?> getImageThumbnail(String? id,
      {int? width, int? height}) async {
    final results =
        await _channel.invokeMethod(PlatformMethod.GET_IMAGE_THUMBNAIL.method, {
      'id': id,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    });

    if (results is Map) {
      return PluginBitmap.factoryMap(results);
    }
    return null;
  }

  static Future<Uint8List?> readImageData(String? id) async {
    final results =
        await _channel.invokeMethod(PlatformMethod.READ_IMAGE_DATA.method, id);

    if (results is Uint8List) {
      return results;
    }
    return null;
  }

  static Future<bool> checkUpdate(int timeMs) async {
    final results =
        await _channel.invokeMethod(PlatformMethod.CHECK_UPDATE.method, timeMs);
    if (results is bool) {
      return results;
    }
    return true;
  }

  static Future<PluginImageInfo?> getImageInfo(String? id) async {
    final results =
        await _channel.invokeMethod(PlatformMethod.GET_IMAGE_INFO.method, id);
    if (results is Map) {
      return PluginImageInfo.map(results);
    }
    return null;
  }

  static Future<bool> addImage(Uint8List buffer, String folder, String name,
      {PluginImageFormat inputFormat = PluginImageFormat.JPG,
      PluginImageFormat outputFormat = PluginImageFormat.JPG,
      int? width,
      int? height}) async {
    final results =
        await _channel.invokeMethod(PlatformMethod.ADD_IMAGE.method, {
      'folder': folder,
      'name': name,
      'buffer': buffer,
      'input': inputFormat.format,
      'output': outputFormat.format,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    });
    // if(results is Map) {
    //   return PluginImageInfo.map(results);
    // }
    return results ?? false;
  }

  static Future<List<String>> deleteImage(List<String> ids) async {
    final results =
        await _channel.invokeMethod(PlatformMethod.DELETE_IMAGE.method, ids);
    if (results is List) {
      final resultsIds = <String>[];
      for (final id in results) {
        if (id is String) {
          resultsIds.add(id);
        }
      }
      return resultsIds;
    }
    return <String>[];
  }

  static Future<bool> shareImage(List<String> ids) async {
    final result =
        await _channel.invokeMethod(PlatformMethod.SHARE_IMAGE.method, ids);
    if (result is bool) {
      return result;
    }
    return false;
  }

  static Future<PluginImageBuffer?> imageBufferConverterWithMaxSize(
      PluginImageBuffer buffer,
      {PluginImageFormat? outputFormat,
      int? maxSize,
      int? maxWidth,
      int? maxHeight}) async {
    Map map = buffer.map();
    if (outputFormat != null) {
      map['output'] = outputFormat.format;
    }
    if (maxSize != null) {
      map['maxWidth'] = maxSize;
      map['maxHeight'] = maxSize;
    }
    if (maxWidth != null) {
      map['maxWidth'] = maxWidth;
    }
    if (maxHeight != null) {
      map['maxHeight'] = maxHeight;
    }

    final result = await _channel.invokeMethod(
        PlatformMethod.IMAGE_BUFFER_CONVERTER_WITH_MAX_SIZE.method, map);
    if (result is Map) {
      return PluginImageBuffer.factoryMap(result);
    }
    return null;
  }

  static Future<PermissionResult> hasPermission() async {
    return PermissionResult.values.byName(await _channel
        .invokeMethod(PlatformMethod.HAS_PERMISSION_CAMERA.method));
  }

  static Future<PermissionResult> requestPermission() async {
    return PermissionResult.values.byName(await _channel
        .invokeMethod(PlatformMethod.REQUEST_PERMISSION_CAMERA.method));
  }
}

enum PermissionResult { GRANTED, DENIED, DENIED_TO_APP_SETTING }
