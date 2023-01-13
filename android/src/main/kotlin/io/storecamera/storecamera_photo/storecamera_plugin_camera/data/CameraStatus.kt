package io.storecamera.storecamera_photo.storecamera_plugin_camera.data

interface CameraStatus: PluginToMap {
    val type: CameraStatusType
}

enum class CameraStatusType(val value: String) {
    BINDING("BINDING"),
    ERROR("ERROR"),
}

class CameraStatusBinding(
        private val availablePosition: MutableList<String>,
        private val setting: CameraSetting): CameraStatus {
    override val type: CameraStatusType
        get() = CameraStatusType.BINDING
    
    override fun pluginToMap(): Map<String, *> = hashMapOf(
            "type" to type.value,
            "availablePosition" to availablePosition,
            "availableMotion" to true,
            "setting" to setting.pluginToMap()
    )
}

class CameraStatusError: CameraStatus {
    override val type: CameraStatusType
        get() = CameraStatusType.ERROR

    override fun pluginToMap(): Map<String, *> = hashMapOf(
            "type" to type.value
    )
}