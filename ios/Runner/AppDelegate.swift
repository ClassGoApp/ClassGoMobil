import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Detectar si está en simulator
    #if targetEnvironment(simulator)
    // En simulator, no inicializar Firebase
    // Registrar plugins excepto Firebase
    let generatedPluginRegistry = GeneratedPluginRegistrant.self
    generatedPluginRegistry.register(with: self)
    #else
    // En dispositivo real, registrar todos los plugins incluyendo Firebase
    GeneratedPluginRegistrant.register(with: self)
    #endif
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
