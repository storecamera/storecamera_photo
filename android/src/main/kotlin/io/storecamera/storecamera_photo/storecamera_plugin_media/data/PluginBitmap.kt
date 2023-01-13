package io.storecamera.storecamera_photo.storecamera_plugin_media.data

import android.graphics.Bitmap
import android.graphics.Canvas
import androidx.core.graphics.BitmapCompat
import java.nio.ByteBuffer

data class PluginBitmap(
        val width: Int,
        val height: Int,
        val buffer: ByteBuffer
) : PluginToMap {
    override fun pluginToMap(): Map<String, *> = hashMapOf(
            "width" to width,
            "height" to height,
            "buffer" to buffer.array()
    )

    companion object {
        @Suppress("MemberVisibilityCanBePrivate")
        fun create(bitmap: Bitmap): PluginBitmap {
            val byteCount = BitmapCompat.getAllocationByteCount(bitmap)
            val buffer: ByteBuffer = ByteBuffer.allocate(byteCount)
            bitmap.copyPixelsToBuffer(buffer)

            return PluginBitmap(
                    bitmap.width,
                    bitmap.height,
                    buffer)
        }

        fun createARGB(bitmap: Bitmap): PluginBitmap {
            val pluginBitmap: PluginBitmap

            if(bitmap.config == Bitmap.Config.ARGB_8888) {
                pluginBitmap = create(bitmap)
            } else {
                val src = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(src)
                canvas.drawBitmap(
                        bitmap,
                        0f,
                        0f,
                        null
                )
                pluginBitmap = create(src)
                src.recycle()
            }
            return pluginBitmap
        }
    }
}