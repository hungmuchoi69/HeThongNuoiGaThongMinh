import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MqttService {
  static final MqttService _instance = MqttService._internal();

  factory MqttService() {
    return _instance;
  }

  MqttService._internal();

  MqttServerClient? client;

  Stream<List<MqttReceivedMessage<MqttMessage>>>? get messageStream =>
      client?.updates?.asBroadcastStream();

  Future<bool> connect() async {
    String clientId = 'flutter_user_${DateTime.now().millisecondsSinceEpoch}';
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return false;
    }
    String uId = user.id;
    String sensorTopic = "chuong_ga/users/$uId/sensors";
    String notiTopic = "chuong_ga/users/$uId/notifications";

    client = MqttServerClient('broker.emqx.io', clientId); 
    client!.port = 1883;
    client!.keepAlivePeriod = 20;
    client!.secure = false;
    client!.logging(on: false);
    client!.autoReconnect = true;

    client!.onDisconnected = () {
      print('🔒 MQTT_LOG: Mất kết nối ngầm với Broker!');
    };
    client!.onConnected = () {
      print('🔓 MQTT_LOG: Kết nối lại thành công, tự động Re-subscribe!');
      client!.subscribe(sensorTopic, MqttQos.atLeastOnce);
      client!.subscribe(notiTopic, MqttQos.atLeastOnce);
    };

    client!.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .withProtocolName('MQTT')
        .withProtocolVersion(4) 
        .startClean(); 

    try {
      print("🔄 Đang thiết lập kết nối MQTT ban đầu...");
      await client!.connect();

      if (client!.connectionStatus?.state == MqttConnectionState.connected) {
        print("🎯 KẾT NỐI MQTT BROKER THÀNH CÔNG!");
        client!.subscribe(sensorTopic, MqttQos.atLeastOnce);
        client!.subscribe(notiTopic, MqttQos.atLeastOnce);
        return true;
      }
      return false;
    } catch (e) {
      print("❌ Lỗi kết nối MQTT: $e");
      return false;
    }
  }

  void publishMessage(String topic, String mess) async {
    if (client?.connectionStatus?.state == MqttConnectionState.connected) {
      _executePublish(topic, mess);
      return;
    }

    print("⚠️ Phát hiện mất kết nối! Đang khôi phục đường truyền ngầm trước khi gửi lệnh...");
    try {
      bool isReconnected = await connect();
      if (isReconnected && client?.connectionStatus?.state == MqttConnectionState.connected) {
        _executePublish(topic, mess);
      } else {
        print("❌ Khôi phục kết nối thất bại. Không thể gửi lệnh: $mess");
      }
    } catch (e) {
      print("❌ Lỗi trong quá trình khôi phục và gửi lệnh: $e");
    }
  }

  void _executePublish(String topic, String mess) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(mess);
    print('🚀 [MQTT SEND] Topic: $topic -> Payload: $mess');
    client!.publishMessage(topic, MqttQos.atMostOnce, builder.payload!); 
  }
}