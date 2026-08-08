import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_chicken_farming/model/ChiPhiChanNuoi.dart';
import 'package:smart_chicken_farming/model/LuaGa.dart';
import 'package:smart_chicken_farming/service/APIService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_chicken_farming/page/homePage.dart';

class CreateBatchScreen extends StatefulWidget {
  const CreateBatchScreen({Key? key}) : super(key: key);

  @override
  State<CreateBatchScreen> createState() => _CreateBatchScreenState();
}

class _CreateBatchScreenState extends State<CreateBatchScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _batchNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _soTienController = TextEditingController();

  String _selectedBreed = 'Gà Ta';
  final List<String> _chickenBreeds = [
    'Gà Ta',
    'Gà Mía',
    'Gà Lương Phượng',
    'Gà Tam Hoàng',
  ];

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("Phiên đăng nhập hết hạn");

      LuaGa luaGa = LuaGa(
        giongGa: _selectedBreed,
        tenLua: _batchNameController.text.trim(),
        ngayNhap: _selectedDate,
        ngayXuatDuKien: _selectedDate.add(const Duration(days: 120)),
        soLuongBanDau: int.parse(_quantityController.text.trim()),
        soLuongHienTai: int.parse(_quantityController.text.trim()),
        trangThai: "RAISING",
        userId: user.id,
      );

      await Apiservice.createLuaGa(luaGa, context: context);
      await Future.delayed(const Duration(milliseconds: 1000));
      LuaGa? lg = await Apiservice.findByUserIdAndTrangThai(user.id, "RAISING", context: context);
      if (lg != null) {
        Chiphichannuoi chiphichannuoi = Chiphichannuoi(
          ngay_chi_tieu: DateTime.now(),
          so_tien: int.parse(_soTienController.text.trim()) * luaGa.soLuongBanDau,
          ghi_chu: "Chi phí nhập gà",
          id_loai_chi_phi: 1,
          id_lua_ga: lg.id!,
        );
        Apiservice.createChiPhiChanNuoi(chiphichannuoi,context: context);
      }
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Khởi tạo lứa gà mới thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Khởi Tạo Lứa Nuôi Mới',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange.shade700,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.shade100),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Hệ thống nhận diện bạn chưa có lứa nuôi nào đang hoạt động. Vui lòng khai báo thông tin ban đầu.',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),

                      // 1. Ô nhập tên lứa gà
                      const Text(
                        'Tên lứa nuôi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _batchNameController,
                        decoration: InputDecoration(
                          hintText: 'Ví dụ: Lứa Gà Thịt Đợt 1',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(
                            Icons.drive_file_rename_outline,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng không để trống tên lứa gà';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // 2. Dropdown chọn giống gà
                      const Text(
                        'Giống gà nuôi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedBreed,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.pets),
                        ),
                        items: _chickenBreeds.map((String breed) {
                          return DropdownMenuItem<String>(
                            value: breed,
                            child: Text(breed),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedBreed = newValue!;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // 3. Ô nhập số lượng gà
                      const Text(
                        'Số lượng nhập chuồng (con)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _quantityController,
                        keyboardType:
                            TextInputType.number, // Chỉ hiện bàn phím số
                        decoration: InputDecoration(
                          hintText: 'Nhập số lượng. Ví dụ: 500',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.numbers),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập số lượng gà';
                          }
                          final num? quantity = num.tryParse(value);
                          if (quantity == null || quantity <= 0) {
                            return 'Số lượng phải là số nguyên dương lớn hơn 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // 4. Chọn ngày nhập chuồng
                      const Text(
                        'Ngày bắt đầu nuôi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd/MM/yyyy').format(_selectedDate),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const Icon(
                                Icons.calendar_month,
                                color: Colors.orange,
                              ),
                            ],
                          ),
                        ),
                      ),
                      //nhap chi phi con giong
                      const SizedBox(height: 20),
                      const Text(
                        'Số tiền cho 1 con giống (vnd)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _soTienController,
                        keyboardType:
                            TextInputType.number, // Chỉ hiện bàn phím số
                        decoration: InputDecoration(
                          hintText: 'Nhập số tiền. Ví dụ: 12500',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.numbers),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập số tiền cho một con giống';
                          }
                          final num? soTien = num.tryParse(value);
                          if (soTien == null || soTien <= 0) {
                            return 'Số tiền phải là số nguyên dương lớn hơn 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),

                      // 5. Nút submit kích hoạt vụ nuôi
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _submitData,
                          child: const Text(
                            'KÍCH HOẠT VỤ NUÔI MỚI',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _batchNameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}
