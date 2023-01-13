package io.storecamera.storecamera_photo.storecamera_plugin_media.data

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import androidx.core.graphics.BitmapCompat
import io.storecamera.storecamera_photo.storecamera_plugin_media.BitmapHelper
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.nio.ByteBuffer

class PluginImageBuffer(
        val width: Int?,
        val height: Int?,
        val format: PluginImageFormat,
        private val buffer: ByteArray
) : PluginToMap {

    companion object {
        fun init(format: PluginImageFormat, bitmap: Bitmap?): PluginImageBuffer? =
                bitmap?.let {
                    when(format) {
                        PluginImageFormat.BITMAP -> {
                            val byteCount = BitmapCompat.getAllocationByteCount(it)
                            val buffer: ByteBuffer = ByteBuffer.allocate(byteCount) //Create a new buffer
                            it.copyPixelsToBuffer(buffer) //Move the byte dat
                            PluginImageBuffer(it.width, it.height, format, buffer.array())
                        }
                        PluginImageFormat.JPG -> {
                            var pluginImageBuffer: PluginImageBuffer? = null
                            var out: ByteArrayOutputStream? = null
                            try {
                                out = ByteArrayOutputStream()
                                it.compress(Bitmap.CompressFormat.JPEG, 100, out)
                                pluginImageBuffer = PluginImageBuffer(it.width, it.height, format, out.toByteArray())
                            } catch (e: Exception) {
                                e.printStackTrace()
                            } finally {
                                try {
                                    out?.close()
                                } catch (e: IOException) {
                                    e.printStackTrace()
                                }
                            }
                            return pluginImageBuffer
                        }
                        PluginImageFormat.PNG -> {
                            var pluginImageBuffer: PluginImageBuffer? = null
                            var out: ByteArrayOutputStream? = null
                            try {
                                out = ByteArrayOutputStream()
                                it.compress(Bitmap.CompressFormat.PNG, 100, out)
                                pluginImageBuffer = PluginImageBuffer(it.width, it.height, format, out.toByteArray())
                            } catch (e: Exception) {
                                e.printStackTrace()
                            } finally {
                                try {
                                    out?.close()
                                } catch (e: IOException) {
                                    e.printStackTrace()
                                }
                            }
                            return pluginImageBuffer
                        }
                    }
                }

        fun map(hashMap: HashMap<*, *>?): PluginImageBuffer? {
            val map = hashMap ?: return null
            val format = PluginImageFormat.from(map["format"] as? String) ?: return null
            val buffer = (map["buffer"] as? ByteArray) ?: return null
            val width = map["width"] as? Int
            val height = map["height"] as? Int
            return PluginImageBuffer(width, height, format, buffer)
        }
    }

    fun bitmap(): Bitmap? = when(format) {
        PluginImageFormat.BITMAP -> {
            var result: Bitmap? = null
            this.width?.let {  width ->
                this.height?.let { height ->
                    result = BitmapHelper.createBitmapFromBitmapByteArray(buffer, width, height)
                }
            }
            result
        }
        PluginImageFormat.JPG -> BitmapHelper.decodeBitmapFromByteArray(buffer)
        PluginImageFormat.PNG -> BitmapHelper.decodeBitmapFromPngByteArray(buffer)
    }

    override fun pluginToMap(): Map<String, *> = hashMapOf(
            "format" to format.format,
            "buffer" to buffer).apply {
        width?.let { this["width"] = it }
        height?.let { this["height"] = it }
    }
}