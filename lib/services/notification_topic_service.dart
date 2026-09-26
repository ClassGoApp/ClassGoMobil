import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Firebase disabled for simulator compatibility
// This service is stubbed to allow compilation without Firebase

class NotificationTopicService {
  static const String _tutorTopic = 'tutor';
  static const String _tutorLegacyTopic = 'tutores';
  static const String _studentTopic = 'estudiantes';
  static const String _fcmRoleKey = 'fcm_user_role';
  static const String _permissionAskedKey = 'notification_permission_asked';

  static Future<void> _persistCurrentRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmRoleKey, role);
  }

  /// Firebase disabled - no topic subscription
  static Future<void> configureTopics(String rol) async {
    print('⚠️ Firebase disabled - configureTopics skipped');
    return;
  }

  /// Firebase disabled - no unsubscribe
  static Future<void> unsubscribeAll() async {
    print('⚠️ Firebase disabled - unsubscribeAll skipped');
    return;
  }

  /// Firebase disabled - no manual subscribe
  static Future<void> subscribe(String topic) async {
    print('⚠️ Firebase disabled - subscribe skipped');
    return;
  }

  /// Firebase disabled - no manual unsubscribe
  static Future<void> unsubscribe(String topic) async {
    print('⚠️ Firebase disabled - unsubscribe skipped');
    return;
  }

  /// Firebase disabled - no mass notification subscribe
  static Future<void> subscribeToMassNotification() async {
    print('⚠️ Firebase disabled - subscribeToMassNotification skipped');
    return;
  }

  /// Firebase disabled - no permission request
  static Future<void> requestPermissionOnFirstLaunch() async {
    print('⚠️ Firebase disabled - requestPermissionOnFirstLaunch skipped');
    return;
  }
}

/// Firebase background handler - disabled for simulator
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(dynamic message) async {
  print('⚠️ Firebase disabled - firebaseMessagingBackgroundHandler skipped');
  return;
}
