class Chiphichannuoi {
  final int? id;
  final DateTime ngay_chi_tieu;
  final int so_tien;
  final String? ghi_chu;
  final int id_loai_chi_phi;
  final int id_lua_ga;

  Chiphichannuoi({
    this.id,
    required this.ngay_chi_tieu,
    required this.so_tien,
    required this.ghi_chu,
    required this.id_loai_chi_phi,
    required this.id_lua_ga,
  });

  factory Chiphichannuoi.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic value, String fallbackKey) {
      if (value is Map<String, dynamic>) {
        return value['id'] as int;
      }
      return json[fallbackKey] as int;
    }

    return Chiphichannuoi(
      id: json['id'] as int,
      ngay_chi_tieu: DateTime.parse(json['ngay_chi_tieu'] as String),
      so_tien: json['so_tien'] as int,
      ghi_chu: json['ghi_chu'] as String?,
      id_loai_chi_phi: parseId(json['loaiChiPhi'], 'id_loai_chi_phi'),
      id_lua_ga: parseId(json['luaGa'], 'id_lua_ga'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ngay_chi_tieu': ngay_chi_tieu.toIso8601String(),
      'so_tien': so_tien,
      'ghi_chu': ghi_chu,
      'loaiChiPhi': {'id': id_loai_chi_phi},
      'luaGa': {'id': id_lua_ga},
    };
  }
}
