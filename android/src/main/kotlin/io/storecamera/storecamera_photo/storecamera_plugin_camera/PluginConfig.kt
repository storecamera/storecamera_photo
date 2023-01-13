package io.storecamera.storecamera_photo.storecamera_plugin_camera

class CameraPluginConfig {
  companion object {
    const val CHANNEL_NAME = "io.storecamera.store_camera_plugin_camera"
  }
}

enum class CameraPlatformMethod {
  HAS_PERMISSION,
  REQUEST_PERMISSION,
  ;

  companion object {
    fun from(method: String): CameraPlatformMethod? {
      try {
        val name = method.substringAfter("${CameraPluginConfig.CHANNEL_NAME}/")
        return CameraPlatformMethod.valueOf(name)
      } catch (e: Exception) {
      }
      return null
    }
  }
}
