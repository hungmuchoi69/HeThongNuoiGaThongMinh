class Danhmucvaccine {
  final int? id;
  final String? ten_vaccine;
  final int? ngay_tuoi;
  final String? phong_benh;
  final String? phuong_thuc;

  Danhmucvaccine({
    this.id,
    this.ten_vaccine,
    this.ngay_tuoi,
    this.phong_benh,
    this.phuong_thuc,
  });

  factory Danhmucvaccine.fromJson(Map<String, dynamic> json) {
    return Danhmucvaccine(
      id: json['id'] as int?,
      ten_vaccine: (json['ten_vaccine'] ?? json['tenVaccine']) as String?,
      ngay_tuoi: (json['ngay_tuoi'] ?? json['ngayTuoi']) as int?,
      phong_benh: (json['phong_benh'] ?? json['phongBenh']) as String?,
      phuong_thuc: (json['phuong_thuc'] ?? json['phuongThuc']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ten_vaccine': ten_vaccine,
      'ngay_tuoi': ngay_tuoi,
      'phong_benh': phong_benh,
      'phuong_thuc': phuong_thuc,
    };
  }
}