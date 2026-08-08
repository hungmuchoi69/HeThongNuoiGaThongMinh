class LuaGa {
  final int? id;
  final String? giongGa;
  final String? tenLua;
  final DateTime ngayNhap;
  final DateTime ngayXuatDuKien;
  final int soLuongBanDau;
  int? soLuongHienTai;
  String trangThai;
  int? loiNhuan;
  final String userId;

  LuaGa({
    this.id,
    this.giongGa,
    this.tenLua,
    required this.ngayNhap,
    required this.ngayXuatDuKien,
    required this.soLuongBanDau,
    this.soLuongHienTai,
    required this.trangThai,
    this.loiNhuan,
    required this.userId,
  });

  factory LuaGa.fromJson(Map<String, dynamic> json) {
    return LuaGa(
      id: json['id'] as int,
      giongGa: json['giong_ga'] as String?,
      tenLua: json['ten_lua'] as String?,
      ngayNhap: DateTime.parse(json['ngay_nhap'] as String),
      ngayXuatDuKien: DateTime.parse(json['ngay_xuat_du_kien'] as String),
      soLuongBanDau: json['so_luong_ban_dau'] as int,
      soLuongHienTai: json['so_luong_hien_tai'] as int?,
      trangThai: json['trang_thai'] as String,
      loiNhuan: json['loi_nhuan'] as int?,
      userId: json['user_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'giong_ga': giongGa,
      'ten_lua': tenLua,
      'ngay_nhap': ngayNhap.toIso8601String(),
      'ngay_xuat_du_kien': ngayXuatDuKien.toIso8601String(),
      'so_luong_ban_dau': soLuongBanDau,
      'so_luong_hien_tai': soLuongHienTai,
      'trang_thai': trangThai,
      'loi_nhuan': loiNhuan,
      'user_id':userId,
    };
  }
}