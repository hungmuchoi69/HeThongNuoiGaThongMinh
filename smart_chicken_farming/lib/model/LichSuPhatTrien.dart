class Lichsuphattrien {
  final int? id;
  final DateTime ngay;
  final double? nhiet_do_tb;
  final double? do_am_tb;
  final double? tds_tb;
  final double? gas_tb;
  final double? trong_luong_tb;
  final double? he_so_FCR;
  final double? ti_le_song;
  final int id_lua_ga;

  Lichsuphattrien({
    this.id,
    required this.ngay,
    this.nhiet_do_tb,
    this.do_am_tb,
    this.tds_tb,
    this.gas_tb,
    required this.trong_luong_tb,
    required this.he_so_FCR,
    required this.ti_le_song,
    required this.id_lua_ga,
  });

  factory Lichsuphattrien.fromJson(Map<String, dynamic> json) {
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

    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return Lichsuphattrien(
      id: parseInt(json['id']),
      ngay: parseDate(json['ngay']),
      nhiet_do_tb: parseDouble(json['nhiet_do_tb']),
      do_am_tb: parseDouble(json['do_am_tb']),
      tds_tb: parseDouble(json['tds_tb']),
      gas_tb: parseDouble(json['gas_tb']),
      trong_luong_tb: parseDouble(json['trong_luong_tb']),
      he_so_FCR: parseDouble(json['he_so_FCR']),
      ti_le_song: parseDouble(json['ti_le_song']),
      id_lua_ga: parseInt(json['id_lua_ga']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ngay': ngay.toIso8601String(),
      'trong_luong_tb': trong_luong_tb,
      'he_so_FCR': he_so_FCR,
      'ti_le_song': ti_le_song,
      'luaGa': {
        'id': id_lua_ga
      },
    };
  }
}
