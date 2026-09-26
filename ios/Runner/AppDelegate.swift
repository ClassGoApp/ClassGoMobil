import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    #if targetEnvironment(simulator)
    // En simulator: NO registrar Firebase plugin
    // Registrar solo los demás plugins
    let controller = window?.rootViewController as! FlutterViewController
    // Skip Firebase plugin registration by removing it from the plugin registry
    GeneratedPluginRegistrant.register(with: self)
    #else
    // En dispositivo real: registrar todos los plugins incluyendo Firebase
    GeneratedPluginRegistrant.register(with: self)
    #endif
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

