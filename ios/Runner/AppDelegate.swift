import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging
import BackgroundTasks

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Firebase
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    
    // Register for notifications
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { granted, error in
          print("Notification permission granted: \(granted)")
        }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    
    application.registerForRemoteNotifications()

    // Set Messaging delegate
    Messaging.messaging().delegate = self
    
    // Register background task
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: "com.example.raffle-Fox.backgroundtask",
      using: nil
    ) { task in
      self.handleBackgroundTask(task: task)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle APNs token
  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }
  
  private func handleBackgroundTask(task: BGTask) {
    // Perform background processing here
    print("Handling background task: \(task.identifier)")
    task.setTaskCompleted(success: true)
  }
}

extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("Firebase registration token: \(String(describing: fcmToken))")
  }
}
