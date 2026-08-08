import 'package:shared_preferences/shared_preferences.dart';

class SnoozeService {
  static const String _prefix = "snooze_alert_";

  /// Lưu thời gian tạm dừng cho 1 loại sự cố
  static Future<bool> setSnooze(String alertType, {int minutes = 15}) async {
    final prefs = await SharedPreferences.getInstance();
    final expireTime = DateTime.now().add(Duration(minutes: minutes)).millisecondsSinceEpoch;
    
    // Dùng reload() để sync bộ nhớ với disk khi chạy ở Background Isolate
    await prefs.reload();
    
    // Lưu và ép ghi ngay lập tức
    bool success = await prefs.setInt('$_prefix$alertType', expireTime);
    print("💾 [SnoozeService] Đã lưu $_prefix$alertType = $expireTime | Thành công: $success");
    return success;
  }

  /// Kiểm tra xem loại sự cố này có đang trong thời gian Snooze hay không
  static Future<bool> isSnoozed(String alertType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    
    final expireTime = prefs.getInt('$_prefix$alertType');
    print("🔍 [SnoozeService] Kiểm tra key [$_prefix$alertType] -> ExpireTime: $expireTime");

    if (expireTime == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now < expireTime) {
      print("⏳ [SnoozeService] Còn trong thời hạn Snooze (${(expireTime - now) ~/ 1000}s còn lại)");
      return true;
    } else {
      await prefs.remove('$_prefix$alertType');
      print("⌛ [SnoozeService] Đã hết hạn Snooze -> Đã xóa Key");
      return false;
    }
  }
}