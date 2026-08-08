import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  String? id;
  String? email;

  Future<void> saveSession(String userId, String userEmail) async {
    id = userId;
    email = userEmail;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_user_id', userId);
    await prefs.setString('saved_user_email', userEmail);
    print("💾 Đã lưu session vào máy: $userId");
  }

  Future<bool> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedId = prefs.getString('saved_user_id');
    String? savedEmail = prefs.getString('saved_user_email');

    if (savedId != null && savedEmail != null) {
      id = savedId;
      email = savedEmail;
      print("🔄 Đã khôi phục session từ bộ nhớ máy: $id");
      return true; 
    }
    return false; 
  }

  Future<void> clearSession() async {
    id = null;
    email = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_user_id');
    await prefs.remove('saved_user_email');
    print("🧹 Đã xóa sạch session trên máy.");
  }
}

final userSession = UserSession();