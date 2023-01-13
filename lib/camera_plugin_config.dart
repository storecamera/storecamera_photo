class PluginConfig {
  static const String CHANNEL_NAME = 'io.storecamera.store_camera_plugin_simple';
}

enum PlatformMethod {
  SEND_EMAIL,
  ANDROID_INTENT_LAUNCH_URL,
  PHONE_COUNTRY_CODE,
}

extension PlatformMethodExtension on PlatformMethod {
  String get method {
    String _method = '';
    switch(this) {
      case PlatformMethod.SEND_EMAIL:
        _method = '${PluginConfig.CHANNEL_NAME}/SEND_EMAIL';
        break;
      case PlatformMethod.ANDROID_INTENT_LAUNCH_URL:
        _method = '${PluginConfig.CHANNEL_NAME}/ANDROID_INTENT_LAUNCH_URL';
        break;
      case PlatformMethod.PHONE_COUNTRY_CODE:
        _method = '${PluginConfig.CHANNEL_NAME}/PHONE_COUNTRY_CODE';
        break;
    }

    return _method;
  }
}