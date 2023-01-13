package io.storecamera.storecamera_photo

import android.app.Activity
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.util.Log
import android.util.Size
import android.Manifest
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.PluginRegistry

import io.reactivex.Observable
import io.reactivex.android.schedulers.AndroidSchedulers
import io.reactivex.schedulers.Schedulers

import io.storecamera.storecamera_photo.storecamera_plugin_media.MediaPlatformMethod
import io.storecamera.storecamera_photo.storecamera_plugin_media.data.PluginBitmap
import io.storecamera.storecamera_photo.storecamera_plugin_media.data.PluginImageBuffer
import io.storecamera.storecamera_photo.storecamera_plugin_media.data.PluginImageFormat
import io.storecamera.storecamera_photo.storecamera_plugin_media.data.PluginSortOrder
import io.storecamera.storecamera_photo.storecamera_plugin_media.media_query.PluginImageQuery
import io.storecamera.storecamera_photo.storecamera_plugin_media.media_query.PluginImageQueryM
import io.storecamera.storecamera_photo.storecamera_plugin_media.media_query.PluginImageQueryQ
import io.storecamera.storecamera_photo.storecamera_plugin_media.PluginPermission
import io.storecamera.storecamera_photo.storecamera_plugin_media.BitmapHelper
import io.storecamera.storecamera_photo.storecamera_plugin_media.MediaPluginConfig

import io.storecamera.storecamera_photo.storecamera_plugin_camera.CameraPlatformViewFactory
import io.storecamera.storecamera_photo.storecamera_plugin_camera.CameraPluginConfig

import java.nio.ByteBuffer


enum class PermissionResult {
    GRANTED,
    DENIED,
    DENIED_TO_APP_SETTING
}

