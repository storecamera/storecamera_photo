package io.storecamera.storecamera_photo.storecamera_plugin_media.media_query

import android.Manifest
import android.annotation.TargetApi
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.hardware.Camera
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import android.webkit.MimeTypeMap
import androidx.exifinterface.media.ExifInterface
import io.reactivex.Observable
import io.reactivex.android.schedulers.AndroidSchedulers
import io.reactivex.schedulers.Schedulers
import io.storecamera.storecamera_photo.storecamera_plugin_media.PluginPermission
import io.storecamera.storecamera_photo.storecamera_plugin_media.data.*
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStream

@TargetApi(Build.VERSION_CODES.LOLLIPOP)
class PluginImageQueryM: PluginImageQuery() {
    private var images = mutableListOf<Image>()
    private var sortOrder = PluginSortOrder.DATE_DESC
    private var thumbnailOrientationStatus = ThumbnailOrientationStatus.UNDEFINED

    private var packageName = "com.zpdl_studio.zpdl_studio_media_plugin"
    private val thumbnailOrientationStatusKey = "thumbnailOrientationStatus"

    override fun init(context: Context) {
        super.init(context)
        packageName = context.packageName
        thumbnailOrientationStatus = ThumbnailOrientationStatus.from(
                context.getSharedPreferences(packageName, Context.MODE_PRIVATE).getString(thumbnailOrientationStatusKey, null) ?: ""
        )
    }

    @Synchronized private fun setImages(images: MutableList<Image>, sortOrder: PluginSortOrder) {
        this.images = images
        this.sortOrder = sortOrder
    }

    @Synchronized private fun getImages(): Pair<MutableList<Image>, PluginSortOrder> = Pair(images, sortOrder)

    override fun getImageFolder(sortOrder: PluginSortOrder): MutableList<PluginFolder> {
        @Suppress("DEPRECATION") val cursor = context?.contentResolver?.query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                arrayOf(
                        MediaStore.Images.Media._ID,
                        MediaStore.Images.Media.DISPLAY_NAME,
                        MediaStore.Images.Media.DATA,
                        MediaStore.Images.Media.MIME_TYPE,
                        MediaStore.Images.Media.WIDTH,
                        MediaStore.Images.Media.HEIGHT,
                        MediaStore.Images.Media.DATE_MODIFIED
                ),
                null,
                null,
                sortOrderQuery(sortOrder, 10000))

        val folderMap = mutableMapOf<String, Folder>()
        val folders = mutableListOf<Folder>()
        val images = mutableListOf<Image>()

