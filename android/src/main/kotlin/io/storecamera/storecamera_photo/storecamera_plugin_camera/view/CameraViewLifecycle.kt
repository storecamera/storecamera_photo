package io.storecamera.storecamera_photo.storecamera_plugin_camera.view

import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry

/** CameraViewLifecycle */
class CameraViewLifecycle : LifecycleOwner {
    private val lifecycleRegistry: LifecycleRegistry = LifecycleRegistry(this)

    init {
        lifecycleRegistry.currentState = Lifecycle.State.CREATED
    }

    fun doOnResume() {
        lifecycleRegistry.currentState = Lifecycle.State.STARTED
        lifecycleRegistry.currentState = Lifecycle.State.RESUMED
    }

    fun doOnPause() {
        lifecycleRegistry.currentState = Lifecycle.State.CREATED
    }

    fun doOnDestroy() {
        lifecycleRegistry.currentState = Lifecycle.State.DESTROYED
    }

    override fun getLifecycle(): Lifecycle {
        return lifecycleRegistry
    }
}

