class Loaichiphi {
  final int id;
  final String ten_loai;
  final String mo_ta;

  Loaichiphi({
    required this.id,
    required this.ten_loai,
    required this.mo_ta,
  });

  factory Loaichiphi.fromJson(Map<String,dynamic> json){
    return Loaichiphi(
      id: json['id'] as int,
      ten_loai: json['ten_loai'] as String,
      mo_ta: json['mo_ta'] as String,
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'id': id,
      'ten_loai': ten_loai,
      'mo_ta': mo_ta,
    };
  }
}