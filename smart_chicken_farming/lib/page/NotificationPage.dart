import 'package:flutter/material.dart';
import 'package:smart_chicken_farming/model/LuaGa.dart';
import 'package:smart_chicken_farming/model/ThongBao.dart';
import 'package:smart_chicken_farming/page/AnalyticsScreen.dart';
import 'package:smart_chicken_farming/service/APIService.dart';
import 'package:smart_chicken_farming/service/UserSession.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key, required this.idLuaGa});

  final int idLuaGa;

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Thongbao> notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final list = await Apiservice.getThongBaoByLuaGa(widget.idLuaGa,context: context);
      if (!mounted) return;
      setState(() {
        notifications = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải thông báo. Vui lòng thử lại.';
        _isLoading = false;
      });
    }
  }

  void _markAsRead(int index) async {
    final item = notifications[index];
    await Apiservice.markAsRead(item.id,userSession.id!, widget.idLuaGa,context: context);
    LuaGa? luaGa = await Apiservice.findLuaGaByID(widget.idLuaGa, context: context);
    if(luaGa == null) return;
    String type=item.loai_tb;
    if(type=="vaccine"){
      Navigator.push(context, MaterialPageRoute(builder: (context)=>AnalyticsScreen(luaGa: luaGa, initTab: 3,)));
    }else if(type=="growth"){
      Navigator.push(context, MaterialPageRoute(builder: (context)=>AnalyticsScreen(luaGa: luaGa, initTab: 1,)));
    }
    setState(() {
      notifications[index].da_doc=true;
    });
  }

  void _markAllAsRead() async{
    if (notifications.every((element) => element.da_doc)) return;
    await Apiservice.markAllRead(userSession.id!, widget.idLuaGa,context: context);
    setState(() {
      for(var item in notifications){
        item.da_doc=true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Đã đánh dấu đọc tất cả thông báo"),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'event':
        return Icons.error_outline_rounded;
      case 'vaccine':
        return Icons.vaccines;
      case 'growth' :
        return Icons.update;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'event':
        return Colors.redAccent;
      case 'vaccine':
        return Colors.amber.shade700;
      case 'growth' :
        return Colors.greenAccent;
      default:
        return Colors.blueAccent;
    }
  }

  String _formatTime(DateTime createdAt) {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    }
    if (diff.inDays == 1) {
      return 'Hôm qua';
    }
    return '${diff.inDays} ngày trước';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Thông báo hệ thống",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          // Nút đọc nhanh tất cả thông báo
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text(
              "Đọc tất cả",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.redAccent, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      itemCount: notifications.length,
      padding: const EdgeInsets.symmetric(vertical: 12),
      separatorBuilder: (context, index) => const SizedBox(height: 1),
      itemBuilder: (context, index) {
        final item = notifications[index];
        final bool isRead = item.da_doc;
        final Color categoryColor = _getColor(item.loai_tb);

        return InkWell(
          onTap: () => _markAsRead(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            color: isRead ? Colors.white : Colors.blue.withOpacity(0.04),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIcon(item.loai_tb),
                    color: categoryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.tieu_de,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isRead
                                    ? FontWeight.w600
                                    : FontWeight.bold,
                                color: isRead
                                    ? Colors.blueGrey.shade700
                                    : Colors.black,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.noi_dung,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isRead ? Colors.grey.shade600 : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(item.thoi_gian_tao),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 70,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            "Hộp thư trống trơn",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Hệ thống chuồng trại hiện tại rất ổn định.",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
