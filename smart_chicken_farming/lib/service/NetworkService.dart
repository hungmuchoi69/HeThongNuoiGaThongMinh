import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class NetworkService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static bool _isNoInternetDialogShowing = false;

  final Connectivity _connectivity = Connectivity();

  Stream<List<ConnectivityResult>> get connectivityStream =>
      _connectivity.onConnectivityChanged;

  Future<bool> hasIntenet() async {
    List<ConnectivityResult> results = await _connectivity.checkConnectivity();
    if (results.contains(ConnectivityResult.none)) {
      return false;
    }
    return true;
  }

  static void showNoInternetDialog({BuildContext? context}) {
    if (_isNoInternetDialogShowing) return;

    final targetContext = context ?? navigatorKey.currentContext;
    if (targetContext == null || !targetContext.mounted) return;

    _isNoInternetDialogShowing = true;

    showDialog(
      context: targetContext,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.blue, size: 28),
            SizedBox(width: 12),
            Text(
              'Mất Kết Nối Mạng',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Hệ thống không thể kết nối Internet. Vui lòng kiểm tra lại Wifi hoặc dữ liệu di động của bạn.',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 12, right: 16),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => dismissNoInternetDialog(ctx: ctx),
            child: const Text(
              'XÁC NHẬN',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static void dismissNoInternetDialog({BuildContext? ctx}) {
    if (!_isNoInternetDialogShowing) return;

    _isNoInternetDialogShowing = false;

    if (ctx != null && ctx.mounted) {
      Navigator.of(ctx, rootNavigator: true).maybePop();
      return;
    }

    navigatorKey.currentState?.pop();
  }
}
