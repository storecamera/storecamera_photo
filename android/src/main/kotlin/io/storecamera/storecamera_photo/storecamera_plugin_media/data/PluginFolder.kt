package io.storecamera.storecamera_photo.storecamera_plugin_media.data

data class PluginFolder(
    val id: String,
    val displayName: String,
    val count: Int,
    val modifyTimeMs: Long
) : PluginToMap {
    override fun pluginToMap(): Map<String, *> = hashMapOf(
            "id" to id,
            "displayName" to displayName,
            "count" to count,
            "modifyTimeMs" to modifyTimeMs
    )
}