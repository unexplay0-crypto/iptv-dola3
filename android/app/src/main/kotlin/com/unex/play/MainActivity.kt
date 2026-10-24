package com.unex.play

import android.content.pm.PackageManager
import android.content.res.Configuration
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "com.unex.play/device"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isTv" -> result.success(isTv())
                    else -> result.notImplemented()
                }
            }
    }

    /// Detecção oficial de Android TV:
    ///  - FEATURE_LEANBACK (declarado no manifest como não-requerido)
    ///  - ou uiMode do tipo TELEVISION (cobre Google TV / Fire TV).
    private fun isTv(): Boolean {
        val pm = packageManager
        val hasLeanback = pm.hasSystemFeature(PackageManager.FEATURE_LEANBACK)
        val uiMode = resources.configuration.uiMode and Configuration.UI_MODE_TYPE_MASK
        val isTelevisionUi = uiMode == Configuration.UI_MODE_TYPE_TELEVISION
        return hasLeanback || isTelevisionUi
    }
}
