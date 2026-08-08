import 'package:flutter/material.dart';
import 'package:smart_chicken_farming/page/LoginScreen.dart';
import 'package:url_launcher/url_launcher.dart';

class SystemIntroductionScreen extends StatefulWidget {
  const SystemIntroductionScreen({Key? key}) : super(key: key);

  @override
  _SystemIntroductionScreenState createState() =>
      _SystemIntroductionScreenState();
}

class _SystemIntroductionScreenState extends State<SystemIntroductionScreen> {
  int _subStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _subStep == 0
              ? 'Giới Thiệu Hệ Thống'
              : (_subStep == 1 ? 'Giải Pháp Thông Minh' : 'Tóm Tắt Tổng Quan'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
            color: Colors.white
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo[800],
        elevation: 0,
        actions: [
        IconButton(
          icon: const Row(
            children: [
              Icon(Icons.login, color: Colors.white),
            ],
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
        ),
      ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.indigo[900],
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (_subStep + 1) / 3,
                      minHeight: 8,
                      backgroundColor: Colors.indigo[700],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.amber,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Bước ${_subStep + 1}/3',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildCurrentStep(context)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_subStep > 0)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _subStep = (_subStep - 1).clamp(0, 2);
                      });
                    },
                    child: const Text(
                      'Quay lại',
                      style: TextStyle(
                        color: Colors.indigo,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 90),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[800],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  onPressed: () async{
                    if (_subStep < 2) {
                      setState(() => _subStep = _subStep + 1);
                    } else {
                      final zaloUri=Uri.parse('https://zalo.me/0387245690');
                      if(await canLaunchUrl(zaloUri)){
                        await launchUrl(zaloUri,mode: LaunchMode.externalApplication);
                      }else{
                        final Uri phoneUri =Uri(scheme: 'tel',path: '0387245690');
                        if(await canLaunchUrl(phoneUri)){
                          await launchUrl(phoneUri);
                        }
                      }
                    }
                  },
                  child: Text(
                    _subStep == 0
                        ? 'Xem giải pháp'
                        : (_subStep == 1 ? 'Xem tóm tắt' : 'Nhận tư vấn'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Hàm gom logic render 3 trạng thái giới thiệu cốt lõi
  Widget _buildCurrentStep(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _subStep == 0
          ? _buildRiskSection()
          : (_subStep == 1 ? _buildSolutionSection() : _buildSummarySection()),
    );
  }

  Widget _buildRiskSection() {
    return Container(
      key: const ValueKey('risk'),
      color: Colors.grey[50],
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            const Text(
              'Rủi ro môi trường tác động trực tiếp đến đàn gà',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Khí hậu biến đổi, chất lượng môi trường trong chuồng nuôi thay đổi, nước không sạch và thức ăn không đủ chuẩn đều khiến gà chậm lớn, giảm miễn dịch và dễ mắc bệnh.',
              style: TextStyle(
                fontSize: 15.2,
                height: 1.7,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            _RiskCard(
              icon: Icons.cloud,
              title: 'Thay đổi môi trường',
              description:
                  'Nhiệt độ và độ ẩm thay đổi do nhiều tác nhân bên trong chuồng nuôi cùng với khí độc sản sinh trong suốt quá trình nuôi gây stress, ngộ độc cho gà, giảm tăng trưởng và tăng nguy cơ dịch bệnh.',
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 16),
            _RiskCard(
              icon: Icons.water_drop,
              title: 'Nguồn nước không ổn định',
              description:
                  'Nước sạch là một trong những thành phần thiết yếu để tạo nên một đàn gà chất lượng. Nước ô nhiễm hoặc thiếu nước khiến đàn gà yếu, dễ nhiễm bệnh và giảm sức đề kháng.',
              color: Colors.teal,
            ),
            const SizedBox(height: 16),
            _RiskCard(
              icon: Icons.restaurant,
              title: 'Thức ăn chưa chuẩn',
              description:
                  'Cấp thiếu hoặc thừa lượng thức ăn cần thiết dẫn đến lãng phí, tăng chi phí và giảm hiệu quả nuôi.',
              color: Colors.orangeAccent,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.indigo[900],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: const Text(
                'Nhận diện các yếu tố môi trường là bước đầu tiên để giữ đàn gà khỏe mạnh và ổn định năng suất.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSolutionSection() {
    return Container(
      key: const ValueKey('solution'),
      color: Colors.grey[50],
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            const Text(
              'Giải pháp thông minh cho trại nuôi gà thương phẩm',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Châm ngôn nuôi gà thịt tiêu chuẩn từ trước đến nay là: "Môi trường sạch + Thức ăn sạch + Nước sạch = Chất lượng thịt sạch". Tự động hóa việc điều chỉnh môi trường, nguồn nước và thức ăn trong suốt quá trình chăn nuôi giúp phát hiện sớm và ngăn chặn rủi ro trước khi chúng biến thành tổn thất.',
              style: TextStyle(
                fontSize: 15.2,
                height: 1.7,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            _SolutionCard(
              icon: Icons.watch_later,
              title: 'Giám sát 24/7',
              description:
                  'Quan sát liên tục các chỉ số môi trường để phản ứng ngay khi có bất thường. Hệ thống sẽ liên tục giám sát và điều chỉnh các chỉ số môi trường sao cho phù hợp với từng giai đoạn chăn nuôi giúp đàn gà có một môi trường sống lý tưởng. Từ đó mà chất lượng sẽ tăng lên.',
              color: Colors.indigo,
            ),
            const SizedBox(height: 16),
            _SolutionCard(
              icon: Icons.opacity,
              title: 'Kiểm soát nước tự động',
              description:
                  'Giám sát mực nước, chất lượng nước trước khi đưa vào chăn nuôi. Điều này rất quan trọng vì hệ thống sẽ phát hiện sớm khi hết nước dự trữ hay khi chất lượng nước không đạt tiêu chuẩn dành cho đàn gà để nhanh chóng có biện pháp xử lý.',
              color: Colors.teal,
            ),
            const SizedBox(height: 16),
            _SolutionCard(
              icon: Icons.no_food,
              title: 'Phân phối thức ăn chính xác',
              description:
                  'Cấp thức ăn đúng định lượng theo nhu cầu đàn gà trong từng giai đoạn tuổi khác nhau, tránh lãng phí và thiếu dinh dưỡng. Thêm vào đó là sự giám sát silo cám trong môi trường nuôi khép kín nhằm tránh việc hỏng hóc động cơ khi hết thức ăn dự trữ trong silo cám đó.',
              color: Colors.deepOrange,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.indigo.shade100),
              ),
              padding: const EdgeInsets.all(20),
              child: const Text(
                'Kết hợp giám sát dữ liệu và hành động tự động giúp trại gà vận hành hiệu quả, giảm thiểu rủi ro và tăng tỉ lệ thành công. Hệ thống ứng dụng khoa học và công nghệ vào chăn nuôi giúp người dùng dễ dàng theo dõi các chỉ số môi trường và nhận các thông báo khẩn cấp để kịp xử lý tránh để lại hậu quả đáng tiếc trong quá trình nuôi.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      key: const ValueKey('summary'),
      color: Colors.grey[50],
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF373B73), Color(0xFF4F85D1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.25),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Trang trại gà an toàn hơn với công nghệ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Giải pháp giúp bạn kiểm soát rủi ro khí hậu, nước và thức ăn bằng dữ liệu thực tế và phản hồi tự động.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Bạn sẽ có:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            const _BenefitBullet(
              text: 'Ổn định môi trường nuôi trong mọi điều kiện.',
            ),
            const _BenefitBullet(
              text: 'Kiểm soát nước và thức ăn tự động, chính xác.',
            ),
            const _BenefitBullet(
              text: 'Cảnh báo tức thì khi xuất hiện bất thường.',
            ),
            const _BenefitBullet(text: 'Giảm bớt sức lao động trong chăn nuôi.'),
            const _BenefitBullet(text: 'Tạo ra đàn gà thương phẩm chất lượng cao.'),
            const SizedBox(height: 24),
            const Text(
              'Hệ thống giúp người nuôi giảm bớt giám sát thủ công và tập trung vào vận hành thông minh hơn.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _RiskCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _RiskCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
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
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14.2,
                    color: Colors.black54,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SolutionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _SolutionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
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
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14.2,
                    color: Colors.black54,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitBullet extends StatelessWidget {
  final String text;

  const _BenefitBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.check_circle, color: Colors.indigo, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
