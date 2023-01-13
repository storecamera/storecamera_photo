package io.storecamera.storecamera_photo.storecamera_plugin_media.media_query

import android.Manifest
import android.app.Activity
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.database.ContentObserver
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import io.reactivex.Observable
import io.reactivex.schedulers.Schedulers
import io.storecamera.storecamera_photo.storecamera_plugin_media.PluginPermission
//import io.storecamera.storecamera_photo.storecamera_plugin_media.StoreCameraPluginMediaPlugin
import io.storecamera.storecamera_photo.storecamera_plugin_media.data.*
import java.io.ByteArrayInputStream
import java.io.InputStream
import java.util.ArrayList

abstract class PluginImageQuery {

    private val readPermission: MutableList<String> =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) mutableListOf(Manifest.permission.READ_MEDIA_IMAGES) else mutableListOf(
            Manifest.permission.READ_EXTERNAL_STORAGE
        )

    protected var context: Context? = null
    private var contentObserver: ContentObserver? = null
    private var modifyTimeMs: Long = 0L

//    protected val permissions = mutableListOf(Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE)

    open fun init(context: Context) {
        this.context = context
        updateModifyTimeMs()
        contentObserver?.let {
            context.contentResolver.unregisterContentObserver(it)
        }
        contentObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean) {
                super.onChange(selfChange)
                updateModifyTimeMs()
            }
        }
        context.contentResolver.registerContentObserver(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                true,
                contentObserver!!
        )
    }

    fun close() {
        contentObserver?.let {
            this.context?.contentResolver?.unregisterContentObserver(it)
        }
        contentObserver = null
        this.context = null
    }

    fun updateModifyTimeMs() {
        modifyTimeMs = System.currentTimeMillis()
    }

    fun getImageFolder(pluginPermission: PluginPermission, sortOrder: PluginSortOrder = PluginSortOrder.DATE_DESC): Observable<PluginDataSet<PluginFolder>> =
            pluginPermission.requestPermissionsObservable(readPermission).flatMap {
                if (it) {
                    Observable.fromCallable {
                        PluginDataSet<PluginFolder>(list = getImageFolder(sortOrder))
                    }.subscribeOn(Schedulers.io())
                } else {
                    Observable.just(PluginDataSet<PluginFolder>(list = mutableListOf()))
                }
            }

    fun getImages(pluginPermission: PluginPermission, bucketId: String?, sortOrder: PluginSortOrder = PluginSortOrder.DATE_DESC, offset: Int? = null, limit: Int? = null): Observable<PluginDataSet<PluginImage>> =
            if (!pluginPermission.checkSelfPermission(readPermission)) {
                Observable.just(PluginDataSet<PluginImage>(permission = false, list = mutableListOf()))
            } else {
                Observable.fromCallable {
                    getImages(bucketId, sortOrder, offset, limit)
                }
            }

    fun getImage(pluginPermission: PluginPermission, id: Long): Observable<PluginImage?> =
        if (!pluginPermission.checkSelfPermission(readPermission)) {
            Observable.just(null)
        } else {
            Observable.fromCallable {
                getImage(id)
            }
        }
    
    fun checkUpdate(timeMs: Long?) =
            timeMs?.let {
                it < modifyTimeMs
            } ?: true

    fun getImageReadBytes(id: Long): ByteArray? {
        this.context?.contentResolver?.openInputStream(ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id))?.use {
            try {
                return it.readBytes()    
            } catch (e: Exception) {
            } finally {
                it.close()
            }
        }

        return null
    }

    fun getBitmapFactoryOption(byteArray: ByteArray): BitmapFactory.Options? {
        var opt: BitmapFactory.Options? = null
        var io: InputStream? = null
        try {
            opt = BitmapFactory.Options()
            opt.inJustDecodeBounds = true
            io = ByteArrayInputStream(byteArray)
            BitmapFactory.decodeStream(io, null, opt)
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            io?.close()
        }
        return opt
    }
    
    fun shareImages(activity: Activity, ids: MutableList<Long>): Boolean {
        if(ids.isEmpty()) {
            return false
        }

        val intent = Intent()
        intent.action = Intent.ACTION_SEND_MULTIPLE
        intent.flags = Intent.FLAG_GRANT_READ_URI_PERMISSION and Intent.FLAG_GRANT_WRITE_URI_PERMISSION
        intent.type = "image/*" /* This example is sharing jpeg images. */

        val uris: ArrayList<Uri> = ArrayList()
        for(id in ids) {
            uris.add(ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id))
        }
        intent.putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
        activity.startActivity(Intent.createChooser(intent, "Share image"))
        return true
    }

    abstract fun getImageFolderCount(bucketId: String?): Int

    abstract fun getImageFolder(sortOrder: PluginSortOrder): MutableList<PluginFolder>

    abstract fun getImages(bucketId: String?, sortOrder: PluginSortOrder, offset: Int? = null, limit: Int? = null): PluginDataSet<PluginImage>

    abstract fun getImage(id: Long): PluginImage?
    
    abstract fun getImageThumbnail(id: Long, width: Int, height: Int): Bitmap?

    abstract fun addImage(pluginPermission: PluginPermission, byteArray: ByteArray, folder: String, name: String, result: (Boolean) -> Unit)

    abstract fun addImage(pluginPermission: PluginPermission, bitmap: Bitmap, format: PluginImageFormat, folder: String, name: String, result: (Boolean) -> Unit)

    abstract fun deleteImage(pluginPermission: PluginPermission, ids: Array<Long>): Observable<MutableList<Long>>
}
