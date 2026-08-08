import 'dart:io';

import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart_chicken_farming/model/ChiPhiChanNuoi.dart';
import 'package:smart_chicken_farming/model/LoaiChiPhi.dart';
import 'package:smart_chicken_farming/model/LuaGa.dart';
import 'package:smart_chicken_farming/page/LivestockSummaryScreen.dart';
import 'package:smart_chicken_farming/service/APIService.dart';

class LivestockCostPage extends StatefulWidget {
  final LuaGa luaGa;
  final int ngayTuoi;

  const LivestockCostPage({super.key, required this.luaGa, required this.ngayTuoi});

  @override
  State<LivestockCostPage> createState() => _LivestockCostPageState();
}

class _LivestockCostPageState extends State<LivestockCostPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _pricePerKgController = TextEditingController();
  final _totalWeightController = TextEditingController();
  
  String? _selectedCostTypeId;
  List<Loaichiphi> _costTypes = [];
  List<Chiphichannuoi> _costsHistory = [];
  bool _isLoading = true;

  int _currentSection = 0; 
  String _amountInWords = "Chưa nhập số tiền";
  String _priceInWords = "Chưa nhập giá bán";

  @override
  void initState() {
    super.initState();
    _loadData();

    _pricePerKgController.addListener(_onPricePerKgChanged);
    _totalWeightController.addListener(_onWeightOrPriceChanged);
  }

  @override
  void dispose() {
    _pricePerKgController.removeListener(_onPricePerKgChanged);
    _totalWeightController.removeListener(_onWeightOrPriceChanged);
    _amountController.dispose();
    _noteController.dispose();
    _pricePerKgController.dispose();
    _totalWeightController.dispose();
    super.dispose();
  }

  void _onPricePerKgChanged() {
    final cleanStr = _pricePerKgController.text.replaceAll('.', '');
    final number = int.tryParse(cleanStr);
    setState(() {
      if (number == null || number == 0) {
        _priceInWords = "Chưa nhập giá bán";
      } else {
        _priceInWords = "${_convertNumberToWords(number)} đồng / kg";
      }
    });
  }

  void _onWeightOrPriceChanged() {
    setState(() {});
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final types = await Apiservice.getAllLoaiChiPhi(context: context);
      final history = await Apiservice.getAllChiPhiChanNuoi(widget.luaGa.id!, context: context);

      setState(() {
        _costTypes = types;
        _costsHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Lỗi tải dữ liệu chi phí: $e");
    }
  }

  Future<void> _submitCost() async {
    if (!_formKey.currentState!.validate() || _selectedCostTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng điền đầy đủ thông tin chi phí!")),
      );
      return;
    }

    String cleanAmount = _amountController.text.replaceAll('.', '');
    int money = int.tryParse(cleanAmount) ?? 0;
    
    Chiphichannuoi newCost = Chiphichannuoi(
      id_lua_ga: widget.luaGa.id!,
      id_loai_chi_phi: int.parse(_selectedCostTypeId!),
      so_tien: money,
      ngay_chi_tieu: DateTime.now(),
      ghi_chu: _noteController.text,
    );

    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
    );

    bool isSuccess = await Apiservice.createChiPhiChanNuoi(newCost, context: context);
    
    if (!mounted) return;
    Navigator.pop(context);

    if (isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Thêm chi phí thành công!"), backgroundColor: Colors.green),
      );
      _amountController.clear();
      _noteController.clear();
      setState(() {
        _amountInWords = "Chưa nhập số tiền";
      });
      _loadData();
    }
  }

  // 🌟 HÀM TỔNG KẾT TOÀN BỘ LỨA NUÔI VÀ HIỂN THỊ BÁO CÁO DIALOG
  Future<void> _submitFinalSummary() async {
    int totalCost = _costsHistory.fold(0, (sum, item) => sum + (item.so_tien));
    String cleanPriceStr = _pricePerKgController.text.replaceAll('.', '');
    int pricePerKg = int.tryParse(cleanPriceStr) ?? 0;
    double totalWeight = double.tryParse(_totalWeightController.text) ?? 0;

    int estimatedRevenue = double.parse((totalWeight * pricePerKg).toString()).toInt();
    int totalProfit = estimatedRevenue - totalCost;

    int inputCount = widget.luaGa.soLuongBanDau;
    int currentCount = widget.luaGa.soLuongHienTai ?? 0;
    double survivalRate = inputCount > 0 ? (currentCount / inputCount) * 100 : 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.green)),
    );

    try {
      LuaGa updatedLuaGa = widget.luaGa;
      updatedLuaGa.loiNhuan = totalProfit;
      updatedLuaGa.trangThai="SOLD";

      bool isSuccess = await Apiservice.updLuaGa(widget.luaGa.id!,updatedLuaGa, context: context);

      if (!mounted) return;
      Navigator.pop(context);

      if (isSuccess) {
        // 4. Cập nhật thành công DB -> Hiển thị Dialog tổng kết chi tiết
        final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
        _showSummaryReportDialog(
          format: currencyFormat,
          inputCount: inputCount,
          currentCount: currentCount,
          survivalRate: survivalRate,
          totalCost: totalCost,
          revenue: estimatedRevenue,
          profit: totalProfit,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tổng kết thất bại. Vui lòng kiểm tra kết nối API!"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Có lỗi xảy ra khi tổng kết: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _showSummaryReportDialog({
    required NumberFormat format,
    required int inputCount,
    required int currentCount,
    required double survivalRate,
    required int totalCost,
    required int revenue,
    required int profit,
  }) {
    bool isProfit = profit >= 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.analytics_rounded, color: Colors.green.shade700, size: 28),
              const SizedBox(width: 10),
              const Text(
                "TỔNG KẾT LỨA NUÔI",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Lứa chăn nuôi đã chốt thành công sang trạng thái SOLD. Dưới đây là thống kê hạch toán chi tiết:",
                  style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 16),
                
                // --- Khối Dữ Liệu Sản Lượng Đàn ---
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildDialogRow("Số lượng nhập vào:", "$inputCount con", Colors.black87),
                      const SizedBox(height: 8),
                      _buildDialogRow("Số lượng hiện tại:", "$currentCount con", Colors.black87),
                      const SizedBox(height: 8),
                      _buildDialogRow(
                        "Tỉ lệ sống:", 
                        "${survivalRate.toStringAsFixed(1)}%", 
                        survivalRate >= 92 ? Colors.green.shade700 : Colors.orange.shade700,
                        isBold: true
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isProfit ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isProfit ? Colors.green.shade200 : Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildDialogRow("Tiền chi (Tổng vốn):", format.format(totalCost), Colors.red.shade700),
                      const SizedBox(height: 8),
                      _buildDialogRow("Tiền thu (Doanh thu):", format.format(revenue), Colors.green.shade700),
                      const Divider(height: 16, color: Colors.black12),
                      _buildDialogRow(
                        isProfit ? "Tổng kết(LÃI):" : "Tổng kết (THUA LỖ):",
                        format.format(profit),
                        isProfit ? Colors.green.shade800 : Colors.red.shade800,
                        isBold: true,
                        valueSize: 15,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade800,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context); 
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LivestockSummaryScreen(
                        profit: profit.toDouble(),
                        totalCost: totalCost.toDouble(),
                        revenue: revenue.toDouble(),
                        survivalRate: survivalRate,
                      ),
                    ),
                  );
                },
                child: const Text(
                  "XÁC NHẬN VÀ ĐÓNG",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportToExcel() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.green)),
    );

    try {
      var excel = Excel.createExcel();
      String defaultSheet = excel.getDefaultSheet()!;

      Sheet sheetOverview = excel["Tổng Quan & Chi Phí"];
      Sheet sheetVaccine = excel["Nhật Ký Tiêm Vaccine"];
      Sheet sheetGrowth = excel["Lịch Sử Phát Triển"];
      
      if (defaultSheet != "Tổng Quan & Chi Phí") {
        excel.delete(defaultSheet);
      }

      final df = DateFormat('dd/MM/yyyy');

      CellStyle cellHeaderStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString("#1B5E20"), 
        fontColorHex: ExcelColor.fromHexString("#FFFFFF"), 
        fontFamily: getFontFamily(FontFamily.Calibri),
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );

      CellStyle sectionStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString("#C8E6C9"), 
        fontFamily: getFontFamily(FontFamily.Calibri),
        bold: true,
        horizontalAlign: HorizontalAlign.Left,
      );

      CellStyle titleTableStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString("#E0E0E0"),
        fontFamily: getFontFamily(FontFamily.Calibri),
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );

      CellStyle warningHeaderStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString("#FFB74D"),
        fontFamily: getFontFamily(FontFamily.Calibri),
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );

      // =========================================================================
      // SHEET 1: TỔNG QUAN & CHI PHÍ
      // =========================================================================
      sheetOverview.appendRow([TextCellValue("THÔNG TIN TỔNG QUAN VỤ CHĂN NUÔI")]);
      sheetOverview.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = cellHeaderStyle;
      sheetOverview.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0));

      sheetOverview.appendRow([TextCellValue("Mã lứa gà:"), IntCellValue(widget.luaGa.id ?? 0)]);
      sheetOverview.appendRow([TextCellValue("Ngày nhập đàn:"), TextCellValue(df.format(DateTime.parse(widget.luaGa.ngayNhap.toString())))]);
      sheetOverview.appendRow([TextCellValue("Số lượng ban đầu:"), IntCellValue(widget.luaGa.soLuongBanDau)]);
      sheetOverview.appendRow([TextCellValue("Số lượng hiện tại:"), IntCellValue(widget.luaGa.soLuongHienTai ?? 0)]);
      
      double totalCost = _costsHistory.fold(0.0, (sum, item) => sum + (item.so_tien));
      double pricePerKg = double.tryParse(_pricePerKgController.text.replaceAll('.', '')) ?? 0.0;
      double totalWeight = double.tryParse(_totalWeightController.text) ?? 0.0;
      double revenue = totalWeight * pricePerKg;
      double profit = revenue - totalCost;

      sheetOverview.appendRow([TextCellValue("Tổng chi phí đầu tư (đ):"), DoubleCellValue(totalCost)]);
      sheetOverview.appendRow([TextCellValue("Doanh thu xuất chuồng (đ):"), DoubleCellValue(revenue)]);
      sheetOverview.appendRow([TextCellValue("Lợi nhuận (đ):"), DoubleCellValue(profit)]);
      sheetOverview.appendRow([TextCellValue("Trạng thái lứa gà:"), TextCellValue(widget.luaGa.trangThai)]);
      sheetOverview.appendRow([TextCellValue("")]); 

      sheetOverview.appendRow([TextCellValue("DANH SÁCH CÁC KHOẢN CHI PHÍ ĐÃ ĐẦU TƯ TÍCH LŨY")]);
      int costHeaderRow = sheetOverview.maxRows - 1;
      sheetOverview.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: costHeaderRow)).cellStyle = sectionStyle;
      sheetOverview.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: costHeaderRow), CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: costHeaderRow));

      sheetOverview.appendRow([TextCellValue("STT"), TextCellValue("Loại chi phí đầu tư"), TextCellValue("Số tiền chi (đ)"), TextCellValue("Ngày thực hiện chi tiêu"), TextCellValue("Ghi chú chi tiết")]);
      int costTitleRow = sheetOverview.maxRows - 1;
      for (int c = 0; c < 5; c++) {
        sheetOverview.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: costTitleRow)).cellStyle = titleTableStyle;
      }

      for (int i = 0; i < _costsHistory.length; i++) {
        var cost = _costsHistory[i];
        var typeName = _costTypes.any((t) => t.id == cost.id_loai_chi_phi)
            ? _costTypes.firstWhere((t) => t.id == cost.id_loai_chi_phi).ten_loai
            : "Chi phí bổ sung";

        sheetOverview.appendRow([
          IntCellValue(i + 1),
          TextCellValue(typeName),
          DoubleCellValue(cost.so_tien.toDouble()),
          TextCellValue(df.format(DateTime.parse(cost.ngay_chi_tieu.toIso8601String()))),
          TextCellValue(cost.ghi_chu ?? ""),
        ]);
      }

      // =========================================================================
      // SHEET 2: NHẬT KÝ VACCINE
      // =========================================================================
      List<dynamic> vaccineSchedule = await Apiservice.getAllLichTiemThucTe(widget.luaGa.id!, context: context);

      sheetVaccine.appendRow([TextCellValue("NHẬT KÝ TIÊM CHỦNG VACCINE ĐÀN GÀ")]);
      sheetVaccine.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = cellHeaderStyle;
      sheetVaccine.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0));

      sheetVaccine.appendRow([
        TextCellValue("STT"),
        TextCellValue("Tên loại Vaccine chỉ định"),
        TextCellValue("Ngày lên lịch dự kiến"),
        TextCellValue("Ngày tiêm thực tế"),
        TextCellValue("Trạng thái"),
        TextCellValue("Đánh giá tiến độ dịch tễ")
      ]);
      int vacTitleRow = sheetVaccine.maxRows - 1;
      for (int v = 0; v < 6; v++) {
        sheetVaccine.cell(CellIndex.indexByColumnRow(columnIndex: v, rowIndex: vacTitleRow)).cellStyle = titleTableStyle;
      }

      for (int j = 0; j < vaccineSchedule.length; j++) {
        var vac = vaccineSchedule[j];
        
        DateTime? dateExpected = vac.ngay_du_kien;
        DateTime? dateActual = vac.ngay_thuc_hien;
        String statusText = vac.trang_thai;
        String evaluation = vac.ghi_chu ?? "---";

        String finalVaccineName = vac.danhMucVaccine?.ten_vaccine ?? "Vaccine phòng bệnh";

        sheetVaccine.appendRow([
          IntCellValue(j + 1),
          TextCellValue(finalVaccineName),
          TextCellValue(dateExpected != null ? df.format(dateExpected) : "---"),
          TextCellValue(dateActual != null ? df.format(dateActual) : "---"),
          TextCellValue(statusText),
          TextCellValue(evaluation),
        ]);
      }

      // =========================================================================
      // SHEET 3: LỊCH SỬ PHÁT TRIỂN & CẢM BIẾN 
      // =========================================================================
      List<dynamic> growthHistory = [];
      try {
        growthHistory = await Apiservice.getAllLichSuPhatTrien(widget.luaGa.id!, context: context);
      } catch (e) {
        print("Trống lịch sử tăng trưởng: $e");
      }

      sheetGrowth.appendRow([TextCellValue("NHẬT KÝ GIÁ TRỊ CẢM BIẾN MÔI TRƯỜNG & ĐÁNH GIÁ TĂNG TRƯỞNG")]);
      sheetGrowth.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = cellHeaderStyle;
      sheetGrowth.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 0));

      sheetGrowth.appendRow([
        TextCellValue("STT"),
        TextCellValue("Ngày ghi nhận"),
        TextCellValue("Nhiệt độ TB (°C)"),
        TextCellValue("Độ ẩm TB (%)"),
        TextCellValue("Chỉ số Nước (TDS)"),
        TextCellValue("Khí độc (GAS)"),
        TextCellValue("Trọng lượng TB (kg)"),
        TextCellValue("Hệ số chuyển đổi thức ăn (FRC)"),
        TextCellValue("Tỉ lệ sống đạt (%)")
      ]);
      int growthTitleRow = sheetGrowth.maxRows - 1;
      for (int g = 0; g < 8; g++) {
        sheetGrowth.cell(CellIndex.indexByColumnRow(columnIndex: g, rowIndex: growthTitleRow)).cellStyle = titleTableStyle;
      }

      if (growthHistory.isEmpty) {
        sheetGrowth.appendRow([TextCellValue("Chưa có nhật ký ghi nhận cảm biến hằng ngày cho lứa này.")]);
      } else {
        for (int k = 0; k < growthHistory.length; k++) {
          var record = growthHistory[k];
          sheetGrowth.appendRow([
            IntCellValue(k + 1),
            TextCellValue(df.format(record.ngay)),
            DoubleCellValue(record.nhiet_do_tb ?? 0.0),
            DoubleCellValue(record.do_am_tb ?? 0.0),
            DoubleCellValue(record.tds_tb ?? 0.0),
            DoubleCellValue(record.gas_tb ?? 0.0),
            DoubleCellValue(record.trong_luong_tb ?? 0.0),
            DoubleCellValue(record.he_so_FCR ?? 0.0),
            DoubleCellValue(record.ti_le_song ?? 100.0),
          ]);
        }
      }

      sheetGrowth.appendRow([TextCellValue("")]); 
      sheetGrowth.appendRow([TextCellValue("")]); 

      sheetGrowth.appendRow([TextCellValue("BẢNG GIẢI THÍCH CHỈ SỐ KỸ THUẬT")]);
      int docHeaderRow = sheetGrowth.maxRows - 1;
      sheetGrowth.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: docHeaderRow)).cellStyle = warningHeaderStyle;
      sheetGrowth.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: docHeaderRow), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: docHeaderRow));

      sheetGrowth.appendRow([
        TextCellValue("Ký hiệu chỉ số"),
        TextCellValue("Khoảng giá trị lý tưởng"),
        TextCellValue("Ngưỡng cảnh báo rủi ro"),
      ]);
      int docTitleRow = sheetGrowth.maxRows - 1;
      for (int d = 0; d < 5; d++) {
        sheetGrowth.cell(CellIndex.indexByColumnRow(columnIndex: d, rowIndex: docTitleRow)).cellStyle = titleTableStyle;
      }
      sheetGrowth.merge(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: docTitleRow), CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: docTitleRow));

      sheetGrowth.appendRow([
        TextCellValue("TDS (ppm)"),
        TextCellValue("0 - 500 ppm"),
        TextCellValue("> 1000 ppm"),
      ]);
      sheetGrowth.merge(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: sheetGrowth.maxRows - 1), CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: sheetGrowth.maxRows - 1));

      sheetGrowth.appendRow([
        TextCellValue("GAS / NH3 (ppm)"),
        TextCellValue("0 - 1200 ppm"),
        TextCellValue("> 1200 ppm (Cực kỳ nguy hiểm)"),
      ]);
      sheetGrowth.merge(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: sheetGrowth.maxRows - 1), CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: sheetGrowth.maxRows - 1));

      sheetGrowth.appendRow([
        TextCellValue("FCR"),
        TextCellValue("1.9 - 2.9 (Tùy giống gà)"),
        TextCellValue("> 3 (Kém hiệu quả kinh tế)"),
      ]);
      sheetGrowth.merge(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: sheetGrowth.maxRows - 1), CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: sheetGrowth.maxRows - 1));

      // =========================================================================
      // 🌟 TỰ ĐỘNG GIÃN CỘT TOÀN DIỆN CHO TẤT CẢ CÁC SHEET
      // =========================================================================
      for (var table in excel.tables.keys) {
        var currentSheet = excel.tables[table]!;
        for (int col = 0; col < currentSheet.maxColumns; col++) {
          int maxLen = 12; 
          for (int row = 0; row < currentSheet.maxRows; row++) {
            var cell = currentSheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
            if (cell.value != null) {
              String cellStr = cell.value.toString();
              if (row == 0 || (table == "Tổng Quan & Chi Phí" && row == costHeaderRow)) {
                continue;
              }
              if (cellStr.length > maxLen) {
                maxLen = cellStr.length;
              }
            }
          }
          currentSheet.setColumnWidth(col, maxLen.toDouble() + 4);
        }
      }

      List<int>? fileBytes = excel.encode();
      if (fileBytes != null) {
        final directory = await getExternalStorageDirectory(); 
        String filePath = "${directory?.path}/Bao_Cao_Trang_Trai_Lua_${widget.luaGa.tenLua}.xlsx";
        File file = File(filePath);
        await file.writeAsBytes(fileBytes, flush: true);

        if (!mounted) return;
        Navigator.pop(context); 

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text("Đã xuất báo cáo đa phân hệ thành công!"), backgroundColor: Colors.green.shade800),
        );

        await OpenFilex.open(filePath);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); 
      print("Lỗi xuất Excel: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi xử lý file Excel: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildDialogRow(String label, String value, Color color, {bool isBold = false, double valueSize = 13}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
        Text(
          value,
          style: TextStyle(fontSize: valueSize, color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.w600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildPillSelectionBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: _buildActiveSectionContent(currencyFormat),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillSelectionBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildPillItem(0, "Nhập chi phí", Icons.add_card_rounded),
          _buildPillItem(1, "Danh sách", Icons.receipt_long_rounded),
          _buildPillItem(2, "Lợi nhuận", Icons.analytics_rounded),
        ],
      ),
    );
  }

  Widget _buildPillItem(int index, String title, IconData icon) {
    bool isSelected = _currentSection == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentSection = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected 
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color.fromARGB(255, 25, 210, 185) : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSectionContent(NumberFormat format) {
    switch (_currentSection) {
      case 0:
        return SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), child: _buildAddCostSection());
      case 1:
        return _buildCostListSection(format);
      case 2:
        return SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), child: _buildProfitAnalysisSection(format));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAddCostSection() {
    return Form(
      key: _formKey,
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200, width: 1)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                dropdownColor: Colors.white,
                decoration: InputDecoration(
                  labelText: "Chọn loại chi phí", 
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                value: _selectedCostTypeId,
                items: _costTypes.map((type) {
                  return DropdownMenuItem(value: type.id.toString(), child: Text(type.ten_loai));
                }).toList(),
                onChanged: (val) => setState(() => _selectedCostTypeId = val),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  _ThousandsSeparatorInputFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: "Số tiền đầu tư (VNĐ)", 
                  prefixIcon: const Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixText: "đ",
                ),
                onChanged: (value) {
                  final cleanNumberStr = value.replaceAll('.', '');
                  final number = int.tryParse(cleanNumberStr);
                  setState(() {
                    if (number == null || number == 0) {
                      _amountInWords = "Chưa nhập số tiền";
                    } else {
                      _amountInWords = "${_convertNumberToWords(number)} đồng";
                    }
                  });
                },
                validator: (value) => value!.isEmpty ? "Không được bỏ trống số tiền" : null,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 4.0, bottom: 8.0),
                child: Text(
                  "➔ Bằng chữ: $_amountInWords",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                    color: _amountInWords == "Chưa nhập số tiền" ? Colors.grey : Colors.blue.shade800,
                    fontWeight: _amountInWords == "Chưa nhập số tiền" ? FontWeight.normal : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Ghi chú chi tiết", 
                  prefixIcon: const Icon(Icons.description_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700, 
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: _submitCost,
                  child: const Text("XÁC NHẬN LƯU CHI PHÍ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCostListSection(NumberFormat format) {
    if (_costsHistory.isEmpty) {
      return Container(
        height: 300,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text("Chưa ghi nhận khoản chi nào.", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
      );
    }

    double totalCost = _costsHistory.fold(0.0, (sum, item) => sum + (item.so_tien));

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: _costsHistory.length,
            itemBuilder: (context, index) {
              final item = _costsHistory[index];
              final typeName = _costTypes.firstWhere((t) => t.id == item.id_loai_chi_phi).ten_loai;

              return Card(
                color: Colors.white,
                elevation: 0,
                margin: const EdgeInsets.symmetric(vertical: 5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade100)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade50, 
                    child: Icon(Icons.arrow_outward_rounded, color: Colors.red.shade700, size: 18)
                  ),
                  title: Text(typeName, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800, fontSize: 14)),
                  subtitle: Text(
                    "${item.ghi_chu ?? 'Không có ghi chú'}\n📅 ${DateFormat('dd/MM/yyyy').format(DateTime.parse(item.ngay_chi_tieu.toIso8601String()))}",
                    style: const TextStyle(fontSize: 12, height: 1.3),
                  ),
                  trailing: Text(
                    "-${format.format(item.so_tien)}", 
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          margin: const EdgeInsets.only(top: 8, bottom: 4),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200, width: 0.8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.monetization_on_rounded, color: Colors.red.shade800, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Tổng chi phí lứa này:",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                  ),
                ],
              ),
              Text(
                format.format(totalCost),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade800),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfitAnalysisSection(NumberFormat format) {
    double totalCost = _costsHistory.fold(0.0, (sum, item) => sum + (item.so_tien));
    
    String cleanPriceStr = _pricePerKgController.text.replaceAll('.', '');
    double pricePerKg = double.tryParse(cleanPriceStr) ?? 0.0;
    double totalWeight = double.tryParse(_totalWeightController.text) ?? 0.0;

    double estimatedRevenue = totalWeight * pricePerKg;
    double totalProfit = estimatedRevenue - totalCost;

    bool isRaising = widget.ngayTuoi>28;
    bool isProfit = totalProfit >= 0;
    
    bool isInputsNotEmpty = _totalWeightController.text.isNotEmpty && _pricePerKgController.text.isNotEmpty;
    bool isSummaryReady = isRaising && isInputsNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.scale_rounded, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text("Thông Số Xuất Bán Thương Phẩm", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800)),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _totalWeightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: "Tổng khối lượng xuất chuồng", border: OutlineInputBorder(), suffixText: "kg", isDense: true),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pricePerKgController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    _ThousandsSeparatorInputFormatter(),
                  ],
                  decoration: const InputDecoration(labelText: "Giá thương phẩm bán ra / 1kg", border: OutlineInputBorder(), suffixText: "đ / kg", isDense: true),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                  child: Text(
                    "➔ Bằng chữ: $_priceInWords",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                      color: _priceInWords == "Chưa nhập giá bán" ? Colors.grey : Colors.blue.shade800,
                      fontWeight: _priceInWords == "Chưa nhập giá bán" ? FontWeight.normal : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        Card(
          color: isRaising 
              ? Colors.blue.shade50 
              : (isProfit ? Colors.green.shade50 : Colors.red.shade50),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), 
            side: BorderSide(
              color: isRaising 
                  ? Colors.blue.shade200 
                  : (isProfit ? Colors.green.shade200 : Colors.red.shade200), 
              width: 0.5
            )
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Text(
                    isRaising ? "HIỆU QUẢ KINH TẾ ĐƯỢC TÍNH TOÁN KHI BÁN" : "KẾT QUẢ KINH TẾ CHÍNH THỨC", 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 11, 
                      color: isRaising ? Colors.blue.shade900 : (isProfit ? Colors.green.shade900 : Colors.red.shade900), 
                      letterSpacing: 0.5
                    )
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isRaising ? "---" : format.format(totalProfit), 
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      color: isRaising ? Colors.blue.shade800 : (isProfit ? Colors.green.shade800 : Colors.red.shade800)
                    )
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isRaising 
                        ? "🔵 ĐANG TRONG VỤ CHĂN NUÔI" 
                        : (isProfit ? "🟢 ĐANG CÓ LÃI" : "🔴 ĐANG THUA LỖ"), 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 12, 
                      color: isRaising ? Colors.blue.shade700 : (isProfit ? Colors.green.shade700 : Colors.red.shade700)
                    )
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              children: [
                _buildSummaryRow("Tổng vốn đầu tư hiện tại (Tổng Chi)", format.format(totalCost), Colors.red.shade700),
                Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade100),
                _buildSummaryRow("Doanh thu bán ra dự kiến (Tổng Thu)", format.format(estimatedRevenue), Colors.green.shade700),
                Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade100),
                _buildSummaryRow("Số lượng gà hiện tại trong đàn", "${widget.luaGa.soLuongHienTai ?? 0} con", Colors.blueGrey.shade700),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.explicit_rounded, size: 20, color: Colors.green),
            label: const Text("XUẤT BÁO CÁO EXCEL (LỊCH SỬ & VACCINE)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.green.shade700, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _exportToExcel, // Kích hoạt tiến trình xuất file
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
            label: const Text("HOÀN THÀNH TỔNG KẾT LỨA NUÔI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade500,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: isSummaryReady ? _submitFinalSummary : null, 
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSummaryRow(String title, String val, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.blueGrey.shade800)),
          Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;
    String cleanString = newValue.text.replaceAll('.', '');
    final formatter = NumberFormat('#,###', 'vi_VN');
    final intValue = int.tryParse(cleanString);
    if (intValue == null) return newValue;
    String newText = formatter.format(intValue).replaceAll(',', '.');
    return newValue.copyWith(text: newText, selection: TextSelection.collapsed(offset: newText.length));
  }
}

