import 'package:smart_chicken_farming/model/DanhMucVaccine.dart';

class Lichtiemthucte {
  final int? id;
  final DateTime? ngay_du_kien;
  DateTime? ngay_thuc_hien; 
  String? trang_thai;
  String? ghi_chu; 
  final int? id_lua_ga;
  final int? id_vaccine;

  Danhmucvaccine? danhMucVaccine; 

  Lichtiemthucte({
    this.id,
    this.ngay_du_kien,
    this.ngay_thuc_hien,
    this.trang_thai,
    this.ghi_chu,
    this.id_lua_ga,
    this.id_vaccine,
    this.danhMucVaccine,
  });

  factory Lichtiemthucte.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return DateTime(value[0], value[1], value[2]); 
      }
      return DateTime.tryParse(value.toString());
    }

    return Lichtiemthucte(
      id: json['id'] as int?,
      ngay_du_kien: parseDateTime(json['ngay_du_kien'] ?? json['ngayTiemDuKien']),
      ngay_thuc_hien: parseDateTime(json['ngay_thuc_hien'] ?? json['ngayThucHien']),
      trang_thai: (json['trang_thai'] ?? json['trangThai']) as String?,
      ghi_chu: (json['ghi_chu'] ?? json['ghiChu']) as String?,
      id_lua_ga: (json['id_lua_ga'] ?? json['idLuaGa'] ?? json['id_dan_ga']) as int?,
      id_vaccine: (json['id_vaccine'] ?? json['idVaccine']) as int?,
      danhMucVaccine: (json['danhMucVaccine'] != null || json['danh_muc_vaccine'] != null)
          ? Danhmucvaccine.fromJson(Map<String, dynamic>.from(json['danhMucVaccine'] ?? json['danh_muc_vaccine']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ngay_du_kien': ngay_du_kien?.toIso8601String(),
      'ngay_thuc_hien': ngay_thuc_hien?.toIso8601String(),
      'trang_thai': trang_thai,
      'ghi_chu': ghi_chu,
      'id_lua_ga': id_lua_ga,
      'id_vaccine': id_vaccine,
      'danhMucVaccine': danhMucVaccine?.toJson(),
    };
  }
}