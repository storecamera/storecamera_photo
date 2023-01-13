package io.storecamera.storecamera_photo.storecamera_plugin_camera

import android.content.Context
import android.util.Log
import android.view.View

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.platform.PlatformView
import io.storecamera.storecamera_photo.storecamera_plugin_camera.data.*
import io.storecamera.storecamera_photo.storecamera_plugin_camera.view.CameraView

/** SelluryCameraPlugin */
class CameraPlatformView(
        messenger: BinaryMessenger,
        context: Context, 
        viewId: Int, 
        args: Any?) : PlatformView, MethodCallHandler {

  private val methodChannel = MethodChannel(messenger, "${CameraPluginConfig.CHANNEL_NAME}_$viewId").apply {
    setMethodCallHandler(this@CameraPlatformView)
  }

  private val view: CameraView = CameraView(context).apply {
    if(args is HashMap<*, *>) {
      initArgs(this, args)
    }
    setOnListener(object : CameraViewFlutterListener {
      override fun onCameraStatus(status: CameraStatus) {
        methodChannel.invokeMethod(FlutterViewMethod.ON_CAMERA_STATUS.method, status.pluginToMap())
      }

      override fun onCameraMotion(radian: Double) {
        methodChannel.invokeMethod(FlutterViewMethod.ON_CAMERA_MOTION.method, radian)
      }
    })
  }

  private fun initArgs(cameraView: CameraView, map: HashMap<*, *>) {
    val position = CameraPosition.from(map.getString("position"))
    if(position != null) {
      cameraView.initPosition = position
    }
  }

  override fun getView(): View = view

  override fun dispose() {
    methodChannel.setMethodCallHandler(null)
    view.setOnListener(null)
    view.deinit()
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    Log.i("KKH", "SelluryCameraPlatformView : onMethodCall ${call.method}")
    when (PlatformViewMethod.from(call.method)) {
      PlatformViewMethod.ON_PAUSE -> {
        view.onPause()
        result.success(null)
      }
      PlatformViewMethod.ON_RESUME -> {
        view.onResume()
        result.success(null)
      }
      PlatformViewMethod.CAPTURE -> {
        if(call.arguments is HashMap<*, *>) {
          val ratio = CameraRatio.from((call.arguments as HashMap<*, *>).getString("ratio"))
          val resolution = CameraResolution.from((call.arguments as HashMap<*, *>).getString("resolution"))
          if(ratio != null && resolution != null) {
            view.capture(ratio, resolution, {
              result.success(it)
            }, {
              result.success(it)
            })
            return
          }
        }
        result.success(null)
      }
      PlatformViewMethod.SET_CAMERA_POSITION -> {
        CameraPosition.from(call.arguments as? String)?.let {
          result.success(view.changeCamera(it)?.pluginToMap())
        } ?: result.success(null)
      }
      PlatformViewMethod.SET_TORCH -> {
        CameraTorch.from(call.arguments as? String)?.let {
          result.success(view.setTorch(it))
        } ?: result.success(false)
      }
      PlatformViewMethod.SET_FLASH -> {
        CameraFlash.from(call.arguments as? String)?.let {
          result.success(view.setFlash(it))
        } ?: result.success(false)
      }
      PlatformViewMethod.SET_ZOOM -> {
        var zoom: Float? = null
        if(call.arguments is Float) {
          zoom = call.arguments as Float
        } else if(call.arguments is Double) {
          zoom = (call.arguments as Double).toFloat()
        }
        
        zoom?.let {
          view.setZoom(it)
        }
        result.success(null)
      }
      PlatformViewMethod.SET_EXPOSURE -> {
        var exposure: Float? = null
        if(call.arguments is Float) {
          exposure = call.arguments as Float
        } else if(call.arguments is Double) {
          exposure = (call.arguments as Double).toFloat()
        }

        exposure?.let { 
          view.setExposure(it.toInt())
        }
        result.success(null)
      }
      PlatformViewMethod.SET_MOTION -> {
        CameraMotion.from(call.arguments as? String)?.let {
          view.setMotion(it)
        }
        result.success(null)
      }
      PlatformViewMethod.ON_TAP -> {
        (call.arguments as? HashMap<*, *>)?.let {
          val dx = it.getFloat("dx")
          val dy = it.getFloat("dy")
          if(dx != null && dy != null) {
            view.onTap(dx, dy)
          }
        }
        result.success(null)
      }
      null -> result.notImplemented()
    }
  }
}

interface CameraViewFlutterListener {
  fun onCameraStatus(status: CameraStatus)
  fun onCameraMotion(radian: Double)
}

fun HashMap<*, *>?.getFloat(key: Any): Float? {
  if(this == null) return null
  this[key]?.let {
    if(it is Number) {
      return it.toFloat()
    } else if(it is String) {
      return it.toFloatOrNull()
    }
  }
  return null
}

//fun HashMap<*, *>?.getInt(key: Any): Int? {
//  if(this == null) return null
//  this[key]?.let {
//    if(it is Number) {
//      return it.toInt()
//    } else if(it is String) {
//      return it.toIntOrNull()
//    }
//  }
//  return null
//}
//
//fun HashMap<*, *>?.getLong(key: Any): Long? {
//  if(this == null) return null
//  this[key]?.let {
//    if(it is Number) {
//      return it.toLong()
//    } else if(it is String) {
//      return it.toLongOrNull()
//    }
//  }
//  return null
//}

fun HashMap<*, *>?.getString(key: Any): String? {
  if(this == null) return null
  this[key]?.let {
    return if(it is String) {
      it
    } else {
      it.toString()
    }
  }
  return null
}
