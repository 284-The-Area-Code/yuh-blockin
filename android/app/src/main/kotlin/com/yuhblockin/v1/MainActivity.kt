package com.yuhblockin.v1

import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.yuhblockin.v1/notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "canUseFullScreenIntent") {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                    result.success(manager.canUseFullScreenIntent())
                } else {
                    result.success(true)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
