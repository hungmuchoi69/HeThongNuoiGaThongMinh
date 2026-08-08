import 'package:flutter/material.dart';
import 'package:smart_chicken_farming/model/LuaGa.dart';
import 'package:smart_chicken_farming/model/TieuChuanPhatTrien.dart';
import 'package:smart_chicken_farming/service/APIService.dart';

class DailyFeedNutritionCard extends StatefulWidget {
  final LuaGa? luaGa;

  const DailyFeedNutritionCard({
    Key? key,
    this.luaGa,
  }) : super(key: key);

  @override
  State<DailyFeedNutritionCard> createState() => _DailyFeedNutritionCardState();
}

class _DailyFeedNutritionCardState extends State<DailyFeedNutritionCard> {
  int ngayTuoi = 1;
  Tieuchuanphattrien? tieuChuan;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNutritionData();
  }

  @override
  void didUpdateWidget(covariant DailyFeedNutritionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.luaGa != widget.luaGa) {
      _loadNutritionData();
    }
  }

  Future<void> _loadNutritionData() async {
    if (widget.luaGa == null) {
      if (mounted) setState(() => isLoading = true);
      return;
    }

    try {
      final ngayNhap = widget.luaGa?.ngayNhap;
      if (ngayNhap != null) {
        final difference = DateTime.now().difference(ngayNhap).inDays;
        ngayTuoi = difference > 0 ? difference + 1 : 1;
      } else {
        ngayTuoi = 1;
      }
      Tieuchuanphattrien? tc = await Apiservice.findTCPTByNgayTuoi(ngayTuoi);
      if (mounted) {
        setState(() {
          tieuChuan = tc;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  double tinhTongLourngThucAnKg({
    required int soLuongHienTai,
    required double dinhMucGramMoiCon,
  }) {
    if (soLuongHienTai <= 0) return 0.0;
    double tongKg = (soLuongHienTai * dinhMucGramMoiCon) / 1000.0;
    return double.parse(tongKg.toStringAsFixed(1));
  }
  String _quyDoiBaoNgan(double kg) {
    if (kg <= 0) return "0 bao";
    const double kgPerBao = 25.0;
    double soBao = kg / kgPerBao;

    if (kg % kgPerBao == 0) {
      return "${soBao.toInt()} bao";
    }
    
    int soBaoNguyen = kg ~/ kgPerBao;
    double kgDu = double.parse((kg % kgPerBao).toStringAsFixed(1));

    if (soBaoNguyen == 0) {
      return "$kgDu kg";
    }
    return "$soBaoNguyen bao + $kgDu kg";
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || widget.luaGa == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const SizedBox(
          height: 150,
          child: Center(
            child: CircularProgressIndicator(color: Colors.orange),
          ),
        ),
      );
    }

    int soGaHienTai = widget.luaGa?.soLuongHienTai ?? (widget.luaGa?.soLuongBanDau ?? 0);
    double dinhMucGram = tieuChuan?.luong_thuc_an_tc ?? 0.0;
    double tongThucAnKg = tinhTongLourngThucAnKg(
      soLuongHienTai: soGaHienTai,
      dinhMucGramMoiCon: dinhMucGram,
    );
    double buaSangLieuLuong = double.parse((tongThucAnKg * 0.4).toStringAsFixed(1));
    double buaChieuLieuLuong = double.parse((tongThucAnKg * 0.2).toStringAsFixed(1));
    double buaToiLieuLuong = double.parse((tongThucAnKg * 0.4).toStringAsFixed(1));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.set_meal_rounded, color: Colors.amber.shade900, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "KHỐI LƯỢNG CÁM HÔM NAY",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            "Số lượng: $soGaHienTai con",
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const Divider(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.deepOrange.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "LƯỢNG CÁM CẦN CHO ĂN",
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Dựa trên tiêu chuẩn ngày tuổi",
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                  Text(
                    "$tongThucAnKg Kg",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    label: "Định mức/con",
                    value: "${dinhMucGram.toStringAsFixed(0)} g",
                    subValue: null,
                    icon: Icons.scale_outlined,
                  ),
                ),
                Container(height: 40, width: 1, color: Colors.grey[300]),
                Expanded(
                  child: _buildInfoTile(
                    label: "Sáng (40%)",
                    value: "$buaSangLieuLuong kg",
                    subValue: _quyDoiBaoNgan(buaSangLieuLuong),
                    icon: Icons.wb_sunny_outlined,
                  ),
                ),
                Container(height: 40, width: 1, color: Colors.grey[300]),
                Expanded(
                  child: _buildInfoTile(
                    label: "Chiều (20%)",
                    value: "$buaChieuLieuLuong kg",
                    subValue: _quyDoiBaoNgan(buaChieuLieuLuong),
                    icon: Icons.wb_twilight_rounded,
                  ),
                ),
                Container(height: 40, width: 1, color: Colors.grey[300]),
                Expanded(
                  child: _buildInfoTile(
                    label: "Tối (40%)",
                    value: "$buaToiLieuLuong kg",
                    subValue: _quyDoiBaoNgan(buaToiLieuLuong),
                    icon: Icons.nightlight_round_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Mẹo: Theo chuẩn 1 bao cám = 25kg. Nên đong cám theo từng bữa để tránh cám ẩm mốc.",
                      style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
    String? subValue,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        if (subValue != null) ...[
          const SizedBox(height: 2),
          Text(
            subValue,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.amber.shade900,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}