package io.storecamera.storecamera_photo.storecamera_plugin_camera.view

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.RectF
import android.hardware.display.DisplayManager
import android.util.AttributeSet
import android.util.DisplayMetrics
import android.util.Log
import android.util.TypedValue
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import io.storecamera.storecamera_photo.storecamera_plugin_camera.CameraViewFlutterListener
import io.storecamera.storecamera_photo.storecamera_plugin_camera.data.*
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/** CameraView */
class CameraView : FrameLayout {
    companion object {
        private const val ANIMATION_MILLIS = 100L
    }

    enum class Status {
        INIT,
        SETUP,
        BINDING,
        ERROR,
    }

    private var listener: CameraViewFlutterListener? = null

    var initPosition: CameraPosition = CameraPosition.FRONT

    private var displayId: Int = -1
    private var lensFacing: Int = CameraSelector.LENS_FACING_BACK
    private var preview: Preview? = null
    private var imageCapture: ImageCapture? = null
//    private var imageAnalyzer: ImageAnalysis? = null
    private var camera: Camera? = null
    private var cameraProvider: ProcessCameraProvider? = null

    private var cameraExecutor: ExecutorService

    private val displayManager = context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager

    private var cameraViewOrientation: CameraViewOrientation

    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayAdded(displayId: Int) = Unit
        override fun onDisplayRemoved(displayId: Int) = Unit
        override fun onDisplayChanged(displayId: Int) {
            if (displayId == this@CameraView.displayId) {
                Log.d("KKH", "Rotation changed: ${this@CameraView.display.rotation}")
                imageCapture?.targetRotation = this@CameraView.display.rotation
//                imageAnalyzer?.targetRotation = view.display.rotation
            }
        }
//        override fun onDisplayChanged(displayId: Int) = view?.let { view ->
//            if (displayId == this@CameraView.displayId) {
//                Log.d("KKH", "Rotation changed: ${view.display.rotation}")
//                imageCapture?.targetRotation = view.display.rotation
////                imageAnalyzer?.targetRotation = view.display.rotation
//            }
//        } ?: Unit
    }

    private var viewFinder: PreviewView = PreviewView(context).apply {
        implementationMode = PreviewView.ImplementationMode.COMPATIBLE
    }
    private var captureView: View = View(context).apply {
        setBackgroundColor(Color.WHITE)
        visibility = View.GONE
    }
    private var lifecycle: CameraViewLifecycle = CameraViewLifecycle()

    private var isResumed = false
    private var isLaunched = false
    private var status: Status = Status.INIT

    private var motion: CameraMotion = CameraMotion.OFF

    constructor(context: Context): this(context, null)

    constructor(context: Context, attrs: AttributeSet?): this(context, attrs, 0)

    constructor(context: Context, attrs: AttributeSet?, defStyleAttr: Int = 0): super(context, attrs, defStyleAttr)
    
    init {
        Log.i("KKH", "SelluryCameraView : init")
        cameraExecutor = Executors.newSingleThreadExecutor()

        // Every time the orientation of device changes, update rotation for use cases
        displayManager.registerDisplayListener(displayListener, null)
        cameraViewOrientation = object : CameraViewOrientation(context) {
            override fun onChangedOrientation(orientation: Int) {
                Log.i("KKH", "onChangedOrientation : $orientation")
            }
        }
        cameraViewOrientation.enable()

        addView(viewFinder, LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
        addView(captureView, LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
    }

    override fun onLayout(changed: Boolean, left: Int, top: Int, right: Int, bottom: Int) {
        super.onLayout(changed, left, top, right, bottom)
        Log.i("KKH", "SurfaceViewImpl changed $changed l: $left t: $top r: $right b: $bottom")
        if(this.status == Status.BINDING && changed) {
            preview?.setSurfaceProvider(viewFinder.surfaceProvider)
        }
    }

    @Suppress("SpellCheckingInspection")
    fun deinit() {
        Log.i("KKH", "SelluryCameraView : deinit lifecycle ${lifecycle.lifecycle.currentState}")
        cameraExecutor.shutdown()
        displayManager.unregisterDisplayListener(displayListener)
        cameraViewOrientation.disable()

        lifecycle.doOnDestroy()
    }

    fun setOnListener(listener: CameraViewFlutterListener?) {
        this.listener = listener
    }

    @SuppressLint("CheckResult")
    fun onResume() {
        Log.i("KKH", "SelluryCameraView : onResume lifecycle ${lifecycle.lifecycle.currentState}")
        isResumed = true
        if(!isLaunched) {
            isLaunched = true
            lifecycle.doOnResume()
            updateStatus(Status.SETUP)
        } else {
            lifecycle.doOnResume()
            if(this.status == Status.BINDING) {
                preview?.setSurfaceProvider(viewFinder.surfaceProvider)
            }
            if(motion == CameraMotion.ON) {
                implSetMotion(CameraMotion.ON)
            }
        }
    }

    fun onPause() {
        Log.i("KKH", "SelluryCameraView : onPause lifecycle ${lifecycle.lifecycle.currentState}")
        isResumed = false
        lifecycle.doOnPause()
        if(motion == CameraMotion.ON) {
            implSetMotion(CameraMotion.OFF)
        }
    }

    fun changeCamera(position: CameraPosition): CameraSetting? {
        if(status != Status.BINDING) {
            return null
        }
        val lensFacing: Int?  = cameraPositionToLensFacing(position)

        lensFacing?.let {
            if(this.lensFacing != it) {
                this.lensFacing = it
                return bindCameraUseCases()
            }
        }

        return null
    }

    fun capture(ratio: CameraRatio, resolution: CameraResolution, onSuccess: (byteArray: ByteArray) -> Unit, onError: (error: String) -> Unit) {
        if(status != Status.BINDING) {
            onError("Camera Status is not available, status: $status")
            return
        }

        imageCapture?.let { imageCapture ->
            val metadata = ImageCapture.Metadata().apply {
                isReversedHorizontal = lensFacing == CameraSelector.LENS_FACING_FRONT
            }
            val cameraViewCapture = CameraViewCapture(
                    ratio,
                    resolution,
                    onSuccess,
                    onError
            )
            val outputOptions = ImageCapture.OutputFileOptions.Builder(cameraViewCapture.outputStream)
                    .setMetadata(metadata)
                    .build()
            imageCapture.targetRotation = cameraViewOrientation.orientationToTargetRotation()
            imageCapture.flashMode = when(flash) {
                CameraFlash.OFF -> ImageCapture.FLASH_MODE_OFF
                CameraFlash.ON -> ImageCapture.FLASH_MODE_ON
                CameraFlash.AUTO -> ImageCapture.FLASH_MODE_AUTO
            }

            imageCapture.takePicture(
                    outputOptions,
                    cameraExecutor,
                    cameraViewCapture)

            captureView.animate().cancel()
            captureView.visibility = View.VISIBLE
            captureView.alpha = 0.0f
            captureView.animate()
                    .alpha(0.25f)
                    .withLayer()
                    .setDuration(ANIMATION_MILLIS)
                    .withEndAction {
                        Log.i("KKH", "captureView withEndAction")
                        captureView.visibility = View.GONE
                    }
                    .start()
        } ?: onError("ImageCapture is null")
    }

    fun setTorch(torch: CameraTorch): Boolean {
        when(torch) {
            CameraTorch.OFF -> {
                if (camera?.cameraInfo?.torchState?.value == TorchState.ON) {
                    camera?.cameraControl?.enableTorch(false)
                }
            }
            CameraTorch.ON -> {
                if (camera?.cameraInfo?.torchState?.value == TorchState.OFF) {
                    camera?.cameraControl?.enableTorch(true)
                }
            }
        }
        return true
    }

    private var flash: CameraFlash = CameraFlash.OFF
    fun setFlash(flash: CameraFlash): Boolean {
        this.flash = flash
        return true
    }

    fun setZoom(zoom: Float) {
        if(status != Status.BINDING) {
            return
        }
        camera?.cameraInfo?.zoomState?.value?.let {
            var newZoom: Float = zoom
            if(it.minZoomRatio < it.maxZoomRatio) {
                if (newZoom <= it.minZoomRatio) {
                    newZoom = it.minZoomRatio
                }
                if (newZoom >= it.maxZoomRatio) {
                    newZoom = it.maxZoomRatio
                }
                if (newZoom != it.zoomRatio) {
                    camera?.cameraControl?.setZoomRatio(newZoom)
                }
            }
        }                
    }


    @SuppressLint("UnsafeOptInUsageError")
    fun setExposure(exposure: Int) {
        if(status != Status.BINDING) {
            return
        }

        camera?.cameraInfo?.exposureState?.let {
            if(it.isExposureCompensationSupported) {
                camera?.cameraControl?.setExposureCompensationIndex(exposure)
            }
        }
    }

    fun setMotion(motion: CameraMotion) {
        this.motion = motion
        implSetMotion(this.motion)
        listener?.onCameraMotion(cameraViewOrientation.getMotionDegree() * Math.PI / 180)
    }

    private fun implSetMotion(motion: CameraMotion) {
        when(motion) {
            CameraMotion.OFF -> cameraViewOrientation.onChangedMotion = null
            CameraMotion.ON -> cameraViewOrientation.onChangedMotion = {
                Log.i("KKH", "implSetMotion $it")
                listener?.onCameraMotion(it * Math.PI / 180)
            }
        }
    }

    fun onTap(dx: Float, dy: Float) {
        if(status != Status.BINDING) {
            return
        }
        val dm: DisplayMetrics = context.resources.displayMetrics
        val dxPx = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, dx, dm)
        val dyPx = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, dy, dm)

        var rect = rotateRect(-(camera?.cameraInfo?.sensorRotationDegrees ?: 0), RectF(0.0f, 0.0f, viewFinder.width.toFloat(), viewFinder.height.toFloat()))
        rect = RectF(0.0f, 0.0f, rect.width(), rect.height())
        var point = rotatePoint(-(camera?.cameraInfo?.sensorRotationDegrees ?: 0), viewFinder.width.toFloat() / 2, viewFinder.height.toFloat() / 2, dxPx, dyPx)
        point = Pair(point.first - (viewFinder.width.toFloat() / 2 - rect.centerX()), point.second - (viewFinder.height.toFloat() / 2 - rect.centerY()))
        val factory: MeteringPointFactory = SurfaceOrientedMeteringPointFactory(
                rect.width(),
                rect.height()
        )
        val autoFocusPoint = factory.createPoint(point.first, point.second)
        focus(autoFocusPoint, false)
    }

    @Suppress("unused")
    private fun autoFocus() {
        val factory: MeteringPointFactory = SurfaceOrientedMeteringPointFactory(
                viewFinder.width.toFloat(), viewFinder.height.toFloat()
        )
        val autoFocusPoint = factory.createPoint(viewFinder.width.toFloat() / 2, viewFinder.height.toFloat() / 2)
        focus(autoFocusPoint)
    }

    private fun focus(point: MeteringPoint, autoCancel: Boolean = true) {
        camera?.cameraControl?.startFocusAndMetering(
                FocusMeteringAction.Builder(point, FocusMeteringAction.FLAG_AF)
                        .addPoint(point, FocusMeteringAction.FLAG_AE).apply {
                            if (!autoCancel) {
                                disableAutoCancel()
                            }
                        }.build()
        )
    }

    private fun rotatePoint(degrees: Int, centerX: Float, centerY: Float, x: Float, y: Float): Pair<Float, Float> {
        if(degrees % 360 == 0) {
            return Pair(x, y)
        }

        val transform = Matrix().apply {
            setRotate(degrees.toFloat(), centerX, centerY)
        }
        val pts = floatArrayOf(x, y)
        transform.mapPoints(pts)
        return Pair(pts[0], pts[1])
    }

    private fun rotateRect(degrees: Int, rect: RectF): RectF {
        if(degrees % 360 == 0) {
            return rect
        }

        val transform = Matrix().apply {
            setRotate(degrees.toFloat(), rect.centerX(), rect.centerY())
        }
        transform.mapRect(rect)
        return rect
    }

    private fun updateStatus(status: Status) {
        when(status) {
            Status.INIT -> {
            }
            Status.SETUP -> {
                if (this.status == Status.INIT) {
                    this.status = Status.SETUP
                    setUpCamera()
                }
            }
            Status.BINDING -> {
                if (this.status == Status.SETUP) {
                    this.status = Status.BINDING
                    bindCameraUseCases()?.let {
                        val availablePosition = mutableListOf<String>()
                        if (hasBackCamera()) {
                            availablePosition.add(CameraPosition.BACK.value)
                        }
                        if (hasFrontCamera()) {
                            availablePosition.add(CameraPosition.FRONT.value)
                        }
                        listener?.onCameraStatus(CameraStatusBinding(
                                availablePosition,
                                it
                        ))
                    } ?: updateStatus(Status.ERROR)
                }
            }
            Status.ERROR -> {
                this.status = Status.ERROR
                listener?.onCameraStatus(CameraStatusError())
            }
        }
    }

    private fun setUpCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
        cameraProviderFuture.addListener({
            cameraProvider = cameraProviderFuture.get()
            val lensFacing: Int? = cameraPositionToLensFacing(initPosition)

            lensFacing?.let {
                this.lensFacing = it
                updateStatus(Status.BINDING)
            } ?: updateStatus(Status.ERROR)
        }, ContextCompat.getMainExecutor(context))
        
    }

    /** Declare and bind preview, capture and analysis use cases */
    private fun bindCameraUseCases(): CameraSetting? {
        // Get screen metrics used to setup camera for full screen resolution
        val screenAspectRatio = AspectRatio.RATIO_4_3

        val rotation = viewFinder.display?.rotation ?: 0

        // CameraProvider
        val cameraProvider = cameraProvider
                ?: throw IllegalStateException("Camera initialization failed.")

        // CameraSelector
        val cameraSelector = CameraSelector.Builder().requireLensFacing(lensFacing).build()

        // Preview
        preview = Preview.Builder()
                // We request aspect ratio but no resolution
                .setTargetAspectRatio(screenAspectRatio)
                // Set initial target rotation
                .setTargetRotation(rotation)
                .build()

        // ImageCapture
        imageCapture = ImageCapture.Builder()
                .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
                // We request aspect ratio but no resolution to match preview config, but letting
                // CameraX optimize for whatever specific resolution best fits our use cases
                .setTargetAspectRatio(screenAspectRatio)
                // Set initial target rotation, we will have to call this again if rotation changes
                // during the lifecycle of this use case
                .setTargetRotation(rotation)
                .build()

        // ImageAnalysis
//        imageAnalyzer = ImageAnalysis.Builder()
//                // We request aspect ratio but no resolution
//                .setTargetAspectRatio(screenAspectRatio)
//                // Set initial target rotation, we will have to call this again if rotation changes
//                // during the lifecycle of this use case
//                .setTargetRotation(rotation)
//                .build()
//                // The analyzer can then be assigned to the instance
//                .also {
//                    it.setAnalyzer(cameraExecutor, LuminosityAnalyzer { luma ->
//                        // Values returned from our analyzer are passed to the attached listener
//                        // We log image analysis results here - you should do something useful
//                        // instead!
//                        Log.d(TAG, "Average luminosity: $luma")
//                    })
//                }

        // Must unbind the use-cases before rebinding them
        cameraProvider.unbindAll()

        try {
            // A variable number of use-cases can be passed here -
            // camera provides access to CameraControl & CameraInfo
            camera = cameraProvider.bindToLifecycle(
                    lifecycle, cameraSelector, preview, imageCapture)
//            camera?.cameraControl?.setExposureCompensationIndex()
            // Attach the viewfinder's surface provider to preview use case
            preview?.setSurfaceProvider(viewFinder.surfaceProvider)

            val currentPosition = if(lensFacing == CameraSelector.LENS_FACING_BACK) CameraPosition.BACK else CameraPosition.FRONT
            return CameraSetting(
                    currentPosition,
                    camera?.cameraInfo?.hasFlashUnit() ?: false,
                    camera?.cameraInfo?.zoomState?.value?.minZoomRatio?.toDouble() ?: 1.0,
                    camera?.cameraInfo?.zoomState?.value?.maxZoomRatio?.toDouble() ?: 1.0,
            )
        } catch (exc: Exception) {
            Log.e("KKH", "Use case binding failed", exc)
        }
        return null
    }

    /** Returns true if the device has an available back camera. False otherwise */
    private fun hasBackCamera(): Boolean {
        return cameraProvider?.hasCamera(CameraSelector.DEFAULT_BACK_CAMERA) ?: false
    }

    /** Returns true if the device has an available front camera. False otherwise */
    private fun hasFrontCamera(): Boolean {
        return cameraProvider?.hasCamera(CameraSelector.DEFAULT_FRONT_CAMERA) ?: false
    }

    private fun cameraPositionToLensFacing(cameraPosition: CameraPosition): Int? = when (cameraPosition) {
        CameraPosition.BACK -> when {
            hasBackCamera() -> CameraSelector.LENS_FACING_BACK
            hasFrontCamera() -> CameraSelector.LENS_FACING_FRONT
            else -> null
        }
        CameraPosition.FRONT -> when {
            hasFrontCamera() -> CameraSelector.LENS_FACING_FRONT
            hasBackCamera() -> CameraSelector.LENS_FACING_BACK
            else -> null
        }
    }
}
