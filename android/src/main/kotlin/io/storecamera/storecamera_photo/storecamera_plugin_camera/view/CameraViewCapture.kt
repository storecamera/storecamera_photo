package io.storecamera.storecamera_photo.storecamera_plugin_camera.view

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.os.Handler
import android.os.Looper
import android.util.Size
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.exifinterface.media.ExifInterface
import io.storecamera.storecamera_photo.storecamera_plugin_camera.data.CameraRatio
import io.storecamera.storecamera_photo.storecamera_plugin_camera.data.CameraResolution
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.InputStream
import kotlin.Exception
import kotlin.concurrent.thread

/** CameraView */
class CameraViewCapture(
        private val ratio: CameraRatio,
        private val resolution: CameraResolution,
        private val success: (byteArray: ByteArray) -> Unit,
        private val error: (error: String) -> Unit,
) : ImageCapture.OnImageSavedCallback {

    val outputStream = ByteArrayOutputStream()

    private fun onSuccess(byteArray: ByteArray) {
        Handler(Looper.getMainLooper()).post {
            success(byteArray)
            outputStream.close()
        }
    }

    private fun onError(error: String) {
        error(error)
        outputStream.close()
    }

    /// 1:1 Full : Original
    /// 1:1 Standard : 2048x2048
    /// 1:1 Low : 1024x1024
    /// 4:5 Full : Original
    /// 4:5 Standard : 2048x2560
    /// 4:5 Low : 1024x1280
    /// 3:4 Full : Original
    /// 3:4 Standard : 1536x2048
    /// 3:4 Low : 768x1024
    /// 9:16 Full : Original
    /// 9:16 Standard : 1440x2560
    /// 9:16 Low : 720x1280
    override fun onImageSaved(outputFileResults: ImageCapture.OutputFileResults) {
        thread {
            try {
                val results = when (ratio) {
                    CameraRatio.RATIO_1_1 -> when (resolution) {
                        CameraResolution.FULL -> toByteArray1d1(null)
                        CameraResolution.STANDARD -> toByteArray1d1(2048)
                        CameraResolution.LOW -> toByteArray1d1(1024)
                    }
                    CameraRatio.RATIO_4_5 -> when (resolution) {
                        CameraResolution.FULL -> toByteArrayBaseOnWidth(5.0 / 4.0, null)
                        CameraResolution.STANDARD -> toByteArrayBaseOnWidth(5.0 / 4.0, 2048)
                        CameraResolution.LOW -> toByteArrayBaseOnWidth(5.0 / 4.0, 1024)
                    }
                    CameraRatio.RATIO_3_4 -> when (resolution) {
                        CameraResolution.FULL -> outputStream.toByteArray()
                        CameraResolution.STANDARD -> toByteArray3d4(1536, 2048)
                        CameraResolution.LOW -> toByteArray3d4(768, 1024)
                    }
                    CameraRatio.RATIO_9_16 -> when (resolution) {
                        CameraResolution.FULL -> toByteArray9d16(null, null)
                        CameraResolution.STANDARD -> toByteArray9d16(1440, 2560)
                        CameraResolution.LOW -> toByteArray9d16(720, 1280)
                    }
                }

                onSuccess(results)
            } catch (e: Exception) {
                onError(e.message ?: "")
            }
        }
    }

    override fun onError(exception: ImageCaptureException) {
        Handler(Looper.getMainLooper()).post {
            onError(exception.message ?: "")
        }
    }

    private fun getOriginalBitmapAndOrientation(): Pair<Bitmap, Matrix> {
        val byteArray = outputStream.toByteArray()
        val io: InputStream = ByteArrayInputStream(byteArray)
        val exifInterface = ExifInterface(io)

        val matrix = when (exifInterface.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_UNDEFINED)) {
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> Matrix().apply { setScale(-1f, 1f) }
            ExifInterface.ORIENTATION_ROTATE_180 -> Matrix().apply { postRotate(180f) }
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> Matrix().apply { setScale(1f, -1f) }
            ExifInterface.ORIENTATION_TRANSPOSE -> Matrix().apply {
                setScale(-1f, 1f)
                postRotate(90F)
            }
            ExifInterface.ORIENTATION_ROTATE_90 -> Matrix().apply { postRotate(90f) }
            ExifInterface.ORIENTATION_TRANSVERSE -> Matrix().apply {
                setScale(-1f, 1f)
                postRotate(90F)
            }
            ExifInterface.ORIENTATION_ROTATE_270 -> Matrix().apply { postRotate(270f) }
            else -> Matrix()
        }

        io.close()
        return Pair(BitmapFactory.decodeByteArray(byteArray, 0, byteArray.size), matrix)
    }

    private fun toByteArray1d1(size: Int?): ByteArray {
        val bitmapAndOrientation = getOriginalBitmapAndOrientation()

        val matrix = bitmapAndOrientation.second
        val bitmapDx: Int
        val bitmapDy: Int
        when {
            bitmapAndOrientation.first.width > bitmapAndOrientation.first.height -> {
                bitmapDx = bitmapAndOrientation.first.width - bitmapAndOrientation.first.height
                bitmapDy = 0
            }
            bitmapAndOrientation.first.width < bitmapAndOrientation.first.height -> {
                bitmapDx = 0
                bitmapDy = bitmapAndOrientation.first.height - bitmapAndOrientation.first.width
            }
            else -> {
                bitmapDx = 0
                bitmapDy = 0
            }
        }
        val bitmapWidth = bitmapAndOrientation.first.width - bitmapDx
        val bitmapHeight = bitmapAndOrientation.first.height - bitmapDy
        if(size != null && size < bitmapWidth && size < bitmapHeight) {
            matrix.postScale(size.toFloat() / bitmapWidth.toFloat(), size.toFloat() / bitmapHeight.toFloat())
        }

        val bitmap = Bitmap.createBitmap(
                bitmapAndOrientation.first,
                bitmapDx / 2, bitmapDy / 2,
                bitmapWidth,
                bitmapHeight,
                matrix, true)

        if(bitmap != bitmapAndOrientation.first) {
            bitmapAndOrientation.first.recycle()
        }

        val outputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream)
        val byteArray = outputStream.toByteArray()
        outputStream.close()
        return byteArray
    }

    private fun toByteArrayBaseOnWidth(ratio: Double, width: Int?): ByteArray {
        val bitmapAndOrientation = getOriginalBitmapAndOrientation()

        val matrix = bitmapAndOrientation.second
        val bitmapDx: Int
        val bitmapDy: Int
        val bitmapWidth = bitmapAndOrientation.first.width
        val bitmapHeight = bitmapAndOrientation.first.height
        if(bitmapWidth > bitmapHeight) {
            bitmapDx = (bitmapWidth - bitmapHeight * ratio).toInt()
            bitmapDy = 0
            if(width != null && width < bitmapHeight) {
                matrix.postScale(width.toFloat() / bitmapHeight.toFloat(), width.toFloat() / bitmapHeight.toFloat())
            }
        } else {
            bitmapDx = 0
            bitmapDy = (bitmapHeight - bitmapWidth * ratio).toInt()
            if(width != null && width < bitmapWidth) {
                matrix.postScale(width.toFloat() / bitmapWidth.toFloat(), width.toFloat() / bitmapWidth.toFloat())
            }
        }

        val bitmap = Bitmap.createBitmap(
                bitmapAndOrientation.first,
                bitmapDx / 2, bitmapDy / 2,
                bitmapWidth - bitmapDx,
                bitmapHeight - bitmapDy,
                matrix, true)

        if(bitmap != bitmapAndOrientation.first) {
            bitmapAndOrientation.first.recycle()
        }

        val outputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream)
        val byteArray = outputStream.toByteArray()
        outputStream.close()
        return byteArray
    }

    private fun toByteArray3d4(width: Int, height: Int): ByteArray {
        val bitmapAndOrientation = getOriginalBitmapAndOrientation()

        val matrix = bitmapAndOrientation.second
        val bitmapWidth = bitmapAndOrientation.first.width
        val bitmapHeight = bitmapAndOrientation.first.height
        val targetWidth: Int
        val targetHeight: Int
        if(bitmapWidth > bitmapHeight) {
            targetWidth = height
            targetHeight = width
        } else {
            targetWidth = width
            targetHeight = height
        }
        if(targetWidth < bitmapWidth && targetHeight < bitmapHeight) {
            matrix.postScale(targetWidth.toFloat() / bitmapWidth.toFloat(), targetHeight.toFloat() / bitmapHeight.toFloat())
        }
        val bitmap = Bitmap.createBitmap(
                bitmapAndOrientation.first,
                0, 0,
                bitmapWidth,
                bitmapHeight,
                matrix, true)

        if(bitmap != bitmapAndOrientation.first) {
            bitmapAndOrientation.first.recycle()
        }

        val outputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream)
        val byteArray = outputStream.toByteArray()
        outputStream.close()
        return byteArray
    }

    private fun toByteArray9d16(width: Int?, height: Int?): ByteArray {
        val bitmapAndOrientation = getOriginalBitmapAndOrientation()

        val matrix = bitmapAndOrientation.second
        val bitmapDx: Int
        val bitmapDy: Int
        val bitmapWidth = bitmapAndOrientation.first.width
        val bitmapHeight = bitmapAndOrientation.first.height
        if(bitmapWidth > bitmapHeight) {
            bitmapDx = 0
            bitmapDy = bitmapHeight - bitmapWidth * 9/16
            if(height != null && height < bitmapWidth) {
                matrix.postScale(height.toFloat() / bitmapWidth.toFloat(), height.toFloat() / bitmapWidth.toFloat())
            }
        } else {
            bitmapDx = bitmapWidth - bitmapHeight * 9/16
            bitmapDy = 0
            if(height != null && height < bitmapHeight) {
                matrix.postScale(height.toFloat() / bitmapHeight.toFloat(), height.toFloat() / bitmapHeight.toFloat())
            }
        }

        val bitmap = Bitmap.createBitmap(
                bitmapAndOrientation.first,
                bitmapDx / 2, bitmapDy / 2,
                bitmapWidth - bitmapDx,
                bitmapHeight - bitmapDy,
                matrix, true)

        if(bitmap != bitmapAndOrientation.first) {
            bitmapAndOrientation.first.recycle()
        }

        val outputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream)
        val byteArray = outputStream.toByteArray()
        outputStream.close()
        return byteArray
    }

    // ratio is y over x
    private fun toMaxByteArrayByRatio(ratio: Double): ByteArray {
        val bitmapAndOrientation = getOriginalBitmapAndOrientation()
        val matrix = bitmapAndOrientation.second
        val sourceWidth = bitmapAndOrientation.first.width
        val sourceHeight = bitmapAndOrientation.first.height
        val (clipWidth, clipHeight) = sizeToFitSourceByRatio(ratio, sourceWidth, sourceHeight)
        val firstPixelInSourceX = (sourceWidth - clipWidth) / 2
        val firstPixelInSourceY = (sourceHeight - clipHeight) / 2

        val bitmap = Bitmap.createBitmap(bitmapAndOrientation.first,
            firstPixelInSourceX, firstPixelInSourceY,
            clipWidth, clipHeight, matrix, true)

        if(bitmap != bitmapAndOrientation.first) {
            bitmapAndOrientation.first.recycle()
        }

        val outputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream)
        val byteArray = outputStream.toByteArray()
        outputStream.close()
        return byteArray
    }

    private fun sizeToFitSourceByRatio(ratio: Double, originalWidth: Int, originalHeight: Int) : Pair<Int, Int> {
        val (sourceWidth, sourceHeight) = Pair(originalWidth.toDouble(), originalHeight.toDouble())
        val sourceSlope = sourceHeight / sourceWidth
        val(width, height) = if(ratio > sourceSlope) Pair(sourceWidth, sourceWidth / ratio)
                             else Pair(sourceHeight * ratio, sourceHeight)

        return Pair((width + 0.5).toInt(), (height + 0.5).toInt())
    }
}
