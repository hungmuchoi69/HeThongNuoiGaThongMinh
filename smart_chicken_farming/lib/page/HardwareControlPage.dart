import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_chicken_farming/model/LuaGa.dart';
import 'package:smart_chicken_farming/model/TieuChuanPhatTrien.dart';
import 'dart:convert';
import 'package:smart_chicken_farming/service/UserSession.dart';
import 'package:smart_chicken_farming/service/mqttService.dart';

class HardwareControlPage extends StatefulWidget {
  final int ngayTuoi;
  final LuaGa luaGa;
  final Tieuchuanphattrien tieuchuanphattrien;
  final bool isManualMode;
  final ValueChanged<bool> onManualChanged;

  const HardwareControlPage({
    Key? key,
    required this.ngayTuoi,
    required this.luaGa,
    required this.tieuchuanphattrien,
    required this.isManualMode,
    required this.onManualChanged,
  }) : super(key: key);

  @override
  State<HardwareControlPage> createState() => _HardwareControlPageState();
}

class _HardwareControlPageState extends State<HardwareControlPage>
    with AutomaticKeepAliveClientMixin<HardwareControlPage> {
  final MqttService _mqttService = MqttService();
  StreamSubscription? _mqttSubscription;

  final TextEditingController _tempMinController = TextEditingController(
    text: "22.0",
  );
  final TextEditingController _tempMaxController = TextEditingController(
    text: "32.0",
  );

  double nhietDoTCMin = 22.0;
  double nhietDoTCMax = 32.0;

  late bool isManualModeLocal;
  static bool isLightOn = false;
  static bool isFanOn = false;
  static bool isLampOn = false;

  // Trạng thái Switch
  bool isCustomSchedule = false;

  // Cờ đánh dấu trạng thái mong muốn của Switch (chờ ESP32 phản hồi đúng mới đồng bộ Switch)
  bool? _pendingCustomSchedule;

  int lightStartHour = 6;
  int lightEndHuor = 22;

  double currentTemp = 34.5;
  int currentGas = 450;

  void sendMqttCommand(
    String mode, {
    String? status,
    String? device,
    int? lightStartHour,
    int? lightEndHour,
    List<String>? timers,
    int? feedWeight,
    bool? isCustom,
    double? tempMin,
    double? tempMax,
  }) {
    final Map<String, dynamic> commandPayload = {"mode": mode};

    if (mode == "MANUAL" && device != null && status != null) {
      commandPayload["device"] = device;
      commandPayload["status"] = status;
    } else if (mode == "SET_LIGHT") {
      commandPayload["sender"] = "USER";
      commandPayload["isCustomSchedule"] = isCustom ?? isCustomSchedule;
      if (lightStartHour != null) commandPayload["lightStartHour"] = lightStartHour;
      if (lightEndHour != null) commandPayload["lightEndHour"] = lightEndHour;
      if (tempMin != null) commandPayload["nhietDoTCMin"] = tempMin;
      if (tempMax != null) commandPayload["nhietDoTCMax"] = tempMax;
    }

    String jsonString = jsonEncode(commandPayload);

    _mqttService.publishMessage(
      "chuong_ga/users/${userSession.id}/controls",
      jsonString,
    );
    print("LOG FLUTTER: Đã gửi lệnh -> $jsonString");
  }

  void _handleDeviceControl(
    String deviceName,
    bool currentValue,
    VoidCallback onConfirm,
  ) {
    String warningMessage = "";
    bool needWarning = false;

    if (deviceName == "Quạt hút thông gió" &&
        currentValue &&
        (currentTemp > widget.tieuchuanphattrien.nhiet_do_toi_da ||
            currentGas > 1500)) {
      needWarning = true;
      warningMessage =
          "Cảnh báo! Chỉ số Khí Gas hoặc Nhiệt độ chuồng đang ở mức báo động. Tắt quạt hút lúc này có thể gây ngạt hoặc quá nhiệt cho vật nuôi.";
    } else if (deviceName == "manual" && !currentValue) {
      needWarning = true;
      warningMessage =
          "Cảnh báo! Nếu chuyển sang chế độ điều khiển thủ công thì hệ thống sẽ không tự động xử lý nếu thông số môi trường không phù hợp.";
    } else if (deviceName == "Quạt hút thông gió" &&
        !currentValue &&
        (currentTemp < widget.tieuchuanphattrien.nhiet_do_toi_thieu)) {
      needWarning = true;
      warningMessage =
          "Cảnh báo! Chỉ số Nhiệt độ chuồng đang ở mức thấp hơn nhiệt độ phù hợp. Bật quạt hút lúc này có thể gây lạnh hoặc thiếu nhiệt cho vật nuôi.";
    } else if (deviceName == "schedule" && !currentValue) {
      needWarning = true;
      warningMessage =
          "Thời gian chiếu sáng và nhiệt độ tiêu chuẩn đã được hệ thống tự động lên kế hoạch thích hợp dựa theo ngày tuổi của gà, nếu thay đổi có thể sẽ gây ảnh hưởng đến quá trình chăn nuôi!";
    } else if (deviceName == "Đèn sưởi" &&
        !currentValue &&
        currentTemp > widget.tieuchuanphattrien.nhiet_do_toi_thieu) {
      needWarning = true;
      warningMessage =
          "Bật bóng sưởi sẽ làm gia tăng nhiệt độ của chuồng và nó sẽ gây ảnh hưởng đến sức khỏe đàn gà! Hãy cẩn trận khi bật đèn sưởi";
    }

    if (needWarning) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                SizedBox(width: 10),
                Text(
                  "CẢNH BÁO",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(warningMessage, style: const TextStyle(fontSize: 15)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  "HỦY BỎ",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm();
                },
                child: const Text(
                  "VẪN TIẾP TỤC",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
    } else {
      onConfirm();
    }
  }

  void _langNgheDuLieu() {
    _mqttSubscription = _mqttService.messageStream?.listen((
      List<MqttReceivedMessage<MqttMessage>> mess,
    ) async {
      try {
        final String curTopic = mess[0].topic;
        if (curTopic.contains("sensors")) {
          final MqttPublishMessage recMess =
              mess[0].payload as MqttPublishMessage;
          final String payload = MqttPublishPayload.bytesToStringAsString(
            recMess.payload.message,
          );
          final Map<String, dynamic> data = jsonDecode(payload);

          if (!mounted) return;

          setState(() {
            if (data.containsKey("temp")) currentTemp = data["temp"].toDouble();
            if (data.containsKey("gas")) currentGas = data["gas"].toInt();

            if (data.containsKey("isManualControl")) {
              isManualModeLocal = (data["isManualControl"] == 1);
            }
            if (data.containsKey("lightStartHour")) {
              lightStartHour = data["lightStartHour"];
              lightEndHuor = data["lightEndHour"];
            }

            if (data.containsKey("nhietDoTCMin")) {
              nhietDoTCMin = data["nhietDoTCMin"].toDouble();
              _tempMinController.text = nhietDoTCMin.toString();
            }
            if (data.containsKey("nhietDoTCMax")) {
              nhietDoTCMax = data["nhietDoTCMax"].toDouble();
              _tempMaxController.text = nhietDoTCMax.toString();
            }

            if (data.containsKey("isUserOverride")) {
              bool espOverrideState = (data["isUserOverride"] == 1);

              if (_pendingCustomSchedule != null) {
                if (espOverrideState == _pendingCustomSchedule) {
                  isCustomSchedule = espOverrideState;
                  _pendingCustomSchedule = null;
                }
              } else {
                isCustomSchedule = espOverrideState;
              }
            }
            
            if (!isManualModeLocal) {
              if (data.containsKey("lightStatus")) {
                isLightOn = data["lightStatus"] == 1;
              }
              if (data.containsKey("fanStatus")) {
                isFanOn = data["fanStatus"] == 1;
              }
              if (data.containsKey("lampStatus")) {
                isLampOn = data["lampStatus"] == 1;
              }
            }
          });
        }
      } catch (e) {
        print("Lỗi lắng nghe MQTT: $e");
      }
    });
  }

  Future<void> _selectTime(BuildContext context, bool isLightStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: isLightStart ? lightStartHour : lightEndHuor,
        minute: 0,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isLightStart) {
          lightStartHour = picked.hour;
        } else {
          lightEndHuor = picked.hour;
        }
      });
    }
  }

  void _thietLapTrangThaiTheoNgayTuoi(int tuoi) {
    if (tuoi < 22) {
      lightStartHour = 2;
      lightEndHuor = 23;
    } else if (tuoi < 57) {
      lightStartHour = 5;
      lightEndHuor = 23;
    } else {
      lightStartHour = 7;
      lightEndHuor = 21;
    }

    nhietDoTCMin = widget.tieuchuanphattrien.nhiet_do_toi_thieu;
    nhietDoTCMax = widget.tieuchuanphattrien.nhiet_do_toi_da;
    _tempMinController.text = nhietDoTCMin.toString();
    _tempMaxController.text = nhietDoTCMax.toString();
  }

  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('cfg_lightStart')) {
      setState(() {
        lightStartHour = prefs.getInt('cfg_lightStart') ?? lightStartHour;
        lightEndHuor = prefs.getInt('cfg_lightEnd') ?? lightEndHuor;
        isCustomSchedule = prefs.getBool('cfg_isCustom') ?? false;
      });
    } else {
      _thietLapTrangThaiTheoNgayTuoi(widget.ngayTuoi);
    }
  }

  String? _validateTemperatureInputs(double minT, double maxT) {
    if (minT < 22.0) {
      return "Nhiệt độ tối thiểu không được dưới 18°C (Gà sẽ bị sốc lạnh/sưng phổi)!";
    }
    if (maxT > 36.0) {
      return "Nhiệt độ tối đa không được vượt quá 38°C (Gà có nguy cơ tử vong do quá nhiệt)!";
    }
    if (minT >= maxT) {
      return "Nhiệt độ Min phải nhỏ hơn Nhiệt độ Max!";
    }
    if (maxT - minT < 2.0) {
      return "Khoảng cách giữa Min và Max phải ít nhất là 2°C để thiết bị không bị bật/tắt liên tục!";
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    isManualModeLocal = widget.isManualMode;

    nhietDoTCMin = widget.tieuchuanphattrien.nhiet_do_toi_thieu;
    nhietDoTCMax = widget.tieuchuanphattrien.nhiet_do_toi_da;
    _tempMinController.text = nhietDoTCMin.toString();
    _tempMaxController.text = nhietDoTCMax.toString();

    _loadLocalSettings();
    _langNgheDuLieu();
  }

  @override
  void didUpdateWidget(covariant HardwareControlPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isManualMode != widget.isManualMode) {
      setState(() {
        isManualModeLocal = widget.isManualMode;
      });
    }
  }

  @override
  void dispose() {
    _tempMinController.dispose();
    _tempMaxController.dispose();
    _mqttSubscription?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      colors: isManualModeLocal
                          ? [Colors.orangeAccent, Colors.orange]
                          : [Colors.blueAccent, Colors.teal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isManualModeLocal
                                ? "CHẾ ĐỘ THỦ CÔNG"
                                : "CHẾ ĐỘ TỰ ĐỘNG",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isManualModeLocal
                                ? "Hệ thống cho phép can thiệp thủ công"
                                : "Hệ thống đang chạy tự động",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: isManualModeLocal,
                        activeColor: Colors.white,
                        activeTrackColor: Colors.deepOrange,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.blueGrey[800],
                        onChanged: (value) {
                          _handleDeviceControl("manual", isManualModeLocal, () {
                            setState(() {
                              isManualModeLocal = value;
                            });
                            widget.onManualChanged(value);
                            sendMqttCommand(value ? "MANUAL" : "AUTO");
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),

              Row(
                children: [
                  const Text(
                    "BẢNG ĐIỀU KHIỂN THIẾT BỊ",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  if (!isManualModeLocal)
                    const Text(
                      "🔒 Đang khóa (Chế độ Auto)",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              _buildDeviceControlCard(
                title: "Đèn chiếu sáng",
                subtitle: isLightOn ? "Đèn đang bật thủ công" : "Đèn đang tắt",
                icon: Icons.lightbulb,
                iconColor: Colors.amber,
                isActive: isLightOn,
                isEnabled: isManualModeLocal,
                onChanged: (value) {
                  if (!isManualModeLocal) return;
                  _handleDeviceControl("Đèn chiếu sáng", isLightOn, () {
                    setState(() {
                      isLightOn = value;
                      sendMqttCommand(
                        "MANUAL",
                        device: "LIGHT",
                        status: isLightOn ? "ON" : "OFF",
                      );
                    });
                  });
                },
              ),

              _buildDeviceControlCard(
                title: "Quạt hút thông gió",
                subtitle: isFanOn ? "Quạt đang quay thủ công" : "Quạt đang tắt",
                icon: Icons.wind_power,
                iconColor: Colors.teal,
                isActive: isFanOn,
                isEnabled: isManualModeLocal,
                onChanged: (value) {
                  if (!isManualModeLocal) return;
                  _handleDeviceControl("Quạt hút thông gió", isFanOn, () {
                    setState(() {
                      isFanOn = value;
                      sendMqttCommand(
                        "MANUAL",
                        device: "FAN",
                        status: isFanOn ? "ON" : "OFF",
                      );
                    });
                  });
                },
              ),

              _buildDeviceControlCard(
                title: "Đèn sưởi",
                subtitle: isLampOn ? "Đèn sưởi đang bật" : "Đèn sưởi đang tắt",
                icon: Icons.thermostat_rounded,
                iconColor: Colors.redAccent,
                isActive: isLampOn,
                isEnabled: isManualModeLocal,
                onChanged: (value) {
                  if (!isManualModeLocal) return;
                  _handleDeviceControl("Đèn sưởi", isLampOn, () {
                    setState(() {
                      isLampOn = value;
                      sendMqttCommand(
                        "MANUAL",
                        device: "LAMP",
                        status: isLampOn ? "ON" : "OFF",
                      );
                    });
                  });
                },
              ),

              const SizedBox(height: 25),
              const Text(
                "CẤU HÌNH THỜI GIAN CHIẾU SÁNG & NHIỆT ĐỘ",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              _buildScheduleConfigCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceControlCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isActive,
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: isActive ? 4 : 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isActive
                    ? iconColor.withOpacity(0.15)
                    : Colors.grey[200],
                radius: 24,
                child: Icon(
                  icon,
                  color: isActive ? iconColor : Colors.grey,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isActive ? iconColor : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isActive,
                onChanged: isEnabled ? onChanged : null,
                activeColor: iconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleConfigCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: isCustomSchedule ? Colors.purple : Colors.teal,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Áp dụng chuẩn theo ngày tuổi",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: !isCustomSchedule,
                  activeColor: Colors.teal,
                  onChanged: (value) {
                    _handleDeviceControl("schedule", isCustomSchedule, () async {
                      bool targetCustomState = !value;

                      setState(() {
                        isCustomSchedule = targetCustomState;
                        _pendingCustomSchedule =
                            targetCustomState; // Lưu trạng thái đang chờ ESP32 ACK
                      });

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('cfg_isCustom', targetCustomState);

                      if (!targetCustomState) {
                        _thietLapTrangThaiTheoNgayTuoi(widget.ngayTuoi);
                        sendMqttCommand(
                          "SET_LIGHT",
                          lightStartHour: lightStartHour,
                          lightEndHour: lightEndHuor,
                          isCustom: false,
                          tempMin: widget.tieuchuanphattrien.nhiet_do_toi_thieu,
                          tempMax: widget.tieuchuanphattrien.nhiet_do_toi_da,
                        );
                      } else {
                        sendMqttCommand(
                          "SET_LIGHT",
                          lightStartHour: lightStartHour,
                          lightEndHour: lightEndHuor,
                          isCustom: true,
                          tempMin:
                              double.tryParse(_tempMinController.text) ??
                              nhietDoTCMin,
                          tempMax:
                              double.tryParse(_tempMaxController.text) ??
                              nhietDoTCMax,
                        );
                      }
                    });
                  },
                ),
              ],
            ),
            const Divider(height: 20),
            const Text(
              "💡 Thời gian chiếu sáng",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            if (lightStartHour == lightEndHuor) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.wb_incandescent_rounded,
                      color: Colors.amber[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Chưa cần sử dụng hệ thống chiếu sáng (Giai đoạn úm gà)",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        disabledForegroundColor: Colors.black54,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: isCustomSchedule
                          ? () => _selectTime(context, true)
                          : null,
                      icon: const Icon(Icons.wb_sunny_outlined, size: 18),
                      label: Text(
                        "Bật: ${lightStartHour.toString().padLeft(2, '0')}:00",
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        disabledForegroundColor: Colors.black54,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: isCustomSchedule
                          ? () => _selectTime(context, false)
                          : null,
                      icon: const Icon(
                        Icons.nightlight_round_outlined,
                        size: 18,
                      ),
                      label: Text(
                        "Tắt: ${lightEndHuor.toString().padLeft(2, '0')}:00",
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (isCustomSchedule) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 5),
              const Text(
                "🌡️ Cấu hình ngưỡng Nhiệt độ (°C)",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tempMinController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: "Nhiệt độ Min",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _tempMaxController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: "Nhiệt độ Max",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    final double? minT = double.tryParse(
                      _tempMinController.text,
                    );
                    final double? maxT = double.tryParse(
                      _tempMaxController.text,
                    );

                    if (minT == null || maxT == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.red,
                          content: Text(
                            "⚠️ Vui lòng nhập đúng định dạng số cho nhiệt độ!",
                          ),
                        ),
                      );
                      return;
                    }

                    String? errorMsg = _validateTemperatureInputs(minT, maxT);
                    if (errorMsg != null) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                                size: 28,
                              ),
                              SizedBox(width: 8),
                              Text("CẢNH BÁO AN TOÀN"),
                            ],
                          ),
                          content: Text(errorMsg),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("ĐÃ HỂU"),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    sendMqttCommand(
                      "SET_LIGHT",
                      lightStartHour: lightStartHour,
                      lightEndHour: lightEndHuor,
                      isCustom: true,
                      tempMin: minT,
                      tempMax: maxT,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.green,
                        content: Text(
                          "🚀 Đã lưu và áp dụng cài đặt nhiệt độ mới!",
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text(
                    "ÁP DỤNG CẤU HÌNH TÙY CHỈNH",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
