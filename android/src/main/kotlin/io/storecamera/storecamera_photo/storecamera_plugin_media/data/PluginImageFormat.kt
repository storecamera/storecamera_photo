package io.storecamera.storecamera_photo.storecamera_plugin_media.data

enum class PluginImageFormat(val format: String) {
    BITMAP("BITMAP"),
    JPG("JPG"),
    PNG("PNG"),
    ;

    companion object {
        fun from(format: String?): PluginImageFormat? {
            format?.let {
                for(value in values()) {
                    if(value.format == it) {
                        return value
                    }
                }
            }
            return null
        }
    }
    
    fun getExtension(): String? = when(this) {
        BITMAP -> null
        JPG -> "jpg"
        PNG -> "png"
    }
    
    fun getMimeType(): String? = when(this) {
        BITMAP -> null
        JPG -> "image/jpeg"
        PNG -> "image/png"
    }
}