import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDs5zKv82dGel5tUUIWE7MsLLyEBCKNW1g',
    appId: '1:934911540456:android:306f0e768c07edede45d5d',
    messagingSenderId: '934911540456',
    projectId: 'classgo-fec0d',
    storageBucket: 'classgo-fec0d.firebasestorage.app',
  );

  static FirebaseOptions get currentPlatform => android;
}
