import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart'; 
import 'package:smart_chicken_farming/service/UserSession.dart';
import 'WelcomeGuideScreen.dart';

class LivestockSummaryScreen extends StatefulWidget {
  final double profit;
  final double totalCost;
  final double revenue;
  final double survivalRate;

  const LivestockSummaryScreen({
    super.key,
    required this.profit,
    required this.totalCost,
    required this.revenue,
    required this.survivalRate,
  });

  @override
  State<LivestockSummaryScreen> createState() => _LivestockSummaryScreenState();
}

class _LivestockSummaryScreenState extends State<LivestockSummaryScreen> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    bool isProfit = widget.profit > 0;

    _confettiController = ConfettiController(duration: const Duration(seconds: 4));

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    if (isProfit) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
  void _exitAndResetSession() {
    UserSession().clearSession();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeGuideScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isProfit = widget.profit > 0;

    return Scaffold(
      body: GestureDetector(
        onTap: _exitAndResetSession,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isProfit
                      ? [Colors.green.shade900, Colors.greenAccent.shade700, Colors.green.shade900]
                      : [Colors.blueGrey.shade900, Colors.blueGrey.shade700, Colors.blueGrey.shade900],
                ),
              ),
            ),
            if (isProfit)
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: pi / 2, 
                  maxBlastForce: 10, 
                  minBlastForce: 2, 
                  emissionFrequency: 0.05,
                  numberOfParticles: 20, 
                  gravity: 0.2, 
                  shouldLoop: true, 
                  colors: const [
                    Colors.green,
                    Colors.blue,
                    Colors.pink,
                    Colors.orange,
                    Colors.purple,
                    Colors.amber
                  ], 
                ),
              ),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),

                      isProfit
                          ? TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0.0, end: 1.2),
                              duration: const Duration(milliseconds: 600),
                              builder: (context, double val, child) {
                                return Transform.scale(
                                  scale: val,
                                  child: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 100),
                                );
                              },
                            )
                          : const Icon(Icons.sentiment_neutral_rounded, color: Colors.orangeAccent, size: 90),

                      const SizedBox(height: 20),

                      Text(
                        isProfit ? "XUẤT CHUỒNG THÀNH CÔNG!" : "KẾT THÚC VỤ CHĂN NUÔI",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        isProfit
                            ? "Chúc mừng bạn! Lứa gà chăn nuôi đạt hiệu quả kinh tế rất xuất sắc. Hãy tiếp tục phát huy ở lứa sau nhé!"
                            : "Vụ nuôi này chưa đem lại lợi nhuận như kỳ vọng. Đừng nản lòng, những kinh nghiệm tích lũy hôm nay sẽ là nền tảng cho sự thành công của lứa gà tiếp theo!",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85), height: 1.4),
                      ),

                      const SizedBox(height: 36),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow("Tổng chi phí (Vốn):", currencyFormat.format(widget.totalCost)),
                            const SizedBox(height: 12),
                            _buildInfoRow("Tổng thu (Doanh thu):", currencyFormat.format(widget.revenue)),
                            const SizedBox(height: 12),
                            _buildInfoRow("Tỉ lệ sống đạt:", "${widget.survivalRate.toStringAsFixed(1)}%"),
                            const Divider(height: 24, color: Colors.white24),
                            _buildInfoRow(
                              isProfit ? "LỢI NHUẬN RÒNG:" : "KẾT QUẢ TÀI CHÍNH:",
                              currencyFormat.format(widget.profit),
                              valueColor: isProfit ? Colors.amberAccent : Colors.redAccent.shade100,
                              isBig: true,
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      const Text(
                        "--- CHẠM VÀO MÀN HÌNH ĐỂ THOÁT ---",
                        style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1),
                      ),
                      const SizedBox(height: 16),
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

  Widget _buildInfoRow(String label, String value, {Color valueColor = Colors.white, bool isBig = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isBig ? 14 : 13, color: Colors.white70, fontWeight: isBig ? FontWeight.bold : FontWeight.normal)),
        Text(
          value,
          style: TextStyle(
            fontSize: isBig ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}