        cursor?.let { _cursor ->
            val columnIndexID = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
            val columnIndexName = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DISPLAY_NAME)
            @Suppress("DEPRECATION") val columnIndexData = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA)
            val columnIndexMimeType = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.MIME_TYPE)
            val columnIndexWidth = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.WIDTH)
            val columnIndexHeight = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.HEIGHT)
            val columnIndexDateModified = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_MODIFIED)

            while (_cursor.moveToNext()) {
                val data = cursor.getString(columnIndexData)
                if(data != null && data.isNotEmpty()) {
                    val bucketId = File(data).parent ?: ""
                    val mimeType: String? = cursor.getString(columnIndexMimeType)
                    val modifyTimeMs = cursor.getLong(columnIndexDateModified) * 1000L

                    val folder = folderMap[bucketId]
                    if(folder == null) {
                        val folderData = Folder(bucketId, 1, modifyTimeMs)
                        folderMap[bucketId] = folderData
                        folders.add(folderData)
                    } else {
                        folder.count++
                    }

                    images.add(Image(
                            bucketId = bucketId,
                            id = cursor.getLong(columnIndexID),
                            displayName = cursor.getString(columnIndexName) ?: "",
                            data = data,
                            mimeType = mimeType,
                            width = cursor.getInt(columnIndexWidth),
                            height = cursor.getInt(columnIndexHeight),
                            modifyTimeMs = modifyTimeMs
                    ))
                }
            }
        }
        cursor?.close()

        setImages(images, sortOrder)

        return folders.map {
            PluginFolder(
                    it.bucketId,
                    File(it.bucketId).name,
                    it.count,
                    it.modifyTimeMs
            )
        }.toMutableList()
    }

    override fun getImages(bucketId: String?, sortOrder: PluginSortOrder, offset: Int?, limit: Int?): PluginDataSet<PluginImage> {
        val imagesDataSet = getImages()
        val images = mutableListOf<Image>().apply {
            addAll(imagesDataSet.first)
        }

        if(sortOrder != imagesDataSet.second) {
            when(sortOrder) {
                PluginSortOrder.DATE_DESC -> images.sortByDescending { it.modifyTimeMs }
                PluginSortOrder.DATE_ARC -> images.sortBy { it.modifyTimeMs }
            }
        }

        val results = mutableListOf<PluginImage>()
        var foundCount = 0
        var count = 0
        if (bucketId != null && bucketId.isNotEmpty()) {
            for(image in images.filter { it.bucketId == bucketId }) {
                if(limit?.let { it <= foundCount } == true) {
                    break
                }
                if(offset == null || offset <= count) {
                    results.add(PluginImage(
                            id = image.id,
                            fullPath = image.data,
                            displayName = image.displayName,
                            mimeType = image.displayName,
                            width = image.width,
                            height = image.height,
                            modifyTimeMs = image.modifyTimeMs
                    ))
                    foundCount++
                }
                count++
            }
        } else {
            for(image in images) {
                if(limit?.let { it <= foundCount } == true) {
                    break
                }
                if(offset == null || offset <= count) {
                    results.add(PluginImage(
                            id = image.id,
                            fullPath = image.data,
                            displayName = image.displayName,
                            mimeType = image.displayName,
                            width = image.width,
                            height = image.height,
                            modifyTimeMs = image.modifyTimeMs
                    ))
                    foundCount++
                }
                count++
            }
        }

        return PluginDataSet(list = results)
    }

    override fun getImage(id: Long): PluginImage? {
        @Suppress("DEPRECATION") val cursor = context?.contentResolver?.query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                arrayOf(
                        MediaStore.Images.Media._ID,
                        MediaStore.Images.Media.DISPLAY_NAME,
                        MediaStore.Images.Media.DATA,
                        MediaStore.Images.Media.MIME_TYPE,
                        MediaStore.Images.Media.WIDTH,
                        MediaStore.Images.Media.HEIGHT,
                        MediaStore.Images.Media.DATE_MODIFIED
                ),
                "${MediaStore.Images.Media._ID} = ?",
                arrayOf(id.toString()),
                null)
        
        var image: Image? = null
        cursor?.let { _cursor ->
            val columnIndexID = _cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
            val columnIndexName = _cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DISPLAY_NAME)
            @Suppress("DEPRECATION") val columnIndexData = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA)
            val columnIndexMimeType = _cursor.getColumnIndexOrThrow(MediaStore.Images.Media.MIME_TYPE)
            val columnIndexWidth = _cursor.getColumnIndexOrThrow(MediaStore.Images.Media.WIDTH)
            val columnIndexHeight = _cursor.getColumnIndexOrThrow(MediaStore.Images.Media.HEIGHT)
            val columnIndexDateModified = _cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_MODIFIED)

            if (_cursor.moveToNext()) {
                val data = cursor.getString(columnIndexData)
                if (data != null && data.isNotEmpty()) {
                    val bucketId = File(data).parent ?: ""
                    val mimeType: String? = cursor.getString(columnIndexMimeType)
                    val modifyTimeMs = cursor.getLong(columnIndexDateModified) * 1000L

                    image = Image(
                            bucketId = bucketId,
                            id = cursor.getLong(columnIndexID),
                            displayName = cursor.getString(columnIndexName) ?: "",
                            data = data,
                            mimeType = mimeType,
                            width = cursor.getInt(columnIndexWidth),
                            height = cursor.getInt(columnIndexHeight),
                            modifyTimeMs = modifyTimeMs
                    )
                }
            }
        }
        cursor?.close()

        return image?.let {
            PluginImage(
                    id = it.id,
                    fullPath = it.data,
                    displayName = it.displayName,
                    mimeType = it.mimeType,
                    width = it.width,
                    height = it.height,
                    modifyTimeMs = it.modifyTimeMs
            )
        }
    }

    override fun getImageFolderCount(bucketId: String?): Int {
        val images = getImages().first

        return if (bucketId != null && bucketId.isNotEmpty()) {
            images.filter { it.bucketId == bucketId }.size
        } else {
            images.size
        }
    }

    override fun getImageThumbnail(id: Long, width: Int, height: Int): Bitmap? {
        return context?.contentResolver?.let {
            // MINI_KIND: 512 x 384 thumbnail
            // MICRO_KIND: 96 x 96 thumbnail
            @Suppress("DEPRECATION")
            val bitmap: Bitmap? = MediaStore.Images.Thumbnails.getThumbnail(
                    it,
                    id,
                    if(width > 96 || height > 96) MediaStore.Images.Thumbnails.MINI_KIND else MediaStore.Images.Thumbnails.MICRO_KIND,
                    null)
            return when(thumbnailOrientationStatus) {
                ThumbnailOrientationStatus.UNDEFINED -> bitmap?.let { _bitmap ->
                    getInternalImage(id)?.let { image ->
                        getUndefinedImageThumbnail(image, _bitmap)
                    } ?: _bitmap
                }
                ThumbnailOrientationStatus.ORIGINAL -> bitmap
                ThumbnailOrientationStatus.ORIENTATION -> bitmap?.let { _bitmap ->
                    getInternalImage(id)?.let { image ->
                        rotateBitmap(_bitmap, getImageOrientation(image))
                    } ?: _bitmap
                }
            }
        }
    }

    override fun addImage(pluginPermission: PluginPermission, byteArray: ByteArray, folder: String, name: String, result: (Boolean) -> Unit) {
        @Suppress("UNUSED_VARIABLE") val disposable = pluginPermission.requestPermissionsObservable(mutableListOf(Manifest.permission.WRITE_EXTERNAL_STORAGE)).flatMap {
            if (it) {
                Observable.fromCallable {
                    addImage(byteArray, folder, name)
                }.subscribeOn(Schedulers.io())
            } else {
                Observable.just(null)
            }
        }
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe({ pair ->
                    @Suppress("DEPRECATION") val results: Boolean = pair?.let {
                        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
                            context?.sendBroadcast(
                                    Intent(Camera.ACTION_NEW_PICTURE, Uri.fromFile(it.first))
                            )
                        }

                        MediaScannerConnection.scanFile(
                                context,
                                arrayOf(it.first.absolutePath),
                                arrayOf(it.second)
                        ) { _, uri ->
                            Log.d("KKH", "Image capture scanned into media store: $uri")
                        }
                        true
                    } ?: false
                    result(results)
                }, {
                    result(false)
                })
    }

    override fun addImage(pluginPermission: PluginPermission, bitmap: Bitmap, format: PluginImageFormat, folder: String, name: String, result: (Boolean) -> Unit) {
        @Suppress("UNUSED_VARIABLE") val disposable = pluginPermission.requestPermissionsObservable(mutableListOf(Manifest.permission.WRITE_EXTERNAL_STORAGE)).flatMap {
            if (it) {
                Observable.fromCallable {
                    addImage(bitmap, format, folder, name)
                }.subscribeOn(Schedulers.io())
            } else {
                Observable.just(null)
            }
        }
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe({ pair ->
                    @Suppress("DEPRECATION") val results: Boolean = pair?.let {
                        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
                            context?.sendBroadcast(
                                    Intent(Camera.ACTION_NEW_PICTURE, Uri.fromFile(it.first))
                            )
                        }

                        MediaScannerConnection.scanFile(
                                context,
                                arrayOf(it.first.absolutePath),
                                arrayOf(it.second)
                        ) { _, uri ->
                            Log.d("KKH", "Image capture scanned into media store: $uri")
                        }
                        true
                    } ?: false
                    result(results)
                }, {
                    result(false)
                })
    }

    override fun deleteImage(pluginPermission: PluginPermission, ids: Array<Long>): Observable<MutableList<Long>> {
        return pluginPermission.requestPermissionsObservable(mutableListOf(Manifest.permission.WRITE_EXTERNAL_STORAGE)).flatMap {
            if (it) {
                Observable.fromCallable {
                    val results = mutableListOf<Long>()
                    for(id in ids) {
                        try {
                            this.context?.contentResolver?.delete(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, MediaStore.Images.ImageColumns._ID + "=?", arrayOf(id.toString()))
                            results.add(id)
                        } catch (e: Exception) {}
                    }
                    results
                }
            } else {
                Observable.just(mutableListOf())
            }
        }
    }

    private fun addImage(bitmap: Bitmap, format: PluginImageFormat, folder: String, name: String): Pair<File, String>? {
        @Suppress("DEPRECATION") val directory = if (folder.isNotEmpty())
            File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM), folder)
        else
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM)
        if (!directory.exists()) {
            if (!directory.mkdir()) {
                Log.w("error", "Failed to create output Pictures directory")
                return null
            }
        }

        val mimeType = format.getMimeType() ?: return null
        val file = File(directory, "$name.${MimeTypeMap.getSingleton().getExtensionFromMimeType(mimeType)}")
        if (file.exists()) {
            file.delete()
        }
        file.createNewFile()
        var imageOutStream: OutputStream? = null
        try {
            imageOutStream = FileOutputStream(file)
            when(format) {
                PluginImageFormat.BITMAP -> {}
                PluginImageFormat.JPG -> bitmap.compress(Bitmap.CompressFormat.JPEG, 100, imageOutStream)
                PluginImageFormat.PNG -> bitmap.compress(Bitmap.CompressFormat.PNG, 100, imageOutStream)
            }
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        } finally {
            imageOutStream?.close()
        }
        return Pair(file, mimeType)
    }

    private fun addImage(byteArray: ByteArray, folder: String, name: String): Pair<File, String>? {
        @Suppress("DEPRECATION") val directory = if (folder.isNotEmpty())
            File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM), folder)
        else
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM)
        if (!directory.exists()) {
            if (!directory.mkdir()) {
                Log.w("error", "Failed to create output Pictures directory")
                return null
            }
        }
        val options: BitmapFactory.Options = getBitmapFactoryOption(byteArray) ?: return null
        val file = File(directory, "$name.${MimeTypeMap.getSingleton().getExtensionFromMimeType(options.outMimeType)}")
        if (file.exists()) {
            file.delete()
        }
        file.createNewFile()
        var imageOutStream: OutputStream? = null
        try {
            imageOutStream = FileOutputStream(file)
            imageOutStream.write(byteArray)
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        } finally {
            imageOutStream?.close()
        }

        return Pair(file, options.outMimeType)
    }

