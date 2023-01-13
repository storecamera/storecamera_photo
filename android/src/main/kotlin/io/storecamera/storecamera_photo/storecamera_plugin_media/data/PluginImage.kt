package io.storecamera.storecamera_photo.storecamera_plugin_media.data

data class PluginImage(
        val id: Long,
        val fullPath: String,
        val displayName: String,
        val mimeType: String?,
        val width: Int,
        val height: Int,
        val modifyTimeMs: Long
) : PluginToMap {
    override fun pluginToMap(): Map<String, *> = hashMapOf(
            "id" to id,
            "width" to width,
            "height" to height,
            "modifyTimeMs" to modifyTimeMs,
            "info" to hashMapOf(
                    "fullPath" to fullPath,
                    "displayName" to displayName,
                    "mimeType" to mimeType
            )
    )
}