package com.neurasoft.classgo

import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
	private val channelName = "classgo/notification_click"
	private var methodChannel: MethodChannel? = null
	private var pendingNotificationData: HashMap<String, String>? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		methodChannel = MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			channelName
		)

		methodChannel?.setMethodCallHandler { call, result ->
			when (call.method) {
				"getInitialNotificationData" -> {
					result.success(pendingNotificationData)
					pendingNotificationData = null
				}
				else -> result.notImplemented()
			}
		}

		consumeNotificationClickIntent(intent, notifyFlutter = false)
	}

	override fun onNewIntent(intent: Intent) {
		super.onNewIntent(intent)
		setIntent(intent)
		consumeNotificationClickIntent(intent, notifyFlutter = true)
	}

	private fun consumeNotificationClickIntent(intent: Intent?, notifyFlutter: Boolean) {
		if (intent?.action != "FLUTTER_NOTIFICATION_CLICK") {
			return
		}

		val data = HashMap<String, String>()
		val extras = intent.extras
		if (extras != null) {
			for (key in extras.keySet()) {
				data[key] = extras.get(key)?.toString() ?: ""
			}
		}

		pendingNotificationData = data

		if (notifyFlutter) {
			methodChannel?.invokeMethod("onNotificationClick", data)
		}

		intent.action = null
	}
}
