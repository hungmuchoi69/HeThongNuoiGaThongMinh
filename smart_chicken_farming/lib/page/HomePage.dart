import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:smart_chicken_farming/model/LuaGa.dart';
import 'package:smart_chicken_farming/page/AnalyticsScreen.dart';
import 'package:smart_chicken_farming/page/DailyFeedNutritionCard.dart';
import 'package:smart_chicken_farming/page/NotificationPage.dart';
import 'package:smart_chicken_farming/service/APIService.dart';
import 'package:smart_chicken_farming/service/NetworkService.dart';
import 'package:smart_chicken_farming/service/mqttService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MqttService _mqttService = MqttService();
  bool _isMqttConnected = false;
  int _unreadCount = 0;
  int? _currentLuaGaId;
  LuaGa? _luaGa;

  double temperature = 0.0;
  double humidity = 0.0;
  double tds = 0.0;
  int gas = 0;

  List<FlSpot> tempHistory = [const FlSpot(0, 0)];
  int chartIndex = 0;

  @override
  void initState() {
    super.initState();
    _connectMqtt();
    _loadUnreadNotificationCount();

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage mess) {
      _handleNotificationRoute(mess.data);
    });

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? mess) {
      if (mess != null) {
        Future.delayed(const Duration(milliseconds: 800), () {
          _handleNotificationRoute(mess.data);
        });
      }
    });
  }

  Future<bool> _ensureNetworkAvailable(BuildContext context) async {
    final hasInternet = await NetworkService().hasIntenet();
    if (!hasInternet) {
      NetworkService.showNoInternetDialog(context: context);
      return false;
    }
    return true;
  }

  void _connectMqtt() async {
    final bool connected = await _mqttService.connect();
    if (!mounted) return;

    setState(() {
      _isMqttConnected = connected;
    });

    if (connected) {
      _mqttService.messageStream?.listen((
        List<MqttReceivedMessage<MqttMessage>> messages,
      ) {
        if (!mounted) return;

        if (messages.isNotEmpty) {
          final received = messages[0];
          final String topic = received.topic;
          final MqttPublishMessage recMess =
              received.payload as MqttPublishMessage;
          final String pt = MqttPublishPayload.bytesToStringAsString(
            recMess.payload.message,
          );

          if (topic.endsWith('/notifications')) {
            try {
              final Map<String, dynamic> payload = jsonDecode(pt);
              if (payload['unreadCount'] != null) {
                if (!mounted) return;
                setState(() {
                  _unreadCount = (payload['unreadCount'] as num).toInt();
                });
              }
            } catch (e) {
              debugPrint('❌ Lỗi đọc notification payload: $e');
            }
            return;
          }

          _parseSensorData(pt);
        }
      });
    }
  }

  void _loadUnreadNotificationCount() async {
    if (!mounted) return;

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    final currentContext = context;
    final LuaGa? luaGa = await Apiservice.findByUserIdAndTrangThai(
      currentUser.id,
      "RAISING",
      context: currentContext,
    );
    if (!mounted || !currentContext.mounted) return;
    if (luaGa == null || luaGa.id == null) return;

    final int count = await Apiservice.countUnreadNotification(
      luaGa.id!,
      context: currentContext,
    );
    if (!mounted || !currentContext.mounted) return;
    if (count == -1) return;

    setState(() {
      _unreadCount = count < 0 ? 0 : count;
      _currentLuaGaId = luaGa.id;
      _luaGa = luaGa;
    });
  }

  void _parseSensorData(String rawJson) {
    try {
      final Map<String, dynamic> data = jsonDecode(rawJson);
      if (!mounted) return;

      setState(() {
        temperature = (data['temp'] ?? 0.0).toDouble();
        humidity = (data['humidity'] ?? 0.0).toDouble();
        tds = (data['tds'] ?? 0.0).toDouble();
        gas = data['gas'] ?? 0.0;

        if (tempHistory.length >= 10) {
          tempHistory.removeAt(0);
        }
        tempHistory.add(FlSpot(chartIndex.toDouble(), temperature));
        chartIndex++;
      });
    } catch (e) {
      debugPrint("❌ Lỗi phân tích cú pháp JSON MQTT: $e");
    }
  }

  Future<void> _handleNotificationRoute(Map<String, dynamic> data) async {
    if (!mounted) return;
    if (!data.containsKey('type')) {
      return;
    }

    final currentContext = context;
    if (!currentContext.mounted) return;

    String notiType = data['type'];
    switch (notiType) {
      case 'VACCINE':
        int? luagaId = int.tryParse(data['luaGaId']?.toString() ?? '');
        if (luagaId != null) {
          if (_luaGa != null && _luaGa!.id == luagaId) {
            if (!mounted || !currentContext.mounted) return;
            if (!await _ensureNetworkAvailable(currentContext)) return;
            Navigator.of(currentContext).push(
              MaterialPageRoute(
                builder: (context) =>
                    AnalyticsScreen(luaGa: _luaGa!, initTab: 3),
              ),
            );
          } else {
            showDialog(
              context: currentContext,
              barrierDismissible: false,
              builder: (dialogContext) => const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              ),
            );

            try {
              final luaGaFetched = await Apiservice.findLuaGaByID(
                luagaId,
                context: currentContext,
              );
              if (!mounted || !currentContext.mounted) return;
              if (Navigator.of(currentContext, rootNavigator: true).canPop()) {
                Navigator.of(currentContext, rootNavigator: true).pop();
              }

              if (luaGaFetched == null) return;

              if (!mounted || !currentContext.mounted) return;
              if (!await _ensureNetworkAvailable(currentContext)) return;
              Navigator.of(currentContext).push(
                MaterialPageRoute(
                  builder: (context) =>
                      AnalyticsScreen(luaGa: luaGaFetched, initTab: 3),
                ),
              );
            } catch (e) {
              if (mounted && currentContext.mounted) {
                if (Navigator.of(
                  currentContext,
                  rootNavigator: true,
                ).canPop()) {
                  Navigator.of(currentContext, rootNavigator: true).pop();
                }
              }
              debugPrint('❌ Lỗi khi lấy chi tiết lứa gà từ thông báo: $e');

              if (mounted && currentContext.mounted) {
                ScaffoldMessenger.of(currentContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Không thể tải thông tin đàn gà có ID: $luagaId',
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            }
          }
        } else {
          debugPrint(
            '❌ Lỗi: Không thể phân giải "luaGaId" thành kiểu số int. Giá trị nhận được: ${data['luaGaId']}',
          );
        }
        break;

      case 'GROWTH':
        int? luagaId = int.tryParse(data['luaGaId']?.toString() ?? '');
        if (luagaId != null) {
          if (_luaGa != null && _luaGa!.id == luagaId) {
            if (!mounted || !currentContext.mounted) return;
            if (!await _ensureNetworkAvailable(currentContext)) return;
            Navigator.of(currentContext).push(
              MaterialPageRoute(
                builder: (context) =>
                    AnalyticsScreen(luaGa: _luaGa!, initTab: 1),
              ),
            );
          } else {
            showDialog(
              context: currentContext,
              barrierDismissible: false,
              builder: (dialogContext) => const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              ),
            );

            try {
              final luaGaFetched = await Apiservice.findLuaGaByID(
                luagaId,
                context: currentContext,
              );
              if (!mounted || !currentContext.mounted) return;
              if (Navigator.of(currentContext, rootNavigator: true).canPop()) {
                Navigator.of(currentContext, rootNavigator: true).pop();
              }

              if (luaGaFetched == null) return;

              if (!mounted || !currentContext.mounted) return;
              if (!await _ensureNetworkAvailable(currentContext)) return;
              Navigator.of(currentContext).push(
                MaterialPageRoute(
                  builder: (context) =>
                      AnalyticsScreen(luaGa: luaGaFetched, initTab: 1),
                ),
              );
            } catch (e) {
              if (mounted && currentContext.mounted) {
                if (Navigator.of(
                  currentContext,
                  rootNavigator: true,
                ).canPop()) {
                  Navigator.of(currentContext, rootNavigator: true).pop();
                }
              }
              debugPrint('❌ Lỗi khi lấy chi tiết lứa gà từ thông báo: $e');

              if (mounted && currentContext.mounted) {
                ScaffoldMessenger.of(currentContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Không thể tải thông tin đàn gà có ID: $luagaId',
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            }
          }
        } else {
          debugPrint(
            '❌ Lỗi: Không thể phân giải "luaGaId" thành kiểu số int. Giá trị nhận được: ${data['luaGaId']}',
          );
        }
        break;

      case 'WARNNING':
        if (!mounted || !currentContext.mounted) return;
        showDialog(
          context: currentContext,
          builder: (dialogContext) => AlertDialog(
            title: const Text('⚠️ CẢNH BÁO!'),
            content: Text(
              data['content'] ?? 'Phát hiện sự cố bất thường tại chuồng nuôi!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('ĐÃ HIỂU'),
              ),
            ],
          ),
        );
        break;
    }
  }

  @override
  void dispose() {
    _mqttService.client?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    DailyFeedNutritionCard(luaGa: _luaGa),
                    const SizedBox(height: 10),
                    _buildHeroChartCard(),
                    const SizedBox(height: 20),
                    Text(
                      "Thông số chuồng trại thực tế",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey.shade900,
                      ),
                    ),
                    const SizedBox(height: 12,),
                  ],
                ),
              ),
            ),
            _buildSensorGrid(),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Dữ liệu từ chuồng trại.",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isMqttConnected
                          ? "Đang nhận dữ liệu MQTT"
                          : "Mất kết nối Broker",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),

            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.black87,
                      size: 26,
                    ),
                    onPressed: () async {
                      if (_currentLuaGaId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Đang tải lứa gà hiện tại. Vui lòng thử lại.',
                            ),
                            duration: Duration(seconds: 1),
                          ),
                        );
                        return;
                      }

                      if (!await _ensureNetworkAvailable(context)) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              NotificationPage(idLuaGa: _currentLuaGaId!),
                        ),
                      );
                    },
                  ),
                ),

                if (_unreadCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Center(
                        child: Text(
                          _unreadCount > 9 ? '9+' : '$_unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroChartCard() {
    return InkWell(
      onTap: () async {
        if (_luaGa == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Không thể mở phân tích. Thiết bị mất kết nối mạng hoặc dữ liệu chưa tải xong!",
              ),
              backgroundColor: Colors.amberAccent,
            ),
          );
          return;
        }
        if (!await _ensureNetworkAvailable(context)) return;

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AnalyticsScreen(luaGa: _luaGa!),
          ),
        );
      },
      borderRadius: BorderRadius.circular(24),
      splashColor: Colors.white.withOpacity(0.1),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF0D9488)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Biến động nhiệt độ thời gian thực",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white60,
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "$temperature°C",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 130,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: tempHistory,
                      isCurved: true,
                      color: Colors.amberAccent,
                      barWidth: 4,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorGrid() {
    Color tempCardColor = temperature >= 38.0
        ? Colors.redAccent
        : const Color(0xFFF97316);
    String tempStatus = temperature >= 38.0
        ? "Nguy hiểm (Quá nóng)"
        : "Ổn định";

    Color waterColor = tds > 300 ? Colors.amber : const Color(0xFF10B981);
    String waterStatus = tds > 300 ? "Nhiễm tạp chất nhẹ" : "Nước sạch";

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        delegate: SliverChildListDelegate([
          _buildSensorCard(
            title: "Nhiệt độ",
            value: "$temperature",
            unit: " °C",
            icon: Icons.thermostat_rounded,
            color: tempCardColor,
            status: tempStatus,
          ),
          _buildSensorCard(
            title: "Độ ẩm chuồng",
            value: "$humidity",
            unit: " %",
            icon: Icons.water_drop,
            color: const Color(0xFF0EA5E9),
            status: humidity < 61 ? "Ổn định" : "Ẩm ướt",
          ),
          _buildSensorCard(
            title: "Độ sạch của nước",
            value: "$tds",
            unit: " PPM",
            icon: Icons.opacity_rounded,
            color: waterColor,
            status: waterStatus,
          ),
          _buildSensorCard(
            title: "Nồng độ khí độc",
            value: "$gas",
            unit: " PPM",
            icon: Icons.dangerous_outlined,
            color: gas < 3000 ? Colors.teal : Colors.red,
            status: gas < 3000 ? "Ổn định" : "Có nhiều khí độc",
          ),
        ]),
      ),
    );
  }

  Widget _buildSensorCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Expanded(
                child: Text(
                  status,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            textBaseline: TextBaseline.alphabetic,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey.shade900,
                ),
              ),
              Text(
                unit,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