String _convertNumberToWords(int number) {
  if (number == 0) return "Không";
  final List<String> units = ["", "nghìn", "triệu", "tỷ", "nghìn tỷ"];
  final List<String> digits = ["không", "một", "hai", "ba", "bốn", "năm", "sáu", "bảy", "tám", "chín"];

  String readThreeDigits(int n, bool showZeroHundred) {
    int hundred = n ~/ 100; int ten = (n % 100) ~/ 10; int unit = n % 10; String res = "";
    if (hundred > 0 || showZeroHundred) res += "${digits[hundred]} trăm ";
    if (ten == 0) { if (hundred > 0 && unit > 0) res += "linh "; } 
    else if (ten == 1) res += "mười "; else res += "${digits[ten]} mươi ";
    if (ten > 1 && unit == 1) res += "mốt"; else if (ten > 0 && unit == 5) res += "lăm"; else if (unit > 0) res += digits[unit];
    return res.trim();
  }

  String res = ""; int unitIndex = 0; int temp = number;
  while (temp > 0) {
    int countThree = temp % 1000; temp = temp ~/ 1000;
    if (countThree > 0) {
      String strThree = readThreeDigits(countThree, temp > 0);
      res = "$strThree ${units[unitIndex]} $res";
    } else if (unitIndex == 3 && number > 0) { res = "${units[unitIndex]} $res"; }
    unitIndex++;
  }
  res = res.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (res.isNotEmpty) res = res[0].toUpperCase() + res.substring(1);
  return res;
}