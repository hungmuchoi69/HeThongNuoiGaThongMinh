import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:smart_chicken_farming/model/CamBienHomNay.dart';
import 'package:smart_chicken_farming/model/ChiPhiChanNuoi.dart';
import 'package:smart_chicken_farming/model/DanhMucVaccine.dart';
import 'package:http/http.dart' as http;
import 'package:smart_chicken_farming/model/LichSuPhatTrien.dart';
import 'package:smart_chicken_farming/model/LichTiemThucTe.dart';
import 'package:smart_chicken_farming/model/LoaiChiPhi.dart';
import 'package:smart_chicken_farming/model/LuaGa.dart';
import 'package:smart_chicken_farming/model/ThongBao.dart';
import 'package:smart_chicken_farming/model/TieuChuanPhatTrien.dart';
import 'package:smart_chicken_farming/service/NetworkService.dart';

class Apiservice {
  static const String baseUrl = 'https://be-78cv.onrender.com/api';

  static void _handleNetworkFailure(BuildContext? context) {
    if (context != null && context.mounted) {
      NetworkService.showNoInternetDialog(context: context);
    } else {
      NetworkService.showNoInternetDialog();
    }
  }

  static Future<bool> _checkNetwork(BuildContext? context) async {
    final networkService = NetworkService();
    bool hasInternet = await networkService.hasIntenet();

    if (!hasInternet) {
      _handleNetworkFailure(context);
      return false;
    }
    return true;
  }

  //Read
  Future<List<Danhmucvaccine>> getAllDanhMuCVaccine({
    BuildContext? context,
  }) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/DanhMucVaccine'));
      if (res.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(res.bodyBytes));

