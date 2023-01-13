package io.storecamera.storecamera_photo.storecamera_plugin_camera.view

import android.content.Context
import android.hardware.SensorManager
import android.view.OrientationEventListener
import android.view.Surface
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry

/** CameraViewOrientation */
abstract class CameraViewOrientation(context: Context) : OrientationEventListener(context, SensorManager.SENSOR_DELAY_UI) {

    companion object {
        private const val ORIENTATION_0 = 0
        private const val ORIENTATION_90 = 90
        private const val ORIENTATION_180 = 180
        private const val ORIENTATION_270 = 270
    }
    private var orientation = ORIENTATION_0
    private var motionDegree: Int = 0
    var onChangedMotion: ((Int) -> Unit)? = null

    override fun onOrientationChanged(orientation: Int) {
        if ((orientation >= 355 || (orientation in 0..4)) && this.orientation != ORIENTATION_0) {
            this.orientation = ORIENTATION_0
            onChangedOrientation(this.orientation)
        } else if (orientation in 85..95 && this.orientation != ORIENTATION_90) {
            this.orientation = ORIENTATION_90
            onChangedOrientation(this.orientation)
        } else if (orientation in 175..185 && this.orientation != ORIENTATION_180) {
            this.orientation = ORIENTATION_180
            onChangedOrientation(this.orientation)
        } else if (orientation in 265..275 && this.orientation != ORIENTATION_270) {
            this.orientation = ORIENTATION_270
            onChangedOrientation(this.orientation)
        }
        motionDegree = orientation
        onChangedMotion?.let {
            it(orientation)
        }
    }

    abstract fun onChangedOrientation(orientation: Int)

    fun orientationToTargetRotation(): Int = when(orientation) {
        90 -> Surface.ROTATION_270
        180 -> Surface.ROTATION_180
        270 -> Surface.ROTATION_90
        else -> Surface.ROTATION_0
    }

    fun getMotionDegree() = motionDegree
}

