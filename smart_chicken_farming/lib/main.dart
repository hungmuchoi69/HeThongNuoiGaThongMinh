import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smart_chicken_farming/page/AuthCheckScreen.dart';
import 'package:smart_chicken_farming/service/NetworkService.dart';
import 'package:smart_chicken_farming/service/NotificationService.dart';
import 'package:smart_chicken_farming/service/UserSession.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'smart_farm_alerts',
  'Cảnh Báo Khẩn Cấp Hệ Thống Gà',
  description: 'Kênh chuyên dùng để bắn còi báo động khi chuồng gà có sự cố.',
  importance: Importance.max,
  playSound: true,
);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Lấy dữ liệu từ Data Payload do Backend Spring Boot gửi về
  String? alertType = message.data['alert_type'];
  String title = message.data['title'] ?? message.notification?.title ?? 'Cảnh báo sự cố';
  String body = message.data['content'] ?? message.data['body'] ?? message.notification?.body ?? 'Phát hiện sự cố hệ thống!';

  if (alertType != null && alertType.isNotEmpty) {
    await NotificationService.showSnoozableNotification(
      id: message.hashCode,
      title: title,
      body: body,
      alertType: alertType,
    );
  } else {
    if (message.notification == null) {
      await NotificationService.showStandardNotification(
        id: message.hashCode,
        title: title,
        body: body,
        payload: message.data,
      );
    }
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MyAppLauncher());
}

class MyAppLauncher extends StatefulWidget {
  const MyAppLauncher({super.key});

  @override
  State<MyAppLauncher> createState() => _MyAppLauncherState();
}

class _MyAppLauncherState extends State<MyAppLauncher> {
  final NetworkService _networkService = NetworkService();
  bool _isLoading = true;
  bool _hasInternet = true;
  bool _isLogged = false;

  @override
  void initState() {
    super.initState();
    _initAppWorkflow();
  }

  Future<void> _initAppWorkflow() async {
    setState(() {
      _isLoading = true;
      _hasInternet = true;
    });
    bool connected = await _networkService.hasIntenet();
    if (!connected) {
      setState(() {
        _hasInternet = false;
        _isLoading = false;
      });
      return;
    }

    try {
      try {
        await Supabase.initialize(
          url: 'https://nsaoytpkiwfsnmlezbsa.supabase.co',
          anonKey:
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5zYW95dHBraXdmc25tbGV6YnNhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk0MTQxNDgsImV4cCI6MjA5NDk5MDE0OH0.NZkLm83XZjDEZ-j0NhsqIf5Ci4E2oyMDzYPEGLX-Jlw',
        );
      } catch (e) {
        print("Supabase đã được khởi tạo trước đó.");
      }

      await Firebase.initializeApp();

      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      await NotificationService.initialize();

      await NotificationService.localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: false,
            badge: true,
            sound: false,
          );
          
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        String userId = user.id.replaceAll("-", "");
        await messaging.unsubscribeFromTopic("all_farmers");
        await messaging.subscribeToTopic(userId);
      }

      _isLogged = await userSession.loadSession();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("❌ Lỗi khởi tạo hệ thống: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gite_rounded, size: 80, color: Colors.orange),
                SizedBox(height: 20),
                CircularProgressIndicator(color: Colors.orange),
              ],
            ),
          ),
        ),
      );
    }

    if (!_hasInternet) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    size: 90,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Không có kết nối mạng",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Vui lòng kiểm tra lại kết nối Wifi hoặc 4G để vào ứng dụng.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _initAppWorkflow,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Thử lại"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return MyApp(isLogged: _isLogged);
  }
}

class MyApp extends StatefulWidget {
  final bool isLogged;
  const MyApp({super.key, required this.isLogged});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final NetworkService _networkService = NetworkService();
  bool _isNoInternet = false;

  @override
  void initState() {
    super.initState();
    _networkService.connectivityStream.listen((
      List<ConnectivityResult> results,
    ) {
      setState(() {
        _isNoInternet = results.contains(ConnectivityResult.none);
      });
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      String? alertType = message.data['alert_type'];
      String title = message.data['title'] ?? message.notification?.title ?? 'Thông báo hệ thống';
      String body = message.data['content'] ?? message.data['body'] ?? message.notification?.body ?? '';

      if (alertType != null && alertType.isNotEmpty) {
        NotificationService.showSnoozableNotification(
          id: message.hashCode,
          title: title,
          body: body,
          alertType: alertType,
        );
      } else {
        NotificationService.showStandardNotification(
          id: message.hashCode,
          title: title,
          body: body,
          payload: message.data,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NetworkService.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Smart Farm',
      routes: {'/dashboard': (context) => const Authcheckscreen()},
      home: Scaffold(
        body: Stack(
          children: [
            const Authcheckscreen(),
            if (_isNoInternet)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    color: Colors.amber[800],
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text(
                          "Mất kết nối Internet. Vui lòng kiểm tra lại!",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}