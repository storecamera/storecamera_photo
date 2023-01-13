package io.storecamera.storecamera_photo.storecamera_plugin_media

class MediaPluginConfig {
  companion object {
    const val CHANNEL_NAME = "io.storecamera.store_camera_plugin_media"
  }
}

enum class MediaPlatformMethod(val method: String) {
  GET_IMAGE_FOLDER("${MediaPluginConfig.CHANNEL_NAME}/GET_IMAGE_FOLDER"),
  GET_IMAGE_FOLDER_COUNT("${MediaPluginConfig.CHANNEL_NAME}/GET_IMAGE_FOLDER_COUNT"),
  GET_IMAGE_FILES("${MediaPluginConfig.CHANNEL_NAME}/GET_IMAGE_FILES"),
  GET_IMAGE_FILE("${MediaPluginConfig.CHANNEL_NAME}/GET_IMAGE_FILE"),
  GET_IMAGE_THUMBNAIL("${MediaPluginConfig.CHANNEL_NAME}/GET_IMAGE_THUMBNAIL"),
  READ_IMAGE_DATA("${MediaPluginConfig.CHANNEL_NAME}/READ_IMAGE_DATA"),
  CHECK_UPDATE("${MediaPluginConfig.CHANNEL_NAME}/CHECK_UPDATE"),
//  GET_IMAGE_INFO("${MediaPluginConfig.CHANNEL_NAME}/GET_IMAGE_INFO")
  ADD_IMAGE("${MediaPluginConfig.CHANNEL_NAME}/ADD_IMAGE"),
  DELETE_IMAGE("${MediaPluginConfig.CHANNEL_NAME}/DELETE_IMAGE"),
  IMAGE_BUFFER_CONVERTER_WITH_MAX_SIZE("${MediaPluginConfig.CHANNEL_NAME}/IMAGE_BUFFER_CONVERTER_WITH_MAX_SIZE"),
  SHARE_IMAGE("${MediaPluginConfig.CHANNEL_NAME}/SHARE_IMAGE"),
  HAS_PERMISSION_CAMERA("${MediaPluginConfig.CHANNEL_NAME}/HAS_PERMISSION_CAMERA"),
  REQUEST_PERMISSION_CAMERA("${MediaPluginConfig.CHANNEL_NAME}/REQUEST_PERMISSION_CAMERA"),
  ;

  companion object {
    fun from(method: String): MediaPlatformMethod? {
      for(value in values()) {
        if(value.method == method) {
          return value
        }
      }
      return null
    }
  }
}
