import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Must match `BackgroundTasks.uniquePeriodic` in Dart and the entry in
  /// `Info.plist` → `BGTaskSchedulerPermittedIdentifiers`. All three are the
  /// same string by requirement, not by convention.
  private static let periodicSyncTaskIdentifier = "paceshift.periodic"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // iOS requires every BGTask handler to be registered *before* launch
    // finishes. Dart's `registerPeriodicTask` only submits the request — if no
    // handler was registered first, `BGTaskScheduler.submit` raises an
    // uncaught NSException ("No launch handler registered…") that no Dart
    // try/catch can absorb, and the app dies on launch.
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: Self.periodicSyncTaskIdentifier,
      frequency: NSNumber(value: 6 * 60 * 60)
    )
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
