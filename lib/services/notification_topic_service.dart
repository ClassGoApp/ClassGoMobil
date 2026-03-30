import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationTopicService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static const String _tutorTopic = 'tutor';
  static const String _tutorLegacyTopic = 'tutores';
  static const String _studentTopic = 'estudiantes';

  /// Suscribe al usuario según su rol
  static Future<void> configureTopics(String rol) async {
    try {
      if (rol == 'tutor') {
        await _messaging.subscribeToTopic(_tutorTopic);
        await _messaging.subscribeToTopic(_tutorLegacyTopic);
        await _messaging.unsubscribeFromTopic(_studentTopic);
        print('Suscrito a topics: $_tutorTopic, $_tutorLegacyTopic');
      } else if (rol == 'student') {
        await _messaging.subscribeToTopic(_studentTopic);
        await _messaging.unsubscribeFromTopic(_tutorTopic);
        await _messaging.unsubscribeFromTopic(_tutorLegacyTopic);
        print('Suscrito a topic: $_studentTopic');
      }
    } catch (e) {
      print('Error al configurar topics: $e');
    }
  }

  /// Desuscribir de todos (por ejemplo al hacer logout)
  static Future<void> unsubscribeAll() async {
    try {
      await _messaging.unsubscribeFromTopic(_tutorTopic);
      await _messaging.unsubscribeFromTopic(_tutorLegacyTopic);
      await _messaging.unsubscribeFromTopic(_studentTopic);
      print('Desuscrito de todos los topics');
    } catch (e) {
      print('Error al desuscribirse: $e');
    }
  }

  /// Suscribirse manualmente a un topic (por si luego agregas más)
  static Future<void> subscribe(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('Suscrito a: $topic');
    } catch (e) {
      print('Error al suscribirse: $e');
    }
  }

  /// Desuscribirse manualmente
  static Future<void> unsubscribe(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('Desuscrito de: $topic');
    } catch (e) {
      print('Error al desuscribirse: $e');
    }
  }
}
