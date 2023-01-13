package io.storecamera.storecamera_photo.storecamera_plugin_media

import android.content.pm.PackageManager
import io.reactivex.Observable
import io.reactivex.android.schedulers.AndroidSchedulers

/** ZpdlStudioMediaPlugin */
class PluginPermission(
        private val checkSelfPermission: (permission: String) -> Boolean,
        private val requestPermission: (requestCode: Int, permissions: Array<String>) -> Boolean
) {
    data class Request(
            val requestCode: Int,
            val permissions: MutableList<String>,
            val requestPermissions: MutableList<String>,
            val grantedPermissions: MutableList<String>,
            val result: (Boolean) -> Unit
    )

    private var requestCode = 0
    private val requests = mutableListOf<Request>()

    @Suppress("MemberVisibilityCanBePrivate")
    fun requestPermissions(permissions: MutableList<String>, result: (Boolean) -> Unit) {
        if(permissions.isEmpty()) {
            result(false)
            return
        }

        val grants = mutableListOf<String>()
        val requests = mutableListOf<String>()

        for(permission in permissions) {
            if(checkSelfPermission(permission)) {
                grants.add(permission)
            } else {
                requests.add(permission)
            }
        }

        if(requests.isNotEmpty()) {
            this.requestCode++
            val requestCode = this.requestCode
            val request = Request(
                    requestCode,
                    permissions,
                    requests,
                    grants,
                    result
            )
            this.requests.add(request)

            if (!requestPermission(
                            requestCode,
                            requests.toTypedArray())) {
                this.requests.remove(request)
                result(false)
            }
        } else {
            result(true)
        }
    }

    fun checkSelfPermission(permissions: MutableList<String>): Boolean {
        for(permission in permissions) {
            if(!checkSelfPermission(permission)) {
                return false
            }
        }
        return true
    }

    fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray): Boolean {
        var request: Request? = null
        for(i in requests.indices) {
            if(requests[i].requestCode == requestCode) {
                request = requests.removeAt(i)
                break
            }
        }

        return request?.let {
            for(i in grantResults.indices) {
                if(i < permissions.size) {
                    when(grantResults[i]) {
                        PackageManager.PERMISSION_GRANTED -> it.grantedPermissions.add(permissions[i])
                    }
                }
            }

            it.result(it.permissions.size == it.grantedPermissions.size)
            true
        } ?: false
    }

    fun requestPermissionsObservable(permissions: MutableList<String>): Observable<Boolean> {
        return Observable.defer {
            val observable: Observable<Boolean> = Observable.create { emitter ->
                requestPermissions(permissions) {
                    emitter.onNext(it)
                    emitter.onComplete()
                }
            }
            observable.subscribeOn(AndroidSchedulers.mainThread())
        }
    }

    fun close() {
        val iterator = requests.iterator()
        while (iterator.hasNext()) {
            iterator.next().result(false)
            iterator.remove()
        }
    }
}
