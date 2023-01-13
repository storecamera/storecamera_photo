package io.storecamera.storecamera_photo.storecamera_plugin_camera

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/** CameraPlatformViewFactory */
class CameraPlatformViewFactory(
  private val messenger: BinaryMessenger
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
  override fun create(context: Context?, viewId: Int, args: Any?): PlatformView =
    CameraPlatformView(messenger, context!!, viewId, args)
}

enum class PlatformViewMethod {
  ON_PAUSE,
  ON_RESUME,
  CAPTURE,
  SET_CAMERA_POSITION,
  SET_TORCH,
  SET_FLASH,
  SET_ZOOM,
  SET_EXPOSURE,
  SET_MOTION,
  ON_TAP,
  ;

  companion object {
    fun from(method: String): PlatformViewMethod? {
      try {
        val name = method.substringAfter("${CameraPluginConfig.CHANNEL_NAME}/")
        return valueOf(name)
      } catch (e: Exception) {
      }
      return null
    }
  }
}

enum class FlutterViewMethod(val method: String) {
  ON_CAMERA_STATUS("${CameraPluginConfig.CHANNEL_NAME}/ON_CAMERA_STATUS"),
  ON_CAMERA_MOTION("${CameraPluginConfig.CHANNEL_NAME}/ON_CAMERA_MOTION")
}