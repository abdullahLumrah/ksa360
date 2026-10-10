import Flutter
import GoogleMaps
import Network
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var localNetworkBrowser: NWBrowser?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyAUjMG0glAvJsfUZJ-D0KPU_JC_foYbJqM")
    GeneratedPluginRegistrant.register(with: self)
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()
    promptLocalNetworkAccess()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// iOS will not load LAN HTTP until Local Network is allowed.
  private func promptLocalNetworkAccess() {
    let browser = NWBrowser(for: .bonjour(type: "_http._tcp", domain: nil), using: .tcp)
    browser.stateUpdateHandler = { _ in }
    browser.start(queue: .main)
    localNetworkBrowser = browser
  }
}
