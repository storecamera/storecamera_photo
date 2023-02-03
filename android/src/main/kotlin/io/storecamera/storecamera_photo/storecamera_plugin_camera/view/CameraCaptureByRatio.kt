package io.storecamera.storecamera_photo.storecamera_plugin_camera.view

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.exifinterface.media.ExifInterface
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.InputStream
import kotlin.Exception
import kotlin.concurrent.thread

/** CameraView */
class CameraCaptureByRatio(
    private val ratio: Float,
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

    override fun onImageSaved(outputFileResults: ImageCapture.OutputFileResults) {
        thread {
            try {
                val results = toMaxByteArrayByRatio(ratio)

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

    private fun getOriginalBitmapAndOrientation(): Pair<Bitmap?, Matrix> {
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
//        return Pair(BitmapFactory.decodeByteArray(byteArray, 0, byteArray.size), matrix)
//        return Pair(scaleImageByDensity(byteArray, 4096), matrix)
        return Pair(resizeImageBySampling(byteArray), matrix)
    }

    // ratio is width over height
    private fun toMaxByteArrayByRatio(ratio: Float): ByteArray {
        Log.d("#######", "toMaxByteArrayByRatio")
        val clipRatio : Float = 1 / ratio
        val (sourceBitmap, matrix) = getOriginalBitmapAndOrientation()

        val bitmapAndOrientation = sourceBitmap ?: return ByteArray(0)

        val sourceWidth = bitmapAndOrientation.width
        val sourceHeight = bitmapAndOrientation.height

        val (clipWidth, clipHeight) = sizeToFitSourceByRatio(clipRatio, sourceWidth, sourceHeight)

        val firstPixelInSourceX = (sourceWidth - clipWidth) / 2
        val firstPixelInSourceY = (sourceHeight - clipHeight) / 2

        Log.d("#######", "Source size: W$sourceWidth H$sourceHeight")
        val bitmap = Bitmap.createBitmap(bitmapAndOrientation,
            firstPixelInSourceX, firstPixelInSourceY,
            clipWidth, clipHeight,
            matrix, false)

        if(bitmap != bitmapAndOrientation) {
            bitmapAndOrientation.recycle()
        }

        Log.d("#######", "Clip size: W$clipWidth H$clipHeight")
        val outputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream)
        val byteArray = outputStream.toByteArray()
        outputStream.close()
        Log.d("#######", "First pixel position: W$firstPixelInSourceX H$firstPixelInSourceY")
        return byteArray
    }

    private fun sizeToFitSourceByRatio(ratio: Float, originalWidth: Int, originalHeight: Int) : Pair<Int, Int> {
        val (sourceWidth, sourceHeight) = Pair(originalWidth.toFloat(), originalHeight.toFloat())
        val sourceSlope = sourceHeight / sourceWidth
        val (width, height) = if(ratio > sourceSlope) Pair(sourceWidth, sourceWidth / ratio)
        else Pair(sourceHeight * ratio, sourceHeight)

        return Pair((width + 0.5).toInt(), (height + 0.5).toInt())
    }

    private fun scaleImageByDensity(byteArray: ByteArray, maxSide: Int) : Bitmap? {
        val (targetDensity, sourceDensity) = findDensity(ByteArrayInputStream(byteArray), maxSide)

        val options = BitmapFactory.Options()
        options.inPreferredConfig = Bitmap.Config.ARGB_8888
        options.inTargetDensity = targetDensity
        options.inDensity = sourceDensity
        options.inScaled = true

        var result: Bitmap? = null

        try {
            result = BitmapFactory.decodeStream(ByteArrayInputStream(byteArray), null, options)
            Log.d("#######", "Bitmap out width: ${options.outWidth}, height: ${options.outHeight}")
        } catch (e: Exception) {}

        return result
    }

    private fun findDensity(inputStream: InputStream, maxSide: Int): Pair<Int, Int> {
        val options = BitmapFactory.Options()
        options.inJustDecodeBounds = true

        var targetDensity = 0
        var sourceDensity = 100
        try {
            BitmapFactory.decodeStream(inputStream, null, options)
            Log.d("#######", "inDensity(${options.inDensity}), targetDensity(${options.inTargetDensity}), " +
                    "inScaled(${options.inScaled}), screenDensity(${options.inScreenDensity})")
            targetDensity = maxSide * sourceDensity / options.outWidth
            targetDensity = if(targetDensity > sourceDensity) sourceDensity else targetDensity
            Log.d("#######", "Density percent: $targetDensity%")
        } catch (e: Exception) {
            targetDensity = 0
            sourceDensity = 0
        } finally {
            inputStream.close()
        }

        return Pair(targetDensity, sourceDensity)
    }

    private fun resizeImageBySampling(byteArray: ByteArray) : Bitmap? {
        val inSampleSize: Int = decodeBitmapInSampleSize(ByteArrayInputStream(byteArray))

        val opts = BitmapFactory.Options()
        opts.inSampleSize = inSampleSize
        opts.inPreferredConfig = Bitmap.Config.ARGB_8888

        var result: Bitmap? = null
        try {
            result = BitmapFactory.decodeStream(ByteArrayInputStream(byteArray), null, opts)
        } catch (e: Exception) {
        }

        return result
    }

    private fun decodeBitmapInSampleSize(inputStream: InputStream): Int {
        val maxWidth = 4096//maxSizeOnBitmap
        val maxHeight = 4096//maxSizeOnBitmap

        val opts = BitmapFactory.Options()
        opts.inJustDecodeBounds = true

        var inSampleSize = 1
        try {
            BitmapFactory.decodeStream(inputStream, null, opts)
            while (opts.outWidth > maxWidth || opts.outHeight > maxHeight) {
                opts.outWidth /= 2
                opts.outHeight /= 2
                inSampleSize *= 2
            }
        } catch (e: Exception) {
        } finally {
            inputStream.close()
        }

        return inSampleSize
    }
}
