package com.neurasoft.classgo

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {
    private val channelId = "classgo_alerts_v2"

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        val rolePrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val currentRole = rolePrefs.getString("flutter.fcm_user_role", "unknown")?.lowercase()
        val fromValue = remoteMessage.from?.lowercase() ?: ""
        val screenValue = remoteMessage.data["screen"]?.lowercase() ?: ""
        val typeValue = remoteMessage.data["type"]?.lowercase() ?: ""
        val isFlexiblePush =
            screenValue == "solicitud_detalle" ||
            screenValue == "detalle_solicitud" ||
            typeValue == "solicitud_tutor_personalizada" ||
            typeValue == "solicitud_flexible"

        if (isFlexiblePush) {
            saveFlexibleRequestToFlutterPrefs(remoteMessage.data)
        }

        val isTutorPush =
            fromValue.endsWith("/topics/tutor") ||
            fromValue.endsWith("/topics/tutores") ||
            screenValue == "solicitud_tutor"

        if (isTutorPush && currentRole != "tutor") {
            Log.w(
                "MyFirebaseMsgService",
                "Notificacion de tutor ignorada para rol actual: $currentRole"
            )
            return
        }

        val iconName = remoteMessage.data["icon"] ?: "ic_notification_outline"
        Log.d("MyFirebaseMsgService", "Icon recibido desde backend: $iconName")
        var requestedIconResId = resources.getIdentifier(iconName, "drawable", packageName)
        if (requestedIconResId == 0) {
            requestedIconResId = resources.getIdentifier(iconName, "mipmap", packageName)
        }
        val iconResId = if (requestedIconResId != 0) requestedIconResId else R.drawable.ic_notification_outline

        val title = remoteMessage.notification?.title
            ?: remoteMessage.data["title"]
            ?: "ClassGo"
        val body = remoteMessage.notification?.body
            ?: remoteMessage.data["body"]
            ?: remoteMessage.data["message"]
            ?: "Tienes una nueva notificacion"

        Log.d("MyFirebaseMsgService", "Titulo final: $title")
        Log.d("MyFirebaseMsgService", "Body final: $body")

        if (!NotificationManagerCompat.from(this).areNotificationsEnabled()) {
            Log.w("MyFirebaseMsgService", "Notificaciones deshabilitadas a nivel de sistema para la app")
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val hasPermission = ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED

            if (!hasPermission) {
                Log.w("MyFirebaseMsgService", "Permiso POST_NOTIFICATIONS no concedido")
                return
            }
        }

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        if (launchIntent == null) {
            Log.w("MyFirebaseMsgService", "No se pudo crear LaunchIntent para notificacion")
            return
        }

        launchIntent.action = "FLUTTER_NOTIFICATION_CLICK"
        launchIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)

        for ((key, value) in remoteMessage.data) {
            launchIntent.putExtra(key, value)
        }

        val pendingIntentFlags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0

        val contentIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            pendingIntentFlags
        )

        val notificationBuilder = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(iconResId)
            .setContentTitle(title)
            .setContentText(body)
            .setContentIntent(contentIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setAutoCancel(true)

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Crear canal de notificación para Android 8+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Alertas ClassGo",
                NotificationManager.IMPORTANCE_HIGH
            )
            channel.description = "Canal para alertas urgentes de tutorias"
            notificationManager.createNotificationChannel(channel)
        }

        val notificationId = (System.currentTimeMillis() % Int.MAX_VALUE).toInt()
        notificationManager.notify(notificationId, notificationBuilder.build())
        Log.d("MyFirebaseMsgService", "Notificacion publicada con id: $notificationId")
    }

    private fun saveFlexibleRequestToFlutterPrefs(data: Map<String, String>) {
        try {
            val rolePrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val existingJson = rolePrefs.getString("flutter.cached_pending_flexible_requests", null)

            val jsonArray = if (!existingJson.isNullOrEmpty()) {
                try {
                    org.json.JSONArray(existingJson)
                } catch (e: Exception) {
                    org.json.JSONArray()
                }
            } else {
                org.json.JSONArray()
            }

            val newObject = org.json.JSONObject()
            for ((k, v) in data) {
                newObject.put(k, v)
            }

            val dataTutorStr = data["data_tutor"]
            var newToken: String? = data["token"] ?: data["accept_token"]
            if (dataTutorStr != null) {
                try {
                    var dtObj: org.json.JSONObject? = null
                    if (dataTutorStr.startsWith("{")) {
                        dtObj = org.json.JSONObject(dataTutorStr)
                    }
                    if (dtObj != null) {
                        newToken = dtObj.optString("token", dtObj.optString("accept_token", newToken))
                    }
                } catch (_: Exception) {}
            }

            val filteredArray = org.json.JSONArray()
            if (!newToken.isNullOrEmpty()) {
                for (i in 0 until jsonArray.length()) {
                    val item = jsonArray.optJSONObject(i) ?: continue
                    var existingToken = item.optString("token", item.optString("accept_token", ""))
                    val itemDtStr = item.optString("data_tutor", null)
                    if (itemDtStr != null && itemDtStr.startsWith("{")) {
                        try {
                            val dtObj = org.json.JSONObject(itemDtStr)
                            existingToken = dtObj.optString("token", dtObj.optString("accept_token", existingToken))
                        } catch (_: Exception) {}
                    }
                    if (existingToken != newToken) {
                        filteredArray.put(item)
                    }
                }
            } else {
                for (i in 0 until jsonArray.length()) {
                    filteredArray.put(jsonArray.get(i))
                }
            }

            val finalArray = org.json.JSONArray()
            finalArray.put(newObject)
            for (i in 0 until filteredArray.length()) {
                finalArray.put(filteredArray.get(i))
            }

            rolePrefs.edit().putString("flutter.cached_pending_flexible_requests", finalArray.toString()).apply()
            Log.d("MyFirebaseMsgService", "💾 Guardada solicitud flexible en SharedPreferences de Flutter desde Kotlin!")
        } catch (e: Exception) {
            Log.e("MyFirebaseMsgService", "❌ Error guardando solicitud flexible en Kotlin: ${e.message}")
        }
    }
} 