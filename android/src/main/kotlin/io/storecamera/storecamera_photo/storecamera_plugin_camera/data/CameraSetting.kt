package io.storecamera.storecamera_photo.storecamera_plugin_camera.data

data class CameraSetting(
        val currentPosition: CameraPosition,
        val hasFlashUnit: Boolean,
        val minZoom: Double,
        val maxZoom: Double
) : PluginToMap {

    override fun pluginToMap(): Map<String, *> {
        val hasFlashUnit: Boolean = if(currentPosition == CameraPosition.BACK) this.hasFlashUnit else false

        return hashMapOf(
                "currentPosition" to currentPosition.value,
                "isTorchAvailable" to hasFlashUnit,
                "isFlashAvailable" to hasFlashUnit,
                "minZoom" to minZoom,
                "maxZoom" to maxZoom,
                "isExposureAvailable" to false,
                "minExposure" to 0.0,
                "maxExposure" to 0.0,
                "currentExposure" to 0.0,
        )
    }
}

enum class CameraPosition(val value: String) {
    BACK("BACK"),
    FRONT("FRONT");

    companion object {
        fun from(value: String?): CameraPosition? {
            for(_value in values()) {
                if(_value.value == value) {
                    return _value
                }
            }
            return null
        }
    }
}

enum class CameraRatio(val value: String) {
    RATIO_1_1("1:1"),
    RATIO_4_5("4:5"),
    RATIO_3_4("3:4"),
    RATIO_9_16("9:16");

    companion object {
        fun from(value: String?): CameraRatio? {
            for(_value in values()) {
                if(_value.value == value) {
                    return _value
                }
            }
            return null
        }
    }
}

enum class CameraResolution(val value: String) {
    FULL("FULL"),
    STANDARD("STANDARD"),
    LOW("LOW");

    companion object {
        fun from(value: String?): CameraResolution? {
            for(_value in values()) {
                if(_value.value == value) {
                    return _value
                }
            }
            return null
        }
    }
}

enum class CameraFlash(val value: String) {
    OFF("OFF"),
    ON("ON"),
    AUTO("AUTO");

    companion object {
        fun from(value: String?): CameraFlash? {
            for(_value in values()) {
                if(_value.value == value) {
                    return _value
                }
            }
            return null
        }
    }
}

enum class CameraTorch(val value: String) {
    OFF("OFF"),
    ON("ON");

    companion object {
        fun from(value: String?): CameraTorch? {
            for(_value in values()) {
                if(_value.value == value) {
                    return _value
                }
            }
            return null
        }
    }
}

enum class CameraMotion(val value: String) {
    OFF("OFF"),
    ON("ON");

    companion object {
        fun from(value: String?): CameraMotion? {
            for(_value in values()) {
                if(_value.value == value) {
                    return _value
                }
            }
            return null
        }
    }
}
