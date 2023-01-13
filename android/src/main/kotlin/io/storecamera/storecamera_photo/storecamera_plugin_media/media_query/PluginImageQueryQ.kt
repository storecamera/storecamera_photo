package io.storecamera.storecamera_photo.storecamera_plugin_media.media_query

import android.annotation.TargetApi
import android.app.RecoverableSecurityException
import android.content.ContentResolver
import android.content.ContentUris
import android.content.ContentValues
import android.content.IntentSender
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.util.Size
import io.reactivex.Observable
import io.reactivex.android.schedulers.AndroidSchedulers
import io.reactivex.schedulers.Schedulers
import io.storecamera.storecamera_photo.storecamera_plugin_media.PluginPermission
import io.storecamera.storecamera_photo.storecamera_plugin_media.data.*
import java.io.File
import java.io.OutputStream


@TargetApi(Build.VERSION_CODES.Q)
class PluginImageQueryQ(private val onWriteImageRequest: (intentSender: IntentSender, onResult: (result: Boolean) -> Unit) -> Unit): PluginImageQuery() {
    
    override fun getImageFolder(sortOrder: PluginSortOrder): MutableList<PluginFolder> {
        val folderSet = mutableSetOf<String>()
        val results = mutableListOf<PluginFolder>()

        val cursor = context?.contentResolver?.query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                arrayOf(
                        MediaStore.Images.Media.BUCKET_ID,
                        MediaStore.Images.Media.BUCKET_DISPLAY_NAME
                ),
                Bundle().apply {
                    putStringArray(
                            ContentResolver.QUERY_ARG_SORT_COLUMNS,
                            arrayOf(MediaStore.Images.Media.DATE_MODIFIED)
                    )
                    when (sortOrder) {
                        PluginSortOrder.DATE_DESC -> {
                            putInt(
                                    ContentResolver.QUERY_ARG_SORT_DIRECTION,
                                    ContentResolver.QUERY_SORT_DIRECTION_DESCENDING
                            )
                        }
                        PluginSortOrder.DATE_ARC -> {
                            putInt(
                                    ContentResolver.QUERY_ARG_SORT_DIRECTION,
                                    ContentResolver.QUERY_SORT_DIRECTION_ASCENDING
                            )
                        }
                    }
                },
                null
        )