        List<Danhmucvaccine> list = body
            .map(
              (dynamic item) =>
                  Danhmucvaccine.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        return list;
      } else {
        return [];
      }
    } catch (e) {
      _handleNetworkFailure(context);
      return [];
    }
  }

  static Future<List<Chiphichannuoi>> getAllChiPhiChanNuoi(
    int idLuaGa, {
    BuildContext? context,
  }) async {
    if (!await _checkNetwork(context)) {
      return [];
    }
    try {
      final res = await http.get(Uri.parse('$baseUrl/ChiPhiChanNuoi/$idLuaGa'));
      if (res.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(res.bodyBytes));

        List<Chiphichannuoi> list = body
            .map(
              (dynamic item) =>
                  Chiphichannuoi.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        return list;
      } else {
        _handleNetworkFailure(context);
        return [];
      }
    } catch (e) {
      _handleNetworkFailure(context);
      return [];
    }
  }

  static Future<List<Lichsuphattrien>> getAllLichSuPhatTrien(
    int idLuaGa, {
    BuildContext? context,
  }) async {
    if (!await _checkNetwork(context)) {
      return [];
    }

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/LichSuPhatTrien/$idLuaGa'),
      );
      if (res.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(res.bodyBytes));

        List<Lichsuphattrien> list = body
            .map(
              (dynamic item) =>
                  Lichsuphattrien.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        return list;
      }
    } catch (e) {
      _handleNetworkFailure(context);
      return [];
    }

    return [];
  }

  static Future<List<Lichtiemthucte>> getAllLichTiemThucTe(
    int idLuaGa, {
    BuildContext? context,
  }) async {
    if (!await _checkNetwork(context)) {
      return [];
    }
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/LichTiemThucTe/LuaGa/$idLuaGa'),
      );
      if (res.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(res.bodyBytes));

        List<Lichtiemthucte> list = body
            .map(
              (dynamic item) =>
                  Lichtiemthucte.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        return list;
      }
    } catch (e) {
      _handleNetworkFailure(context);
      return [];
    }

    return [];
  }

  static Future<List<Loaichiphi>> getAllLoaiChiPhi({
    BuildContext? context,
  }) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/LoaiChiPhi'));
      if (res.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(res.bodyBytes));

        List<Loaichiphi> list = body
            .map(
              (dynamic item) =>
                  Loaichiphi.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        return list;
      } else {
        return [];
      }
    } catch (e) {
      _handleNetworkFailure(context);
      return [];
    }
  }

  Future<List<LuaGa>> getAllLuaGa({BuildContext? context}) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/DanhMucVaccine'));
      if (res.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(res.bodyBytes));

        List<LuaGa> list = body
            .map((dynamic item) => LuaGa.fromJson(item as Map<String, dynamic>))
            .toList();

        return list;
      } else {
        return [];
      }
    } catch (e) {
      _handleNetworkFailure(context);
      return [];
    }
  }

  static Future<List<Thongbao>> getThongBaoByLuaGa(
    int idLuaGa, {
    BuildContext? context,
  }) async {
    if (!await _checkNetwork(context)) {
      return [];
    }
    try {
      final res = await http.get(Uri.parse('$baseUrl/ThongBao/$idLuaGa'));
      if (res.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(res.bodyBytes));

        List<Thongbao> list = body
            .map(
              (dynamic item) => Thongbao.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        return list;
      }
    } catch (e) {
      _handleNetworkFailure(context);
      return [];
    }

    return [];
  }

  static Future<List<Tieuchuanphattrien>> getAllTieuChuanPhatTrien({
    BuildContext? context,
  }) async {
    if (!await _checkNetwork(context)) {
      return [];
    }
    try {
      final res = await http.get(Uri.parse('$baseUrl/TieuChuanPhatTrien'));
      if (res.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(res.bodyBytes));

        List<Tieuchuanphattrien> list = body
            .map(
              (dynamic item) =>
                  Tieuchuanphattrien.fromJson(item as Map<String, dynamic>),
            )
            .toList();
        return list;
      }
    } catch (e) {
      _handleNetworkFailure(context);
      return [];
    }

    return [];
  }

  static Future<List<Cambienhomnay>> getAllCamBienHomNayByLuaGa(
    int idLuaGa, {
    BuildContext? context,
  }) async {
    if (!await _checkNetwork(context)) {
      return [];
    }
    try {
      final res = await http.get(Uri.parse('$baseUrl/CamBienHomNay/$idLuaGa'));
      if (res.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(res.bodyBytes));

        List<Cambienhomnay> list = body
            .map(
              (dynamic item) =>
                  Cambienhomnay.fromJson(item as Map<String, dynamic>),
            )
            .toList();
        return list;
      }
    } catch (e) {
      _handleNetworkFailure(context);
      return [];
    }

    return [];
  }

  //Create
  static Future<bool> createLuaGa(LuaGa luaga, {BuildContext? context}) async {
    if (!await _checkNetwork(context)) {
      return false;
    }
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/LuaGa'),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(luaga.toJson()),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _handleNetworkFailure(context);
      return false;
    }
  }

  static Future<bool> createChiPhiChanNuoi(
    Chiphichannuoi chiphi, {
    BuildContext? context,
  }) async {
    if (!await _checkNetwork(context)) {
      return false;
    }
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/ChiPhiChanNuoi'),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(chiphi.toJson()),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _handleNetworkFailure(context);
      return false;
    }
  }

  Future<bool> createLichTiemThucTe(
    Lichtiemthucte lichTiem, {
    BuildContext? context,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/LichTiemThucTe'),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(lichTiem.toJson()),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _handleNetworkFailure(context);
      return false;
    }
  }

  static Future<bool> createLichSuPhatTrien(
    Lichsuphattrien lsuPhatTrien, {
    BuildContext? context,
  }) async {
    if (!await _checkNetwork(context)) {
      return false;
    }
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/LichSuPhatTrien'),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(lsuPhatTrien.toJson()),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _handleNetworkFailure(context);
      return false;
    }
  }

  //Update
  static Future<bool> markAsRead(
    int idThongBao,
    String userId,
    int idLuaGa, {
    BuildContext? context,
  }) async {
    if (!await _checkNetwork(context)) {
      return false;
    }
    final String url =
        "$baseUrl/ThongBao/read/$idThongBao?userId=$userId&idLuaGa=$idLuaGa";
    try {
      final response = await http.put(Uri.parse(url));
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      _handleNetworkFailure(context);
      return false;
    }
  }

  static Future<bool> markAllRead(
    String userId,
    int idLuaGa, {
    BuildContext? context,
  }) async {
    if (!await _checkNetwork(context)) {
      return false;
    }
    final String url =
        "$baseUrl/ThongBao/ReadAll?idLuaGa=$idLuaGa&userId=$userId";
    try {
      final response = await http.put(Uri.parse(url));
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      _handleNetworkFailure(context);
      return false;
    }
  }

  static Future<bool> updLichTiemThucTe(
    int id,
    Lichtiemthucte lichTiem, {
    BuildContext? context,
  }) async {
    if (!await _checkNetwork(context)) {
      return false;
    }
    final String url = "$baseUrl/LichTiemThucTe/$id";
    try {
      final res = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(lichTiem.toJson()),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _handleNetworkFailure(context);
      return false;
    }
  }

  static Future<bool> updLuaGa(
    int id,
    LuaGa luaGa, {
    BuildContext? context,
  }) async {
    if (!await _checkNetwork(context)) {
      return false;
    }
    final String url = "$baseUrl/LuaGa/$id";
    try {
      final res = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(luaGa.toJson()),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _handleNetworkFailure(context);
      return false;
    }
  }

  //Delete

  //Others
  static Future<bool> checkActiveLuaGa(
    String uid, {
    BuildContext? context,
  }) async {
    if (!await _checkNetwork(context)) {
      return false;
    }
    final url = Uri.parse("$baseUrl/LuaGa/Check/$uid");
    try {
      final response = await http
          .get(
            url,
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final Map<String, dynamic> resData = jsonDecode(response.body);
        return resData['hasActiveLuaGa'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      _handleNetworkFailure(context);
      return false;
    }
  }

  static Future<int> countUnreadNotification(
    int id, {
    BuildContext? context,
  }) async {
    if (!await _checkNetwork(context)) {
      return -1;
    }
    final url = Uri.parse("$baseUrl/ThongBao/ChuaDoc/$id");
    try {
      final response = await http
          .get(
            url,
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final Map<String, dynamic> resData = jsonDecode(response.body);
        return resData['count'] ?? -1;
      } else {
        return -1;
      }
    } catch (e) {
      _handleNetworkFailure(context);
      return -1;
    }
  }

  static Future<int> getKhoiLuongTA(
    int ngayTuoi, {
    BuildContext? context,
  }) async {
    if (!await _checkNetwork(context)) {
      return -1;
    }
    final url = Uri.parse("$baseUrl/TieuChuanPhatTrien/ThucAn/$ngayTuoi");
    try {
      final response = await http
          .get(
            url,
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final Map<String, dynamic> resData = jsonDecode(response.body);
        return resData['KhoiLuongTA'] ?? -1;
      } else {
        return -1;
      }
    } catch (e) {
      _handleNetworkFailure(context);
      return -1;
    }
  }

  //find
  static Future<LuaGa?> findByUserIdAndTrangThai(
    String id,
    String status, {
    BuildContext? context,
  }) async {
    if (!await _checkNetwork(context)) {
      return null;
    }
    final url = Uri.parse("$baseUrl/LuaGa/$id/$status");
    try {
      final response = await http
          .get(
            url,
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final Map<String, dynamic> resData = jsonDecode(response.body);
        LuaGa luaGa = LuaGa(
          id: resData['id'],
          tenLua: resData['ten_lua'],
          giongGa: resData['giong_ga'],
          ngayNhap: DateTime.parse(resData['ngay_nhap'].toString()),
          ngayXuatDuKien: DateTime.parse(
            resData['ngay_xuat_du_kien'].toString(),
          ),
          soLuongBanDau: resData['so_luong_ban_dau'],
          soLuongHienTai: resData['so_luong_hien_tai'],
          trangThai: resData['trang_thai'],
          loiNhuan: resData['loi_nhuan'],
          userId: resData['user_id'],
        );
        return luaGa;
      } else {
        return null;
      }
    } catch (e) {
      _handleNetworkFailure(context);
      return null;
    }
  }

  static Future<LuaGa?> findLuaGaByID(int id, {BuildContext? context}) async {
    if (!await _checkNetwork(context)) {
      return null;
    }
    final url = Uri.parse("$baseUrl/LuaGa/find/$id");
    try {
      final response = await http
          .get(
            url,
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final Map<String, dynamic> resData = jsonDecode(response.body);
        LuaGa luaGa = LuaGa(
          id: resData['id'],
          tenLua: resData['ten_lua'],
          giongGa: resData['giong_ga'],
          ngayNhap: DateTime.parse(resData['ngay_nhap'].toString()),
          ngayXuatDuKien: DateTime.parse(
            resData['ngay_xuat_du_kien'].toString(),
          ),
          soLuongBanDau: resData['so_luong_ban_dau'],
          soLuongHienTai: resData['so_luong_hien_tai'],
          trangThai: resData['trang_thai'],
          loiNhuan: resData['loi_nhuan'],
          userId: resData['user_id'],
        );
        return luaGa;
      } else {
        return null;
      }
    } catch (e) {
      _handleNetworkFailure(context);
      return null;
    }
  }

  static Future<Tieuchuanphattrien?> findTCPTByNgayTuoi(
    int ngayTuoi, {
    BuildContext? context,
  }) async {
    if (!await _checkNetwork(context)) {
      return null;
    }
    final url = Uri.parse("$baseUrl/TieuChuanPhatTrien/NgayTuoi/$ngayTuoi");
    try {
      final response = await http
          .get(
            url,
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final Map<String, dynamic> resData = jsonDecode(response.body);

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

        Tieuchuanphattrien tieuchuanphattrien = Tieuchuanphattrien(
          id: parseInt(resData['id']),
          ngay_tuoi: parseInt(resData['ngay_tuoi']),
          trong_luong_tc: parseDouble(resData['trong_luong_tc']),
          luong_thuc_an_tc: parseDouble(resData['luong_thuc_an_tieu_chuan']),
          nhiet_do_toi_thieu: parseDouble(resData['nhiet_do_toi_thieu']),
          nhiet_do_toi_da: parseDouble(resData['nhiet_do_toi_da']),
          do_am_tc: parseDouble(resData['do_am_tc']),
        );
        return tieuchuanphattrien;
      } else {
        return null;
      }
    } catch (e) {
      _handleNetworkFailure(context);
      return null;
    }
  }
}