/** StoreCameraPluginMediaPlugin */
class StoreCameraPhoto : PluginRegistry.RequestPermissionsResultListener,
    FlutterPlugin, MethodCallHandler, ActivityAware {

    // Camera
    private var cameraPlatformViewFactory: CameraPlatformViewFactory? = null
    private var cameraActivityPluginBinding: ActivityPluginBinding? = null

    private val hashCode = CameraPluginConfig.CHANNEL_NAME.hashCode()
    private var requestCode = if (hashCode > 0) hashCode else -hashCode
    private val requests = mutableListOf<(PermissionResult) -> Unit>()

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == this.requestCode) {
            var checkResult = true

            for (result in grantResults) {
                if (result != PackageManager.PERMISSION_GRANTED) {
                    checkResult = false
                    break
                }
            }

            if (checkResult) {
                for (request in requests) {
                    request(PermissionResult.GRANTED)
                }
                requests.clear()
            } else {
                if (cameraActivityPluginBinding?.activity?.let {
                        ActivityCompat.shouldShowRequestPermissionRationale(
                            it,
                            Manifest.permission.CAMERA
                        )
                    } == true) {
                    for (request in requests) {
                        request(PermissionResult.DENIED)
                    }
                    requests.clear()
                } else {
                    for (request in requests) {
                        request(PermissionResult.DENIED_TO_APP_SETTING)
                    }
                    requests.clear()
                }
            }
            return true
        }
        return false
    }


    // Media A.K.A Albums
    companion object {
        private const val WRITE_SENDER_REQUEST_CODE = 0x1001
    }

    private lateinit var mediaChannel : MethodChannel
    private var mediaActivityPluginBinding: ActivityPluginBinding? = null
    private var mediaPluginPermission = PluginPermission(
        { permission ->
            mediaActivityPluginBinding?.activity?.let {
                it.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
            } ?: false
        },
        { requestCode, permissions ->
            mediaActivityPluginBinding?.activity?.let {
                it.requestPermissions(permissions, requestCode)
                true
            } ?: false
        }
    )
    private val pluginMediaQuery: PluginImageQuery = if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) PluginImageQueryQ { intentSender, onResult ->
        if(writeImageRequestResult != null) {
            onResult(false)
        }

        mediaActivityPluginBinding?.activity?.let { activity ->
            writeImageRequestResult = onResult
            ActivityCompat.startIntentSenderForResult(activity, intentSender, WRITE_SENDER_REQUEST_CODE, null, 0, 0, 0, null)
        } ?: onResult(false)
    } else PluginImageQueryM()

    private var writeImageRequestResult: ((result: Boolean) -> Unit)? = null

    private val requestPermissionsResultListener = PluginRegistry.RequestPermissionsResultListener { requestCode, permissions, grantResults ->
        return@RequestPermissionsResultListener mediaPluginPermission.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    private val onActivityResult = PluginRegistry.ActivityResultListener { requestCode, resultCode, _ ->
        when(requestCode) {
            WRITE_SENDER_REQUEST_CODE -> {
                val result = writeImageRequestResult
                writeImageRequestResult = null
                Log.i("KKH", "WRITE_SENDER_REQUEST_CODE RESULT : $resultCode")
                result?.let {
                    it(resultCode == Activity.RESULT_OK)
                }
                true
            }
            else -> false
        }
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when(MediaPlatformMethod.from(call.method)) {
            MediaPlatformMethod.GET_IMAGE_FOLDER -> {
                pluginMediaQuery.getImageFolder(mediaPluginPermission)
                    .observeOn(AndroidSchedulers.mainThread())
                    .subscribe({
                        result.success(it.pluginToMap())
                    }, {
                        result.error("GET_IMAGE_FOLDER", it.message, null)
                    })
            }
            MediaPlatformMethod.GET_IMAGE_FOLDER_COUNT -> {
                Observable.fromCallable {
                    pluginMediaQuery.getImageFolderCount(call.arguments as? String)
                }
                    .subscribeOn(Schedulers.io())
                    .observeOn(AndroidSchedulers.mainThread())
                    .subscribe({
                        result.success(it)
                    }, {
                        result.success(null)
                    })
            }
            MediaPlatformMethod.GET_IMAGE_FILES -> {
                val map: HashMap<*, *> = call.arguments as? HashMap<*, *> ?: HashMap<Any, Any>()
                pluginMediaQuery.getImages(
                    mediaPluginPermission,
                    map.getString("id"),
                    PluginSortOrder.from(map.getString("sortOrder")) ?: PluginSortOrder.DATE_DESC,
                    map.getInt("offset"),
                    map.getInt("limit")
                )
                    .subscribeOn(Schedulers.io())
                    .observeOn(AndroidSchedulers.mainThread())
                    .subscribe({
                        result.success(it.pluginToMap())
                    }, {
                        result.error("GET_IMAGE_FILES", it.message, null)
                    })
            }
            MediaPlatformMethod.GET_IMAGE_FILE -> {
                val map: HashMap<*, *> = call.arguments as? HashMap<*, *> ?: HashMap<Any, Any>()
                map.getLong("id")?.let { id ->
                    pluginMediaQuery.getImage(mediaPluginPermission, id)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread())
                        .subscribe({
                            result.success(it?.pluginToMap())
                        }, {
                            result.error("GET_IMAGE_FILE", it.message, null)
                        })
                } ?: result.success(null)
            }
            MediaPlatformMethod.GET_IMAGE_THUMBNAIL -> {
                Observable.fromCallable<PluginBitmap> {
                    val map: HashMap<*, *> = call.arguments as? HashMap<*, *> ?: HashMap<Any, Any>()

                    val bitmap = map.getLong("id")?.let {
                        pluginMediaQuery.getImageThumbnail(
                            it,
                            width = (map.getInt("width")) ?: 256,
                            height = (map.getInt("height")) ?: 256
                        )
                    }
                    bitmap?.let {
                        PluginBitmap.createARGB(it)
                    }
                }
                    .subscribeOn(Schedulers.io())
                    .observeOn(AndroidSchedulers.mainThread())
                    .subscribe({
                        result.success(it.pluginToMap())
                    }, {
                        result.success(null)
                    })
            }
            MediaPlatformMethod.READ_IMAGE_DATA -> {
                Observable.fromCallable<ByteArray> {
                    if(call.arguments is String) {
                        (call.arguments as String).toLongOrNull()?.let {
                            return@fromCallable pluginMediaQuery.getImageReadBytes(it)
                        }
                    }
                    return@fromCallable null
                }
                    .subscribeOn(Schedulers.io())
                    .observeOn(AndroidSchedulers.mainThread())
                    .subscribe({
                        result.success(it)
                    }, {
                        result.success(null)
                    })
            }
            MediaPlatformMethod.CHECK_UPDATE -> {
                var timeMs: Long? = null
                if(call.arguments is Int) {
                    timeMs = (call.arguments as Int).toLong()
                } else if(call.arguments is Long) {
                    timeMs = call.arguments as Long
                }
                result.success(pluginMediaQuery.checkUpdate(timeMs))
            }
//      PlatformMethod.GET_IMAGE_INFO -> Observable.fromCallable<PluginImageInfo> {
//        if(call.arguments is String) {
//          (call.arguments as String).toLongOrNull()?.let {
//            return@fromCallable pluginMediaQuery.getImageInfo(it)
//          }
//        }
//        return@fromCallable null
//      }
//              .subscribeOn(Schedulers.io())
//              .observeOn(AndroidSchedulers.mainThread())
//              .subscribe({
//                result.success(it.pluginToMap())
//              }, {
//                result.success(null)
//              })
            MediaPlatformMethod.ADD_IMAGE -> {
                (call.arguments as? HashMap<*, *>)?.let { map ->
                    val folder = map.getString("folder") ?: ""
                    val name = map.getString("name")
                    val byteArray: ByteArray? = map["buffer"] as? ByteArray
                    val inputFormat = PluginImageFormat.from(map.getString("input"))
                    val outputFormat = PluginImageFormat.from(map.getString("output"))

                    if(name != null && byteArray != null && inputFormat != null && outputFormat != null) {
                        if(inputFormat == outputFormat) {
                            pluginMediaQuery.addImage(mediaPluginPermission, byteArray, folder, name) {
                                result.success(it)
                            }
                        } else {
                            @Suppress("UNUSED_VARIABLE") val dispose = Observable.fromCallable {
                                when(inputFormat) {
                                    PluginImageFormat.BITMAP -> {
                                        var resultBitmap: Bitmap? = null
                                        val width: Int? = map.getInt("width")
                                        val height: Int? = map.getInt("height")
                                        if(width != null && height != null) {
                                            resultBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                                            resultBitmap.copyPixelsFromBuffer(ByteBuffer.wrap(byteArray))
                                        }
                                        resultBitmap
                                    }
                                    PluginImageFormat.JPG, PluginImageFormat.PNG -> {
                                        BitmapFactory.decodeByteArray(byteArray, 0, byteArray.size)
                                    }
                                }
                            }
                                .subscribeOn(Schedulers.io())
                                .observeOn(AndroidSchedulers.mainThread())
                                .subscribe({ bitmap1 ->
                                    bitmap1?.let { bitmap2 ->
                                        pluginMediaQuery.addImage(mediaPluginPermission, bitmap2, outputFormat, folder, name) {
                                            bitmap2.recycle()
                                            result.success(it)
                                        }
                                    } ?: result.success(false)
                                }, {
                                    result.success(false)
                                })
                        }
                        return
                    }
                }
                result.success(false)
            }
            MediaPlatformMethod.DELETE_IMAGE -> {
                (call.arguments as? ArrayList<*>)?.let { list ->
                    val ids = mutableListOf<Long>()
                    for(id in list) {
                        if(id is String) {
                            id.toLongOrNull()?.let {
                                ids.add(it)
                            }
                        }
                    }

                    if(ids.isNotEmpty()) {
                        pluginMediaQuery.deleteImage(mediaPluginPermission, ids.toTypedArray())
                            .observeOn(AndroidSchedulers.mainThread())
                            .subscribe({ results ->
                                result.success(results.map { it.toString() })
                            }, {
                                result.success(mutableListOf<String>())
                            })
                    }
                    return
                } ?: result.success(mutableListOf<String>())
            }
            MediaPlatformMethod.IMAGE_BUFFER_CONVERTER_WITH_MAX_SIZE -> {
                (call.arguments as? HashMap<*, *>)?.let { map ->
                    PluginImageBuffer.map(map)?.let { pluginImageBuffer ->
                        val outputFormat = PluginImageFormat.from(map.getString("output")) ?: pluginImageBuffer.format
                        val maxWidth = map.getInt("maxWidth")
                        val maxHeight = map.getInt("maxHeight")
                        @Suppress("UNUSED_VARIABLE") val dispose = Observable.fromCallable {
                            val sizedBitmap = pluginImageBuffer.bitmap()?.let {
                                if(maxWidth != null && maxHeight != null) {
                                    val rect = BitmapHelper.centerInsideRect(Size(it.width, it.height), Size(maxWidth, maxHeight))
                                    val scaleBitmap = Bitmap.createScaledBitmap(it, rect.width(), rect.height(), true)
                                    it.recycle()
                                    scaleBitmap
                                } else {
                                    it
                                }
                            }
                            val buffer = PluginImageBuffer.init(outputFormat, sizedBitmap)
                            sizedBitmap?.recycle()
                            buffer
                        }.subscribeOn(Schedulers.io())
                            .observeOn(AndroidSchedulers.mainThread())
                            .subscribe({ buffer ->
                                result.success(buffer?.pluginToMap())
                            }, {
                                result.success(null)
                            })
                        return
                    }
                }
                result.success(null)
            }
            MediaPlatformMethod.SHARE_IMAGE -> {
                (call.arguments as? ArrayList<*>)?.let { list ->
                    val ids = mutableListOf<Long>()
                    for (id in list) {
                        val idLong: Long? = when (id) {
                            is Number -> id.toLong()
                            is String -> id.toLongOrNull()
                            else -> null
                        }

                        idLong?.let {
                            ids.add(idLong)
                        }
                    }

                    result.success(mediaActivityPluginBinding?.activity?.let {
                        pluginMediaQuery.shareImages(it, ids)
                    } ?: false)
                }
            }
            // Temporally, followings are moved from camera
            MediaPlatformMethod.HAS_PERMISSION_CAMERA -> {
                if (cameraActivityPluginBinding?.activity?.checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
                    result.success(PermissionResult.GRANTED.name)
                } else {
                    result.success(PermissionResult.DENIED.name)
                }
            }
            MediaPlatformMethod.REQUEST_PERMISSION_CAMERA -> {
                val activity = cameraActivityPluginBinding?.activity
                if (activity != null) {
                    if (activity.checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
                        result.success(PermissionResult.GRANTED.name)
                    } else {
                        if (requests.isEmpty()) {
                            requests.add {
                                result.success(it.name)
                            }
                            activity.requestPermissions(
                                arrayOf(Manifest.permission.CAMERA),
                                ++requestCode
                            )
                        } else {
                            requests.add {
                                result.success(it.name)
                            }
                        }
                    }
                } else {
                    result.success(PermissionResult.DENIED.name)
                }
            }
            null -> result.notImplemented()
        }
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        mediaChannel = MethodChannel(flutterPluginBinding.binaryMessenger, MediaPluginConfig.CHANNEL_NAME)
        mediaChannel.setMethodCallHandler(this)

        cameraPlatformViewFactory = CameraPlatformViewFactory(flutterPluginBinding.binaryMessenger)
        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            CameraPluginConfig.CHANNEL_NAME,
            cameraPlatformViewFactory!!
        )
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        mediaChannel.setMethodCallHandler(null)

        cameraPlatformViewFactory = null
    }

    override fun onDetachedFromActivity() {
        mediaActivityPluginBinding?.removeRequestPermissionsResultListener(requestPermissionsResultListener)
        mediaActivityPluginBinding?.removeActivityResultListener(onActivityResult)
        mediaActivityPluginBinding = null
        mediaPluginPermission.close()
        pluginMediaQuery.close()

        cameraActivityPluginBinding?.removeRequestPermissionsResultListener(this)
        cameraActivityPluginBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        mediaActivityPluginBinding = binding
        mediaActivityPluginBinding?.addRequestPermissionsResultListener(requestPermissionsResultListener)
        mediaActivityPluginBinding?.addActivityResultListener(onActivityResult)
        mediaActivityPluginBinding?.activity?.let {
            pluginMediaQuery.init(it)
        }

        cameraActivityPluginBinding?.removeRequestPermissionsResultListener(this)
        cameraActivityPluginBinding = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        mediaActivityPluginBinding = binding
        mediaActivityPluginBinding?.addRequestPermissionsResultListener(requestPermissionsResultListener)
        mediaActivityPluginBinding?.addActivityResultListener(onActivityResult)
        mediaActivityPluginBinding?.activity?.let {
            pluginMediaQuery.init(it)
        }

        cameraActivityPluginBinding = binding
        cameraActivityPluginBinding?.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        mediaActivityPluginBinding?.removeRequestPermissionsResultListener(requestPermissionsResultListener)
        mediaActivityPluginBinding?.removeActivityResultListener(onActivityResult)
        mediaActivityPluginBinding = null
        mediaPluginPermission.close()
        pluginMediaQuery.close()
    }
}

fun HashMap<*, *>?.getInt(key: Any): Int? {
    if(this == null) return null
    this[key]?.let {
        if(it is Number) {
            return it.toInt()
        } else if(it is String) {
            return it.toIntOrNull()
        }
    }
    return null
}

fun HashMap<*, *>?.getLong(key: Any): Long? {
    if(this == null) return null
    this[key]?.let {
        if(it is Number) {
            return it.toLong()
        } else if(it is String) {
            return it.toLongOrNull()
        }
    }
    return null
}

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
