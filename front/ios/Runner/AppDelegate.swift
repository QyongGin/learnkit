import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 알림 플러그인 등록
    GeneratedPluginRegistrant.register(with: self)

    // iOS 10+ 알림 센터 설정
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // 포그라운드(앱 실행 중) 알림 표시 처리
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // iOS 14+: banner, list, sound 모두 표시
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound])
    } else {
      // iOS 10-13: alert, sound 표시
      completionHandler([.alert, .sound])
    }
  }
}
