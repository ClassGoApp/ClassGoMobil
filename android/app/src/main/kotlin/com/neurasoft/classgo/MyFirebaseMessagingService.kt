package com.neurasoft.classgo

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
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
        val iconName = remoteMessage.data["icon"] ?: "ic_stat_pendiente"
        Log.d("MyFirebaseMsgService", "Icon recibido desde backend: $iconName")
        val requestedIconResId = resources.getIdentifier(iconName, "drawable", packageName)
        val iconResId = if (requestedIconResId != 0) requestedIconResId else R.mipmap.ic_launcher

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

        val notificationBuilder = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(iconResId)
            .setContentTitle(title)
            .setContentText(body)
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
} 