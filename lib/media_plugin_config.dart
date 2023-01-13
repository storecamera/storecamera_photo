class PluginConfig {
  static const String CHANNEL_NAME = 'io.storecamera.store_camera_plugin_media';
}

enum PlatformMethod {
  GET_IMAGE_FOLDER,
  GET_IMAGE_FOLDER_COUNT,
  GET_IMAGE_FILES,
  GET_IMAGE_FILE,
  GET_IMAGE_THUMBNAIL,
  READ_IMAGE_DATA,
  CHECK_UPDATE,
  GET_IMAGE_INFO,
  ADD_IMAGE,
  DELETE_IMAGE,
  IMAGE_BUFFER_CONVERTER_WITH_MAX_SIZE,
  SHARE_IMAGE,

  // temporal enums. those will be removed in future.
  HAS_PERMISSION_CAMERA,
  REQUEST_PERMISSION_CAMERA,
}

extension PlatformMethodExtension on PlatformMethod {
  String get method {
    String _method = '';
    switch (this) {
      case PlatformMethod.GET_IMAGE_FOLDER:
        _method = '${PluginConfig.CHANNEL_NAME}/GET_IMAGE_FOLDER';
        break;
      case PlatformMethod.GET_IMAGE_FOLDER_COUNT:
        _method = '${PluginConfig.CHANNEL_NAME}/GET_IMAGE_FOLDER_COUNT';
        break;
      case PlatformMethod.GET_IMAGE_FILES:
        _method = '${PluginConfig.CHANNEL_NAME}/GET_IMAGE_FILES';
        break;
      case PlatformMethod.GET_IMAGE_FILE:
        _method = '${PluginConfig.CHANNEL_NAME}/GET_IMAGE_FILE';
        break;
      case PlatformMethod.GET_IMAGE_THUMBNAIL:
        _method = '${PluginConfig.CHANNEL_NAME}/GET_IMAGE_THUMBNAIL';
        break;
      case PlatformMethod.READ_IMAGE_DATA:
        _method = '${PluginConfig.CHANNEL_NAME}/READ_IMAGE_DATA';
        break;
      case PlatformMethod.CHECK_UPDATE:
        _method = '${PluginConfig.CHANNEL_NAME}/CHECK_UPDATE';
        break;
      case PlatformMethod.GET_IMAGE_INFO:
        _method = '${PluginConfig.CHANNEL_NAME}/GET_IMAGE_INFO';
        break;
      case PlatformMethod.ADD_IMAGE:
        _method = '${PluginConfig.CHANNEL_NAME}/ADD_IMAGE';
        break;
      case PlatformMethod.DELETE_IMAGE:
        _method = '${PluginConfig.CHANNEL_NAME}/DELETE_IMAGE';
        break;
      case PlatformMethod.IMAGE_BUFFER_CONVERTER_WITH_MAX_SIZE:
        _method =
            '${PluginConfig.CHANNEL_NAME}/IMAGE_BUFFER_CONVERTER_WITH_MAX_SIZE';
        break;
      case PlatformMethod.SHARE_IMAGE:
        _method = '${PluginConfig.CHANNEL_NAME}/SHARE_IMAGE';
        break;
      case PlatformMethod.HAS_PERMISSION_CAMERA:
        _method = '${PluginConfig.CHANNEL_NAME}/HAS_PERMISSION_CAMERA';
        break;
      case PlatformMethod.REQUEST_PERMISSION_CAMERA:
        _method = '${PluginConfig.CHANNEL_NAME}/REQUEST_PERMISSION_CAMERA';
        break;
    }

    return _method;
  }
}
