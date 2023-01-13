package io.storecamera.storecamera_photo.storecamera_plugin_media

import android.content.ContentUris
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.graphics.Rect
import android.provider.MediaStore
import android.util.Size
import androidx.exifinterface.media.ExifInterface
import java.io.ByteArrayInputStream
import java.io.InputStream
import java.nio.ByteBuffer

object BitmapHelper {

    fun createBitmapFromBitmapByteArray(byteArray: ByteArray, width: Int, height: Int): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        bitmap.copyPixelsFromBuffer(ByteBuffer.wrap(byteArray))
        return bitmap
    }

    fun decodeBitmapFromByteArray(byteArray: ByteArray): Bitmap? {
        val inSampleSize: Int = decodeBitmapInSampleSize(ByteArrayInputStream(byteArray))
        val exitOrientation: Int = decodeBitmapExitOrientation(ByteArrayInputStream(byteArray))

        val opts = BitmapFactory.Options()
        opts.inSampleSize = inSampleSize
        opts.inPreferredConfig = Bitmap.Config.ARGB_8888

        var result: Bitmap? = null
        try {
            result = BitmapFactory.decodeStream(ByteArrayInputStream(byteArray), null, opts)?.let {
                orientationBitmap(it, exitOrientation)
            }
        } catch (e: Exception) {
        }

        return result
    }

    fun decodeBitmapFromPngByteArray(byteArray: ByteArray): Bitmap? {
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

    private fun decodeBitmapExitOrientation(inputStream: InputStream): Int {
        var orientation: Int = ExifInterface.ORIENTATION_UNDEFINED
        try {
            val exif = ExifInterface(inputStream)
            orientation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, orientation)
        } catch (e: Exception) {
        } finally {
            inputStream.close()
        }
        return orientation
    }

    private fun orientationBitmap(bitmap: Bitmap, exifOrientation: Int): Bitmap =
            matrixBitmap(bitmap, orientationMatrix(exifOrientation))

    private fun orientationMatrix(exifOrientation: Int): Matrix = when (exifOrientation) {
        ExifInterface.ORIENTATION_ROTATE_90 -> {
            Matrix().apply {
                postRotate(90f)
            }
        }
        ExifInterface.ORIENTATION_ROTATE_180 -> {
            Matrix().apply {
                postRotate(180f)
            }
        }
        ExifInterface.ORIENTATION_ROTATE_270 -> {
            Matrix().apply {
                postRotate(270f)
            }
        }
        ExifInterface.ORIENTATION_TRANSVERSE -> {
            Matrix().apply {
                setScale(-1f, 1f)
                postRotate(90F)
            }
        }
        ExifInterface.ORIENTATION_TRANSPOSE -> {
            Matrix().apply {
                setScale(-1f, 1f)
                postRotate(90F)
            }
        }
        ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> {
            Matrix().apply {
                setScale(-1f, 1f)
            }
        }
        else -> Matrix()
    }

    private fun matrixBitmap(bitmap: Bitmap, matrix: Matrix?): Bitmap {
        val result = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
        if(bitmap != result) {
            bitmap.recycle()
        }
        return result
    }

    fun centerInsideRect(source: Size, target: Size): Rect {
        if(source.width == target.width && source.height == target.height) {
            return Rect(0, 0, source.width, source.height)
        }

        val sourceRatio: Double = source.width.toDouble() / source.height.toDouble()
        val targetRatio: Double = target.width.toDouble() / target.height.toDouble()

        return if(sourceRatio < targetRatio) {
            val width = (source.width * (target.height.toDouble() / source.height.toDouble())).toInt()
            val height = target.height
            Rect(
                    (target.width - width) / 2,
                    0,
                    (target.width - width) / 2 + width,
                    height)
        } else {
            val width = target.width
            val height = (source.height * (target.width.toDouble() / source.width.toDouble())).toInt()
            Rect(
                    0,
                    (target.height - height) / 2,
                    width,
                    (target.height - height) / 2 + height)
        }
    }

    fun centerCropRect(source: Size, target: Size): Rect {
        if(source.width == target.width && source.height == target.height) {
            return Rect(0, 0, source.width, source.height)
        }

        val sourceRatio: Double = source.width.toDouble() / source.height.toDouble()
        val targetRatio: Double = target.width.toDouble() / target.height.toDouble()

        return if(sourceRatio > targetRatio) {
            val width = (source.height * targetRatio).toInt()
            Rect(
                    (source.width - width) / 2,
                    0,
                    (source.width - width) / 2 + width,
                    source.height)
        } else {
            val height = (source.width / targetRatio).toInt()
            Rect(
                    0,
                    (source.height - height) / 2,
                    source.width,
                    (source.height - height) / 2 + height)
        }
    }
}