//    override fun getImageInfo(id: Long): PluginImageInfo? =
//            getImage(id)?.let {
//                PluginImageInfo(
//                        id = it.id,
//                        path = it.data,
//                        displayName = it.displayName,
//                        mimeType = it.mimeType,
//                        orientation = getImageOrientation(it),
//                        width = it.width,
//                        height = it.height,
//                        modifyTimeMs = it.modifyTimeMs
//                )
//            }
    
    private fun sortOrderQuery(sortOrder: PluginSortOrder?, @Suppress("SameParameterValue") limit: Int?): String {
        val sb = StringBuilder()
        sortOrder?.let {
            sb.append(when (it) {
                PluginSortOrder.DATE_DESC -> "${MediaStore.MediaColumns.DATE_MODIFIED} DESC"
                PluginSortOrder.DATE_ARC -> "${MediaStore.MediaColumns.DATE_MODIFIED} ASC"
            })
        }

        limit?.let {
            if(sb.isNotEmpty()) {
                sb.append(" ")
            }
            sb.append("LIMIT $it")
        }

        return sb.toString()
    }

//    private fun getBucketId(path: String): String {
//        val index: Int = path.lastIndexOf(File.separatorChar)
//        return if(index > 0) path.substring(0, index) else ""
//    }
//
//    private fun getBucketName(bucketId: String): String {
//        val index: Int = bucketId.lastIndexOf(File.separatorChar)
//        return bucketId.substring(index + 1)
//    }

    private fun getInternalImage(id: Long): Image? = images.firstOrNull { it.id == id }

    private fun getImageOrientation(image: Image): Int {
        image.orientation?.let { return it }

        var orientation = 0
        if (image.mimeType == "image/jpeg") {
            try {
                val exifInterface = ExifInterface(image.data)
                orientation = when (exifInterface.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_UNDEFINED)) {
                    ExifInterface.ORIENTATION_ROTATE_90 -> 90
                    ExifInterface.ORIENTATION_ROTATE_180 -> 180
                    ExifInterface.ORIENTATION_ROTATE_270 -> 270
                    else -> 0
                }
            } catch (e: Exception) {
            }
        }

        image.orientation = orientation
        return orientation
    }

    private fun getUndefinedImageThumbnail(image: Image, bitmap: Bitmap): Bitmap {
        return when(val orientation = getImageOrientation(image)) {
            90, 270 -> {
                when {
                    image.width == image.height -> bitmap
                    kotlin.math.abs(image.height / bitmap.width - image.width / bitmap.height) > 0.0001 -> {
                        thumbnailOrientationStatus = ThumbnailOrientationStatus.ORIENTATION
                        context?.getSharedPreferences(packageName, Context.MODE_PRIVATE)?.edit()?.let {
                            it.putString(thumbnailOrientationStatusKey, ThumbnailOrientationStatus.ORIENTATION.value)
                            it.apply()
                        }

                        rotateBitmap(bitmap, orientation)
                    }
                    else -> {
                        thumbnailOrientationStatus = ThumbnailOrientationStatus.ORIGINAL
                        context?.getSharedPreferences(packageName, Context.MODE_PRIVATE)?.edit()?.let {
                            it.putString(thumbnailOrientationStatusKey, ThumbnailOrientationStatus.ORIGINAL.value)
                            it.apply()
                        }
                        bitmap
                    }
                }
            }
            else -> bitmap
        }
    }

    private fun rotateBitmap(bitmap: Bitmap, orientation: Int): Bitmap {
        val matrix = when (orientation) {
            90 -> Matrix().apply { postRotate(90f) }
            180 -> Matrix().apply { postRotate(180f) }
            270 -> Matrix().apply { postRotate(270f) }
            else -> null
        }

        return matrix?.let {
            val result = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
            if(bitmap != result) {
                bitmap.recycle()
            }
            return result
        } ?: bitmap
    }
}

data class Folder(
        val bucketId: String,
        var count: Int,
        val modifyTimeMs: Long
)

data class Image(
        val bucketId: String,
        val id: Long,
        val displayName: String,
        val data: String,
        val mimeType: String?,
        var orientation: Int? = null,
        val width: Int,
        val height: Int,
        val modifyTimeMs: Long
)

enum class ThumbnailOrientationStatus(val value: String) {
    UNDEFINED(""),
    ORIGINAL("original"),
    ORIENTATION("orientation");

    companion object {
        fun from(value: String): ThumbnailOrientationStatus {
            for (_value in values()) {
                if (_value.value == value) {
                    return _value
                }
            }
            return UNDEFINED
        }
    }
}

