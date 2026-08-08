class Thongbao {
  final int id;
  final String tieu_de;
  final String noi_dung;
  final String loai_tb;
  bool da_doc;
  final DateTime thoi_gian_tao;

  Thongbao({
    required this.id,
    required this.tieu_de,
    required this.noi_dung,
    required this.loai_tb,
    required this.da_doc,
    required this.thoi_gian_tao,
  });

  factory Thongbao.fromJson(Map<String, dynamic> json) {
    return Thongbao(
      id: json['id'] as int,
      tieu_de: json['tieu_de'] as String,
      noi_dung: json['noi_dung'] as String,
      loai_tb: json['loai_tb'] as String,
      da_doc: json['da_doc'] as bool,
      thoi_gian_tao: DateTime.parse(json['thoi_gian_tao'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tieu_de': tieu_de,
      'noi_dung': noi_dung,
      'loai_tb': loai_tb,
      'da_doc': da_doc,
      'thoi_gian_tao': thoi_gian_tao.toIso8601String(),
    };
  }
}
