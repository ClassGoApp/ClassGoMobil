import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    #if targetEnvironment(simulator)
    // En simulator: Deshabilitar Firebase completamente
    // Configurar variable de entorno para plugins de Firebase
    setenv("FIREBASE_DISABLED", "1", 1)
    #endif
    
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
