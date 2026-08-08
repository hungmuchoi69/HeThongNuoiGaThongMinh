import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_chicken_farming/img/AppImage.dart';
import 'package:smart_chicken_farming/page/SystemIntroductionScreen.dart';

class WelcomeGuideScreen extends StatelessWidget {
  const WelcomeGuideScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "SMART CHICKEN FARMING",
          style: GoogleFonts.bebasNeue(letterSpacing: 2, fontSize: 24),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.indigo,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SystemIntroductionScreen(),
            ),
          );
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Image.network(
                  Appimage.imgSmartFarmUrl,
                  height: 170,
                  width: 500,
                  fit: BoxFit.contain,
                  loadingBuilder:
                      (
                        BuildContext context,
                        Widget child,
                        ImageChunkEvent? loadingProgress,
                      ) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },

                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      color: Colors.grey[100],
                      alignment: Alignment.center,
                      child: const Text(
                        "Không thể tải hình ảnh, vui lòng kiểm tra Intenet!",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    );
                  },
                ),
                const Spacer(),
                const Text(
                  "HỆ THỐNG CHĂN NUÔI GÀ KHÉP KÍN THÔNG MINH",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Giải pháp IoT chuyên dụng cho mô hình chuồng trại chăn nuôi gà công nghiệp khép kín, tối ưu hóa môi trường nuôi dưỡng cho các dòng gà thương phẩm trong suốt quá trình chăn nuôi. Hệ thống tự động giám sát và điều chỉnh môi trường sống phù hợp, kiểm soát lượng thức ăn, nguồn nước theo thời gian thực và đồng hành cùng với bạn để có được 1 đàn gà chất lượng.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      "Chạm vào màn hình để đến bước tiếp theo",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(Icons.touch_app, color: Colors.grey, size: 18),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
