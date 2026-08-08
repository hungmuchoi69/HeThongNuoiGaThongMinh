class Cambienhomnay {
  final int id;
  final double nhiet_do;
  final double do_am;
  final int tds;
  final bool silo_status;
  final int gas;
  final DateTime logged_at;

  Cambienhomnay({
    required this.id,
    required this.nhiet_do,
    required this.do_am,
    required this.tds,
    required this.silo_status,
    required this.gas,
    required this.logged_at,
  });

  factory Cambienhomnay.fromJson(Map<String, dynamic> json) {
    bool parseBoolValue(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value.toInt() == 1;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return false;
    }

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

    return Cambienhomnay(
      id: parseInt(json['id']),
      nhiet_do: parseDouble(json['nhiet_do']),
      do_am: parseDouble(json['do_am']),
      tds: parseInt(json['tds']),
      silo_status: parseBoolValue(json['silo_status']),
      gas: parseInt(json['gas']),
      logged_at: parseDate(json['logged_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nhiet_do': nhiet_do,
      'do_am': do_am,
      'tds': tds,
      'silo_status': silo_status,
      'gas': gas,
      'logged_at': logged_at.toIso8601String(),
    };
  }
}
