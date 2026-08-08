import 'package:flutter/material.dart';
import 'package:smart_chicken_farming/page/WelcomeGuideScreen.dart';
import 'package:smart_chicken_farming/page/HomePage.dart';
import 'package:smart_chicken_farming/service/APIService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Authcheckscreen extends StatefulWidget {
  const Authcheckscreen({super.key});

  @override
  State<StatefulWidget> createState() => _AuthCheckSreenState();
}

class _AuthCheckSreenState extends State<Authcheckscreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  void _checkAuth() async {
    await Future.delayed(const Duration(microseconds: 250));
    if (!mounted) return;
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        // Kiểm tra xem có lứa đang RAISING hay không
        try {
          final luaGa = await Apiservice.findByUserIdAndTrangThai(
            currentUser.id,
            "RAISING",
            context: context,
          );
          if (!mounted) return;
          if (luaGa == null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const WelcomeGuideScreen(),
              ),
            );
            return;
          }
        } catch (e) {
          // Nếu có lỗi khi gọi API, fallback về HomePage để người dùng vẫn vào app
          debugPrint('❌ Lỗi khi kiểm tra lứa gà RAISING: $e');
        }
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeGuideScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
