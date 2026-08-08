import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'SnoozeService.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse details) async {
  WidgetsFlutterBinding.ensureInitialized();

  print(
    "🔘 [NotificationTapBackground] Nhận event bấm nút: actionId=${details.actionId}, payload=${details.payload}",
  );

  if (details.actionId == 'SNOOZE_15_MINS' && details.payload != null) {
    bool saved = await SnoozeService.setSnooze(details.payload!, minutes: 15);
    if (saved) {
      print(
        "✅ [BACKGROUND SNOOZE SUCCESS] Đã hoãn thành công [$details.payload]",
      );
    } else {
      print("❌ [BACKGROUND SNOOZE FAILED] Lỗi lưu SharedPreferences!");
    }
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) async {
        print(
          "🔘 [Foreground Tap] Nhận event bấm nút ở Foreground: ${details.actionId}",
        );
        if (details.actionId == 'SNOOZE_15_MINS' && details.payload != null) {
          await SnoozeService.setSnooze(details.payload!, minutes: 15);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  static Future<void> showSnoozableNotification({
    required int id,
    required String title,
    required String body,
    required String alertType,
  }) async {
    bool isSnoozed = await SnoozeService.isSnoozed(alertType);
    if (isSnoozed) {
      print("🔕 [BLOCKED] Sự cố [$alertType] đang bị tạm dừng thông báo.");
      return;
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'smart_farm_alerts',
          'Cảnh Báo Khẩn Cấp Hệ Thống Gà',
          importance: Importance.max,
          priority: Priority.high,
          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction(
              'SNOOZE_15_MINS',
              'Đang xử lý (Tắt 15p)',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: alertType,
    );
  }

  static Future<void> showStandardNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'smart_farm_daily_channel',
          'Thông Báo Định Kỳ Hệ Thống',
          channelDescription:
              'Kênh nhận thông báo khẩu phần ăn, lịch vắc-xin...',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          playSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: payload?.toString(),
    );
  }
}