        cursor?.let { _cursor ->
            val columnIndexBucketId = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.BUCKET_ID)
            val columnIndexBucketDisplayName = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.BUCKET_DISPLAY_NAME)

            while (_cursor.moveToNext()) {
                val bucketId = cursor.getString(columnIndexBucketId)
                if(bucketId != null && !folderSet.contains(bucketId)) {
                    folderSet.add(bucketId)
                    results.add(PluginFolder(
                            id = bucketId,
                            displayName = cursor.getString(columnIndexBucketDisplayName) ?: "",
                            count = getImageFolderCount(bucketId),
                            modifyTimeMs = 0
                    ))
                }
            }
        }
        cursor?.close()

        return results
    }

    override fun getImages(bucketId: String?, sortOrder: PluginSortOrder, offset: Int?, limit: Int?): PluginDataSet<PluginImage> {
        val cursor = context?.contentResolver?.query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                arrayOf(
                        MediaStore.Images.Media._ID,
                        MediaStore.Images.Media.RELATIVE_PATH,
                        MediaStore.Images.Media.DISPLAY_NAME,
                        MediaStore.Images.Media.MIME_TYPE,
                        MediaStore.Images.Media.ORIENTATION,
                        MediaStore.Images.Media.WIDTH,
                        MediaStore.Images.Media.HEIGHT,
                        MediaStore.Images.Media.DATE_MODIFIED
                ),
                Bundle().apply {
                    if (bucketId != null && bucketId.isNotEmpty()) {
                        putString(ContentResolver.QUERY_ARG_SQL_SELECTION, "${MediaStore.Video.Media.BUCKET_ID}=?")
                        putStringArray(
                                ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS,
                                arrayOf(bucketId)
                        )
                    }
                    offset?.let {
                        putInt(ContentResolver.QUERY_ARG_OFFSET, it)
                    }
                    limit?.let {
                        putInt(ContentResolver.QUERY_ARG_LIMIT, it)
                    }
                    putStringArray(
                            ContentResolver.QUERY_ARG_SORT_COLUMNS,
                            arrayOf(MediaStore.Images.Media.DATE_MODIFIED)
                    )
                    when (sortOrder) {
                        PluginSortOrder.DATE_DESC -> {
                            putInt(
                                    ContentResolver.QUERY_ARG_SORT_DIRECTION,
                                    ContentResolver.QUERY_SORT_DIRECTION_DESCENDING
                            )
                        }
                        PluginSortOrder.DATE_ARC -> {
                            putInt(
                                    ContentResolver.QUERY_ARG_SORT_DIRECTION,
                                    ContentResolver.QUERY_SORT_DIRECTION_ASCENDING
                            )
                        }
                    }
                },
                null
        )

        val results = mutableListOf<PluginImage>()
        cursor?.let { _cursor ->
            val columnIndexID = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
            val columnIndexRelativePath = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.RELATIVE_PATH)
            val columnIndexDisplayName = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DISPLAY_NAME)
            val columnIndexDisplayMimeType = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.MIME_TYPE)
            val columnIndexWidth = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.WIDTH)
            val columnIndexHeight = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.HEIGHT)
            val columnIndexDateModified = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_MODIFIED)

            // Android Galaxy (Android Q(11) 이상) 시리즈에서 offset 밑 limit 가 적용안되는 현상이 있음.
            if(offset != null && offset > 0 && limit != null && limit < _cursor.count) {
                _cursor.moveToPosition(offset)
            }

            while (_cursor.moveToNext()) {
                val displayName = cursor.getString(columnIndexDisplayName) ?: ""
                val path = "${cursor.getString(columnIndexRelativePath)}$displayName"

                results.add(PluginImage(
                        id = cursor.getLong(columnIndexID),
                        fullPath = path,
                        displayName = displayName,
                        mimeType = cursor.getString(columnIndexDisplayMimeType),
                        width = cursor.getInt(columnIndexWidth),
                        height = cursor.getInt(columnIndexHeight),
                        modifyTimeMs = cursor.getLong(columnIndexDateModified) * 1000
                ))

                if(limit?.let { results.size >= it } == true) {
                    break
                }
            }
        }
        cursor?.close()
        return PluginDataSet(list = results)
    }

    override fun getImage(id: Long): PluginImage? {
        @Suppress("DEPRECATION") val cursor = context?.contentResolver?.query(
                ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id),
                arrayOf(
                        MediaStore.Images.Media._ID,
                        MediaStore.Images.Media.RELATIVE_PATH,
                        MediaStore.Images.Media.DISPLAY_NAME,
                        MediaStore.Images.Media.MIME_TYPE,
                        MediaStore.Images.Media.ORIENTATION,
                        MediaStore.Images.Media.WIDTH,
                        MediaStore.Images.Media.HEIGHT,
                        MediaStore.Images.Media.DATE_MODIFIED
                ),
                null,
                null)

        var image: PluginImage? = null
        cursor?.let { _cursor ->
            val columnIndexID = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
            val columnIndexRelativePath = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.RELATIVE_PATH)
            val columnIndexDisplayName = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DISPLAY_NAME)
            val columnIndexDisplayMimeType = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.MIME_TYPE)
            val columnIndexWidth = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.WIDTH)
            val columnIndexHeight = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.HEIGHT)
            val columnIndexDateModified = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_MODIFIED)

            if (_cursor.moveToNext()) {
                val displayName = cursor.getString(columnIndexDisplayName) ?: ""
                val path = "${cursor.getString(columnIndexRelativePath)}$displayName"

                image = PluginImage(
                        id = cursor.getLong(columnIndexID),
                        fullPath = path,
                        displayName = displayName,
                        mimeType = cursor.getString(columnIndexDisplayMimeType),
                        width = cursor.getInt(columnIndexWidth),
                        height = cursor.getInt(columnIndexHeight),
                        modifyTimeMs = cursor.getLong(columnIndexDateModified) * 1000
                )
            }
        }
        cursor?.close()

        return image
    }

    override fun getImageFolderCount(bucketId: String?): Int = try {
        val cursor = context?.contentResolver?.query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                null,
                Bundle().apply {
                    if (bucketId != null && bucketId.isNotEmpty()) {
                        putString(ContentResolver.QUERY_ARG_SQL_SELECTION, "${MediaStore.Video.Media.BUCKET_ID}=?")
                        putStringArray(
                                ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS,
                                arrayOf(bucketId)
                        )
                    }
                },
                null)
        val count: Int = cursor?.count ?: 0
        cursor?.close()
        count
    } catch (e: Exception) {
        0
    }

    override fun getImageThumbnail(id: Long, width: Int, height: Int): Bitmap? =
        this.context?.contentResolver?.loadThumbnail(
                ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id),
                Size(width, height),
                null
        )

    override fun addImage(pluginPermission: PluginPermission, byteArray: ByteArray, folder: String, name: String, result: (Boolean) -> Unit) {
        @Suppress("UNUSED_VARIABLE") val disposable = Observable.fromCallable {
            addImage(byteArray, folder, name)
        }.subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe({
                    result(it)
                }, {
                    result(false)
                })
    }

    override fun addImage(pluginPermission: PluginPermission, bitmap: Bitmap, format: PluginImageFormat, folder: String, name: String, result: (Boolean) -> Unit) {
        @Suppress("UNUSED_VARIABLE") val disposable = Observable.fromCallable {
            addImage(bitmap, format, folder, name)
        }.subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe({
                    result(it)
                }, {
                    result(false)
                })
    }

    override fun deleteImage(pluginPermission: PluginPermission, ids: Array<Long>): Observable<MutableList<Long>> {
        var observable = Observable.just(mutableListOf<Long>())
        for(id in ids) {
            observable = observable.flatMap { list ->
                deleteImageObservable(id).map {
                    if(it.second) {
                        list.add(it.first)
                    }
                    list
                }
            }
        }

        return observable
    }

    private fun deleteImageObservable(id: Long): Observable<Pair<Long, Boolean>> {
        return Observable.create<Pair<Long, Boolean>> { emitter ->
            try {
                this.context?.contentResolver?.delete(ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id), null, null)
                emitter.onNext(Pair(id, true))
                emitter.onComplete()
            } catch (securityException: SecurityException) {
                val intentSender = (securityException as? RecoverableSecurityException)?.userAction?.actionIntent?.intentSender
                if (intentSender != null) {
                    onWriteImageRequest(intentSender) {
                        if (it) {
                            try {
                                this.context?.contentResolver?.delete(ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id), null, null)
                                emitter.onNext(Pair(id, true))
                                emitter.onComplete()
                            } catch (e: Exception) {
                                emitter.onNext(Pair(id, false))
                                emitter.onComplete()
                            }
                        } else {
                            emitter.onNext(Pair(id, false))
                            emitter.onComplete()
                        }
                    }
                } else {
                    emitter.onNext(Pair(id, false))
                    emitter.onComplete()
                }
            }
        }
    }

    private fun addImage(bitmap: Bitmap, format: PluginImageFormat, folder: String, name: String): Boolean {
        val contentResolver: ContentResolver = context?.contentResolver ?: return false
        val values = ContentValues()
        val mimeType: String = when(format) {
            PluginImageFormat.BITMAP -> null
            PluginImageFormat.JPG -> "image/jpeg"
            PluginImageFormat.PNG -> "image/png"
        } ?: return false

        val relativePath = if(folder.isNotEmpty()) "${Environment.DIRECTORY_PICTURES}${File.separatorChar}$folder" else Environment.DIRECTORY_PICTURES
        values.put(MediaStore.Images.Media.DISPLAY_NAME, name)
        values.put(MediaStore.Images.Media.MIME_TYPE, mimeType)
        if(format == PluginImageFormat.PNG) {
            values.put(MediaStore.Images.Media.WIDTH, bitmap.width)
            values.put(MediaStore.Images.Media.HEIGHT, bitmap.height)
        }
        values.put(MediaStore.Images.Media.RELATIVE_PATH, relativePath)

        var imageOutStream: OutputStream? = null
        try {
            contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)?.let {
                imageOutStream = contentResolver.openOutputStream(it)
                when(format) {
                    PluginImageFormat.BITMAP -> {}
                    PluginImageFormat.JPG -> bitmap.compress(Bitmap.CompressFormat.JPEG, 100, imageOutStream)
                    PluginImageFormat.PNG -> bitmap.compress(Bitmap.CompressFormat.PNG, 100, imageOutStream)
                }

                values.put(MediaStore.MediaColumns.IS_PENDING, false)
                contentResolver.update(it, values, null, null)
                return true
            }
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            imageOutStream?.close()
        }
        return false
    }

    private fun addImage(byteArray: ByteArray, folder: String, name: String): Boolean {
        val contentResolver: ContentResolver = context?.contentResolver ?: return false

        val options: BitmapFactory.Options = getBitmapFactoryOption(byteArray) ?: return false

        val values = ContentValues()
        val relativePath = if(folder.isNotEmpty()) "${Environment.DIRECTORY_PICTURES}${File.separatorChar}$folder" else Environment.DIRECTORY_PICTURES
        values.put(MediaStore.Images.Media.DISPLAY_NAME, name)
        values.put(MediaStore.Images.Media.MIME_TYPE, options.outMimeType)
        values.put(MediaStore.Images.Media.WIDTH, options.outWidth)
        values.put(MediaStore.Images.Media.HEIGHT, options.outHeight)
        values.put(MediaStore.Images.Media.RELATIVE_PATH, relativePath)

        var imageOutStream: OutputStream? = null
        try {
            contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)?.let {
                imageOutStream = contentResolver.openOutputStream(it)
                imageOutStream?.write(byteArray)

                values.put(MediaStore.MediaColumns.IS_PENDING, false)
                contentResolver.update(it, values, null, null)
                return true
            }
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            imageOutStream?.close()
        }
        return false
    }
