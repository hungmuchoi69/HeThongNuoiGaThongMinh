import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_chicken_farming/model/LichSuPhatTrien.dart';
import 'package:smart_chicken_farming/model/LuaGa.dart';
import 'package:smart_chicken_farming/model/TieuChuanPhatTrien.dart';
import 'package:smart_chicken_farming/service/APIService.dart';

class GrowthEvaluationPage extends StatefulWidget {
  final LuaGa luaGa;
  final int ngayTuoi;
  final Tieuchuanphattrien tieuchuanphattrien;
  final List<Lichsuphattrien> history;

  const GrowthEvaluationPage({
    super.key,
    required this.luaGa,
    required this.ngayTuoi,
    required this.tieuchuanphattrien,
    required this.history,
  });

  @override
  State<GrowthEvaluationPage> createState() => _CreateBatchScreenState();
}

class _CreateBatchScreenState extends State<GrowthEvaluationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _deadChicController = TextEditingController();
  final List<int> _sampledWeights = [];
  List<Lichsuphattrien> _evaluationHistory = [];
  bool _isLoadingHistory = true;
  int soLuongMau = 0;

  @override
  void initState() {
    super.initState();
    _initialHistorySetup();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _deadChicController.dispose();
    super.dispose();
  }

  void _initialHistorySetup() {
    final evaluationOnly = widget.history.where((item) {
      return item.trong_luong_tb != null &&
          item.trong_luong_tb! > 0 &&
          item.he_so_FCR != null &&
          item.he_so_FCR! > 0;
    }).toList();
    evaluationOnly.sort((a, b) => b.ngay.compareTo(a.ngay));

    setState(() {
      _evaluationHistory = evaluationOnly;
      _isLoadingHistory = false;
    });
  }

  void _addSampledWeight() {
    final weightValue = int.tryParse(_weightController.text.trim());
    if (weightValue == null || weightValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập trọng lượng hợp lệ (gam)!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _sampledWeights.add(weightValue);
      _weightController.clear();
    });
  }

  Future<void> _submitEvaluation() async {
    if (!_formKey.currentState!.validate()) return;

    // 1. Nếu người dùng đang gõ dở cân nặng ở ô Input mà chưa bấm nút Thêm mẫu, tự động thêm vào danh sách mẫu
    if (_weightController.text.trim().isNotEmpty) {
      _addSampledWeight();
    }

    final deadText = _deadChicController.text.trim();
    final bool hasDeadCount =
        deadText.isNotEmpty && (int.tryParse(deadText) ?? 0) >= 0;
    final bool hasWeightSamples = _sampledWeights.isNotEmpty;

    //  TRƯỜNG HỢP: Người dùng KHÔNG nhập bất kỳ dữ liệu nào ở cả 2 chức năng -> Cảnh báo
    if (!hasDeadCount && !hasWeightSamples) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Vui lòng nhập số lượng gà hao hụt HOẶC cân mẫu ít nhất 1 con để thực hiện!",
          ),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    final luaGa = widget.luaGa;
    final deadCount = hasDeadCount ? (int.tryParse(deadText) ?? 0) : 0;
    final slHienTai = (luaGa.soLuongHienTai ?? luaGa.soLuongBanDau) - deadCount;
    luaGa.soLuongHienTai = slHienTai;

    // =========================================================================
    // XỬ LÝ CÔNG VIỆC 1: CẬP NHẬT SỐ LƯỢNG HẠN GÀ (Nếu người dùng nhập hao hụt)
    // =========================================================================
    if (hasDeadCount) {
      await Apiservice.updLuaGa(luaGa.id!, luaGa, context: context);
    }

    // =========================================================================
    // XỬ LÝ CÔNG VIỆC 2: ĐÁNH GIÁ TĂNG TRƯỞNG ĐÀN GÀ (Nếu người dùng cân mẫu)
    // =========================================================================
    double avgWeight = 0.0;
    double fcr = 0.0;
    double tiLeSong = 0.0;

    if (hasWeightSamples) {
      final int sum = _sampledWeights.reduce((a, b) => a + b);
      avgWeight = sum / _sampledWeights.length;
      soLuongMau = _sampledWeights.length;

      final int khoiLuongTA = await Apiservice.getKhoiLuongTA(widget.ngayTuoi);

      fcr = (khoiLuongTA > 0 && avgWeight > 0)
          ? (khoiLuongTA / avgWeight).toDouble()
          : 0.0;
      tiLeSong = widget.luaGa.soLuongBanDau > 0
          ? (slHienTai / widget.luaGa.soLuongBanDau).toDouble()
          : 0.0;

      final lichsuphattrienNew = Lichsuphattrien(
        ngay: DateTime.now(),
        trong_luong_tb: avgWeight.toDouble(),
        he_so_FCR: fcr,
        ti_le_song: tiLeSong,
        id_lua_ga: luaGa.id!,
      );
      await Apiservice.createLichSuPhatTrien(
        lichsuphattrienNew,
        context: context,
      );

      setState(() {
        _evaluationHistory.insert(0, lichsuphattrienNew);
      });
    } else {
      tiLeSong = widget.luaGa.soLuongBanDau > 0
          ? (slHienTai / widget.luaGa.soLuongBanDau).toDouble()
          : 0.0;
    }

    setState(() {
      _sampledWeights.clear();
      _deadChicController.clear();
      _weightController.clear();
    });
    String message = "";
    if (hasDeadCount && hasWeightSamples) {
      message = "Đã cập nhật số lượng đàn và lưu nhật ký đánh giá thành công!";
    } else if (hasDeadCount) {
      message = "Đã cập nhật số lượng gà hiện tại thành công!";
    } else {
      message = "Đã lưu bản ghi đánh giá tăng trưởng thành công!";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );

    _showProcessingDialog(
      deadCount,
      avgWeight,
      fcr,
      tiLeSong,
      widget.tieuchuanphattrien.trong_luong_tc,
      hasWeightSamples: hasWeightSamples
    );
  }

  void _showProcessingDialog(
    int deadCount,
    double avgWeight,
    double fcr,
    double tiLeSong,
    double standardWeight, {
    bool hasWeightSamples = true,
  }) {
    //  TRƯỜNG HỢP : CHỈ CẬP NHẬT SỐ LƯỢNG (KHÔNG CÂN MẪU ĐÁNH GIÁ)
    if (!hasWeightSamples) {
      final int slHienTai = widget.luaGa.soLuongHienTai ?? 0;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.edit_note, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "CẬP NHẬT SỐ LƯỢNG",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Đã ghi nhận cập nhật số lượng gà thành công!",
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              _buildHistoryDetailRow(
                Icons.remove_circle_outline,
                "Số gà hao hụt ghi nhận",
                "$deadCount con",
                color: deadCount > 0 ? Colors.red : Colors.black87,
              ),
              _buildHistoryDetailRow(
                Icons.groups,
                "Tổng số gà còn lại",
                "$slHienTai con",
                color: Colors.green.shade700,
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.only(bottom: 12, right: 16),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                FocusScope.of(context).unfocus();
              },
              child: const Text(
                "XÁC NHẬN",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
      return;
    }

    //  TRƯỜNG HỢP : CÓ ĐÁNH GIÁ TĂNG TRƯỜNG (CÂN MẪU) HOẶC THỰC HIỆN CẢ HAI
    final double chenhLech = avgWeight - standardWeight;
    String thongBaoDanhGia = "";
    Color mauTrangThai = Colors.green;
    IconData iconTrangThai = Icons.trending_up;

    if (chenhLech < -0.05) {
      thongBaoDanhGia =
          "ĐÀN GÀ ĐANG BỊ THIẾU CÂN \n(Thấp hơn tiêu chuẩn ${chenhLech.abs().toStringAsFixed(2)} gam)";
      mauTrangThai = Colors.orange.shade800;
      iconTrangThai = Icons.trending_down;
    } else if (chenhLech >= -0.05 && chenhLech < 0) {
      thongBaoDanhGia = "CÂN NẶNG ĐẠT XẤP XỈ TIÊU CHUẨN";
      mauTrangThai = Colors.blue.shade700;
      iconTrangThai = Icons.trending_flat;
    } else {
      thongBaoDanhGia =
          "ĐÀN GÀ PHÁT TRIỂN CÂN NẶNG TỐT \n(Vượt tiêu chuẩn ${chenhLech.toStringAsFixed(2)} gam)";
      mauTrangThai = Colors.green.shade700;
      iconTrangThai = Icons.star_rounded;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: mauTrangThai,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Icon(iconTrangThai, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "KẾT QUẢ ĐÁNH GIÁ",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: mauTrangThai.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: mauTrangThai.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  thongBaoDanhGia,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: mauTrangThai,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildHistoryDetailRow(
                Icons.scale,
                "Trọng lượng trung bình",
                "${avgWeight.toStringAsFixed(2)} gam",
              ),
              _buildHistoryDetailRow(
                Icons.flag_outlined,
                "Trọng lượng tiêu chuẩn",
                "${standardWeight.toStringAsFixed(2)} gam",
              ),
              const Divider(height: 20),
              _buildHistoryDetailRow(
                Icons.calculate,
                "Hệ số thức ăn (FCR)",
                "${fcr.toStringAsFixed(3)} ${fcr < 2.5 ? "Tốt" : "Chưa Tốt"}",
              ),
              _buildHistoryDetailRow(
                Icons.favorite,
                "Tỉ lệ sống hiện tại",
                "${(tiLeSong * 100).toStringAsFixed(1)} %",
                color: tiLeSong < 0.9 ? Colors.red : Colors.green.shade700,
              ),
              _buildHistoryDetailRow(
                Icons.remove_circle_outline,
                "Số gà chết ghi nhận",
                "$deadCount con",
                color: deadCount > 0 ? Colors.red : Colors.black87,
              ),
              _buildHistoryDetailRow(
                Icons.layers,
                "Số lượng mẫu cân",
                "$soLuongMau con",
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 12, right: 16),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: mauTrangThai,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              FocusScope.of(context).unfocus();
            },
            child: const Text(
              "XÁC NHẬN",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Đánh Giá Tăng Trưởng",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "1. Tình trạng hao hụt đàn",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _deadChicController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText:
                          "Số lượng gà chết từ lần đánh giá trước đến nay (nếu có)",
                      labelStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red.shade400,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.blue.shade400,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final deadCount = int.tryParse(value.trim());
                      if (deadCount == null || deadCount < 0) {
                        return "Vui lòng nhập số nguyên hợp lệ";
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "2. Cân mẫu trọng lượng",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Đã cân: ${_sampledWeights.length} con",
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: "Trọng lượng mẫu gà (gam)",
                                labelStyle: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                                prefixIcon: Icon(
                                  Icons.scale,
                                  color: Colors.blue.shade600,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.blue.shade400,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              onFieldSubmitted: (_) => _addSampledWeight(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                              onPressed: _addSampledWeight,
                              child: const Row(
                                children: [
                                  Icon(Icons.add),
                                  SizedBox(width: 4),
                                  Text("Thêm"),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_sampledWeights.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        const Text(
                          "Danh sách mẫu đã thêm:",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _sampledWeights.asMap().entries.map((
                            entry,
                          ) {
                            int idx = entry.key + 1;
                            int w = entry.value;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "#$idx: ",
                                    style: TextStyle(
                                      color: Colors.green.shade800,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "$w gam",
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _sampledWeights.removeAt(entry.key);
                                      });
                                    },
                                    child: Icon(
                                      Icons.cancel,
                                      size: 16,
                                      color: Colors.green.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _sampledWeights.clear();
                            _deadChicController.clear();
                            _weightController.clear();
                          });
                          FocusScope.of(context).unfocus();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          foregroundColor: Colors.black54,
                        ),
                        icon: const Icon(Icons.refresh, size: 20),
                        label: const Text(
                          "Xóa dữ liệu mẫu",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _submitEvaluation,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.analytics, size: 20),
                        label: const Text(
                          "Xác nhận",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 35),
                Row(
                  children: [
                    Icon(Icons.history, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    const Text(
                      "Lịch sử đánh giá tăng trưởng",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const Divider(thickness: 1, height: 20),
                _isLoadingHistory
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(
                            color: Colors.blueAccent,
                          ),
                        ),
                      )
                    : _evaluationHistory.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(25.0),
                          child: Text(
                            "Chưa có bản ghi đánh giá nào trước đó.",
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _evaluationHistory.length,
                        itemBuilder: (context, index) {
                          final historyItem = _evaluationHistory[index];
                          final String formatNgay = DateFormat(
                            'dd/MM/yyyy',
                          ).format(historyItem.ngay);
                          final double trongLuong =
                              ((historyItem.trong_luong_tb ?? 0.0) as num)
                                  .toDouble();

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade50,
                                child: Icon(
                                  Icons.analytics_outlined,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              title: Text(
                                "Trọng lượng TB: ${trongLuong.toString()} gam",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                "Ngày đánh giá: $formatNgay",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    bottom: 12,
                                  ),
                                  child: Column(
                                    children: [
                                      const Divider(),
                                      _buildHistoryDetailRow(
                                        Icons.scale,
                                        "Trọng lượng",
                                        "${trongLuong.toString()} gam",
                                      ),
                                      _buildHistoryDetailRow(
                                        Icons.calculate,
                                        "Hệ số FCR",
                                        ((historyItem.he_so_FCR ?? 0.0) as num)
                                            .toDouble()
                                            .toStringAsFixed(3),
                                      ),
                                      _buildHistoryDetailRow(
                                        Icons.favorite,
                                        "Tỉ lệ sống đạt",
                                        "${(((historyItem.ti_le_song ?? 0.0) as num).toDouble() * 100).toStringAsFixed(1)} %",
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryDetailRow(
    IconData icon,
    String title,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? Colors.blueGrey),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
