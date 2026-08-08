import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_chicken_farming/model/LichTiemThucTe.dart';
import 'package:smart_chicken_farming/service/APIService.dart';

class VaccineManagementTab extends StatefulWidget {
  final int idLuaGa;

  const VaccineManagementTab({super.key, required this.idLuaGa});

  @override
  State<VaccineManagementTab> createState() => _VaccineManagementTabState();
}

class _VaccineManagementTabState extends State<VaccineManagementTab> {
  List<Lichtiemthucte> _lichTiemList = [];
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _errorMess;

  @override
  void initState() {
    super.initState();
    _loadLichTiemThucTe();
  }

  Future<void> _loadLichTiemThucTe() async {
    try {
      setState(() => _isLoading = true);
      final list = await Apiservice.getAllLichTiemThucTe(widget.idLuaGa,context: context);
      if (!mounted) return;
      setState(() {
        _lichTiemList = list;
        _errorMess = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMess = 'Không thể tải lịch tiêm thực tế';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCheckboxChanged(
    Lichtiemthucte item,
    bool isChecked,
  ) async {
    final isDone = (item.trang_thai?.trim() ?? '') == "Đã thực hiện";
    if (isDone && !isChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '🔒 Lịch tiêm đã thực hiện thành công, không thể hủy bỏ chọn!',
          ),
          backgroundColor: Color.fromARGB(255, 236, 114, 21),
        ),
      );
      return;
    }
    if (isChecked && item.ngay_du_kien != null) {
      final ngayHomNay = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      final ngayDuKien = DateTime(
        item.ngay_du_kien!.year,
        item.ngay_du_kien!.month,
        item.ngay_du_kien!.day,
      );

      if (ngayDuKien.isAfter(ngayHomNay)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Chưa đến ngày tiêm dự kiến của vaccine này!'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    if (isChecked) {
      _showConfirmDialog(item);
    }
  }

  // Hàm hiển thị Dialog xác nhận tiêm và nhập ghi chú
  void _showConfirmDialog(Lichtiemthucte item) {
    final noteController = TextEditingController(text: item.ghi_chu);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.verified_user, color: Colors.green),
              SizedBox(width: 8),
              Text('Xác Nhận Đã Tiêm'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn có chắc chắn đã tiêm vaccine này cho lứa gà không?',
                style: TextStyle(color: Colors.grey[800]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Thêm ghi chú (nếu có)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.note_alt_outlined),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy bỏ', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _updateLichTiemStatus(item, true, noteController.text.trim());
              },
              child: const Text(
                'Xác nhận',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateLichTiemStatus(
    Lichtiemthucte item,
    bool isChecked,
    String? note,
  ) async {
    final index = _lichTiemList.indexWhere((element) => element.id == item.id);
    if (index == -1) return;

    final trangThaiCu = _lichTiemList[index].trang_thai;
    final ngayThucHienCu = _lichTiemList[index].ngay_thuc_hien;
    final ghiChuCu = _lichTiemList[index].ghi_chu;

    try {
      setState(() => _isActionLoading = true);

      final ngayThucHienHienTai = DateTime.now();
      String ghiChuHienTai = note ?? '';
      if (isChecked && item.ngay_du_kien != null) {
        final ngayDuKien = DateTime(
          item.ngay_du_kien!.year,
          item.ngay_du_kien!.month,
          item.ngay_du_kien!.day,
        );
        final ngayThucHien = DateTime(
          ngayThucHienHienTai.year,
          ngayThucHienHienTai.month,
          ngayThucHienHienTai.day,
        );

        if (ngayThucHien.isAfter(ngayDuKien)) {
          ghiChuHienTai = ghiChuHienTai.isEmpty
              ? '(Thực hiện trễ)'
              : '$ghiChuHienTai (Thực hiện trễ)';
        }
      }
      item.trang_thai = isChecked ? 'Đã thực hiện' : 'Chưa thực hiện';
      item.ngay_thuc_hien = isChecked ? ngayThucHienHienTai : null;
      item.ghi_chu = ghiChuHienTai.isEmpty ? null : ghiChuHienTai;

      await Apiservice.updLichTiemThucTe(item.id!, item,context: context);

      if (!mounted) return;
      setState(() {
        _lichTiemList[index].trang_thai = item.trang_thai;
        _lichTiemList[index].ngay_thuc_hien = item.ngay_thuc_hien;
        _lichTiemList[index].ghi_chu = item.ghi_chu;
        _isActionLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isChecked
                ? 'Cập nhật lịch tiêm thành công! 🎉'
                : 'Đã hủy xác nhận.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lichTiemList[index].trang_thai = trangThaiCu;
        _lichTiemList[index].ngay_thuc_hien = ngayThucHienCu;
        _lichTiemList[index].ghi_chu = ghiChuCu;
        _isActionLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Lỗi hệ thống, không thể lưu dữ liệu vào DB!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '---';
    if (date is DateTime) {
      return DateFormat('dd/MM/yyyy').format(date);
    }
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(date.toString()));
    } catch (_) {
      return date.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                )
              : _errorMess != null
              ? Center(
                  child: Text(
                    _errorMess!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : _lichTiemList.isEmpty
              ? const Center(child: Text('Chưa có lịch tiêm nào được đồng bộ.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _lichTiemList.length,
                  itemBuilder: (context, index) {
                    final item = _lichTiemList[index];
                    final isDone =
                        (item.trang_thai?.trim() ?? '') == 'Đã thực hiện';

                    final tenVaccine =
                        item.danhMucVaccine?.ten_vaccine ??
                        'Vaccine #${item.id_vaccine}';
                    final phongBenh = item.danhMucVaccine?.phong_benh != null
                        ? ' (${item.danhMucVaccine?.phong_benh})'
                        : '';

                    final ngayDuKienStr = _formatDate(item.ngay_du_kien);

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: isDone
                              ? Colors.green[100]
                              : Colors.orange[100],
                          child: Icon(
                            isDone
                                ? Icons.check_circle
                                : Icons.medical_services,
                            color: isDone ? Colors.green : Colors.orange[800],
                          ),
                        ),
                        title: Text(
                          '$tenVaccine$phongBenh',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                            color: isDone ? Colors.grey : Colors.black87,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            if (item.danhMucVaccine?.ngay_tuoi != null)
                              Text(
                                'Độ tuổi tiêm: ${item.danhMucVaccine?.ngay_tuoi} ngày tuổi',
                              ),
                            if(item.danhMucVaccine?.phuong_thuc != null)
                              Text('Phương thức: ${item.danhMucVaccine?.phuong_thuc}'),
                            Text(
                              item.ghi_chu?.isNotEmpty == true
                                  ? 'Ghi chú: ${item.ghi_chu}'
                                  : 'Không có ghi chú',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ngày dự kiến: $ngayDuKienStr',
                              style: TextStyle(
                                color: isDone ? Colors.grey : Colors.red[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isDone && item.ngay_thuc_hien != null) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.edit_calendar,
                                    size: 14,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Ngày thực tế: ${_formatDate(item.ngay_thuc_hien)}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        trailing: Checkbox(
                          activeColor: Colors.green,
                          value: isDone,
                          onChanged: isDone
                              ? null
                              : (value) {
                                  if (value != null) {
                                    _handleCheckboxChanged(item, value);
                                  }
                                },
                        ),
                      ),
                    );
                  },
                ),

          if (_isActionLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  elevation: 5,
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.orange),
                        SizedBox(height: 16),
                        Text(
                          'Đang đồng bộ cơ sở dữ liệu...',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