//    override fun getImageInfo(id: Long): PluginImageInfo? {
//        val cursor = context?.contentResolver?.query(
//                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
//                arrayOf(
//                        MediaStore.Images.Media._ID,
//                        MediaStore.Images.Media.RELATIVE_PATH,
//                        MediaStore.Images.Media.DISPLAY_NAME,
//                        MediaStore.Images.Media.MIME_TYPE,
//                        MediaStore.Images.Media.ORIENTATION,
//                        MediaStore.Images.Media.WIDTH,
//                        MediaStore.Images.Media.HEIGHT,
//                        MediaStore.Images.Media.DATE_MODIFIED
//                ),
//                Bundle().apply {
//                    putString(ContentResolver.QUERY_ARG_SQL_SELECTION, "${MediaStore.Video.Media._ID}=?")
//                    putStringArray(
//                            ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS,
//                            arrayOf(id.toString())
//                    )
//                    putInt(ContentResolver.QUERY_ARG_LIMIT, 1)
//                },
//                null
//        )
//
//        var pluginImageInfo: PluginImageInfo? = null
//        cursor?.let { _cursor ->
//            while (_cursor.moveToNext()) {
//                val displayName = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DISPLAY_NAME))
//                val path = "${MediaStore.Images.Media.EXTERNAL_CONTENT_URI}${File.separatorChar}${cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.Images.Media.RELATIVE_PATH))}${File.separatorChar}$displayName"
//                pluginImageInfo = PluginImageInfo(
//                        id = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID)),
//                        path = path,
//                        displayName = displayName,
//                        mimeType = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.Images.Media.MIME_TYPE)),
//                        orientation = cursor.getInt(cursor.getColumnIndexOrThrow(MediaStore.Images.Media.ORIENTATION)),
//                        width = cursor.getInt(cursor.getColumnIndexOrThrow(MediaStore.Images.Media.WIDTH)),
//                        height = cursor.getInt(cursor.getColumnIndexOrThrow(MediaStore.Images.Media.HEIGHT)),
//                        modifyTimeMs = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_MODIFIED)) * 1000
//                )
//                break
//            }
//        }
//        cursor?.close()
//        return pluginImageInfo
//    }
}
