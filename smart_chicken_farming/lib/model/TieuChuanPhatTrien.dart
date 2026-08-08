class Tieuchuanphattrien {
  final int id;
  final int ngay_tuoi;
  final double trong_luong_tc;
  final double luong_thuc_an_tc;
  final double nhiet_do_toi_thieu;
  final double nhiet_do_toi_da;
  final double do_am_tc;

  Tieuchuanphattrien({
    required this.id,
    required this.ngay_tuoi,
    required this.trong_luong_tc,
    required this.luong_thuc_an_tc,
    required this.nhiet_do_toi_thieu,
    required this.nhiet_do_toi_da,
    required this.do_am_tc,
  });

  factory Tieuchuanphattrien.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Tieuchuanphattrien(
      id: parseInt(json['id']),
      ngay_tuoi: parseInt(json['ngay_tuoi']),
      trong_luong_tc: parseDouble(json['trong_luong_tc']),
      luong_thuc_an_tc: parseDouble(json['luong_thuc_an_tieu_chuan']),
      nhiet_do_toi_thieu: parseDouble(json['nhiet_do_toi_thieu']),
      nhiet_do_toi_da: parseDouble(json['nhiet_do_toi_da']),
      do_am_tc: parseDouble(json['do_am_tc']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tuan_tuoi': ngay_tuoi,
      'trong_luong_tc': trong_luong_tc,
      'luong_thuc_an_tc': luong_thuc_an_tc,
      'nhiet_do_toi_thieu': nhiet_do_toi_thieu,
      'nhiet_do_toi_da': nhiet_do_toi_da,
      'do_am_tc': do_am_tc,
    };
  }
}
