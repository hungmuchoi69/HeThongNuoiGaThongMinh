import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_chicken_farming/model/CamBienHomNay.dart';
import 'package:smart_chicken_farming/model/LichSuPhatTrien.dart';
import 'package:smart_chicken_farming/model/LuaGa.dart';
import 'package:smart_chicken_farming/model/TieuChuanPhatTrien.dart';
import 'package:smart_chicken_farming/page/GrowthEvaluationScreen.dart';
import 'package:smart_chicken_farming/page/HardwareControlPage.dart';
import 'package:smart_chicken_farming/page/LivestockCostPage.dart';
import 'package:smart_chicken_farming/page/VaccineManagementTab.dart';
import 'package:smart_chicken_farming/service/APIService.dart';
import 'package:smart_chicken_farming/service/UserSession.dart';
import 'package:smart_chicken_farming/service/mqttService.dart';
import 'package:smart_chicken_farming/service/NetworkService.dart';

class AnalyticsScreen extends StatefulWidget {
  final LuaGa luaGa;
  final int initTab;
  const AnalyticsScreen({super.key, required this.luaGa, this.initTab = 0});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MqttService _mqttService = MqttService();
  List<Cambienhomnay> _rawSensorData = [];
  List<Lichsuphattrien> _rawLichSuPhatTrien = [];

  List<FlSpot> _tempSpots = [];
  List<FlSpot> _humiSpots = [];
  List<FlSpot> _tdsSpots = [];
  List<FlSpot> _gasSpots = [];
  List<FlSpot> _tempLSSpots = [];
  List<FlSpot> _humiLSSpots = [];
  List<FlSpot> _tdsLSSpots = [];
  List<FlSpot> _trongLuongSpots = [];
  List<FlSpot> _gasLSSpots = [];

  int _ngayTuoi = 0;
  bool _isLoading = true;
  String? _errorMessage;
  Tieuchuanphattrien? _tieuChuan;
  bool _isManualMode = false;

  final ScrollController _tempChartController = ScrollController();
  final ScrollController _tdsChartController = ScrollController();
  final ScrollController _gasChartController = ScrollController();
  final ScrollController _trongLuongChartController = ScrollController();
  final ScrollController _tempLSChartController = ScrollController();
  final ScrollController _tdsLSChartController = ScrollController();
  final ScrollController _gasLSChartController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initData();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initTab,
    );
    _tabController.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    _tempChartController.dispose();
    _tdsChartController.dispose();
    _trongLuongChartController.dispose();
    _tempLSChartController.dispose();
    _tdsLSChartController.dispose();
    _gasChartController.dispose();
    _gasLSChartController.dispose();
    _tabController.removeListener(_handleTabSelection);
    super.dispose();
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging) return;

    if (_tabController.previousIndex == 2 && _tabController.index != 2) {
      if (_isManualMode) {
        _showLeaveControlTabDialog();
      } else {
        _resetHardwareToAuto();
      }
    }
  }

  Future<void> _showLeaveControlTabDialog() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cảnh báo rời trang'),
          content: const Text(
            'Bạn đang ở tab Điều khiển. Nếu rời khỏi tab này, hệ thống sẽ đặt thiết bị về chế độ Tự động để tránh sự cố. Bạn có chắc chắn muốn tiếp tục?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('HỦY BỎ'),
            ),
            ElevatedButton(
              onPressed: () {
                _resetHardwareToAuto();
                if (mounted) {
                  setState(() {
                    _isManualMode = false;
                  });
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('ĐỒNG Ý'),
            ),
          ],
        );
      },
    );

    if (shouldLeave != true && mounted && _tabController.index != 2) {
      _tabController.animateTo(2);
    }
  }

  Future<void> _handleLeaveAnalytics() async {
    if (_tabController.index != 2 || !_isManualMode) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cảnh báo rời trang'),
          content: const Text(
            'Hệ thống sẽ thiết lập lại các thiết bị về chế độ TỰ ĐỘNG để tránh sự cố trong chăn nuôi. Bạn có chắc chắn muốn rời khỏi màn hình này?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('HỦY BỎ'),
            ),
            ElevatedButton(
              onPressed: () {
                _resetHardwareToAuto();
                if (mounted) {
                  setState(() {
                    _isManualMode = false;
                  });
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('ĐỒNG Ý'),
            ),
          ],
        );
      },
    );

    if (shouldLeave == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _resetHardwareToAuto() {
    try {
      _mqttService.publishMessage(
        "chuong_ga/users/${userSession.id}/controls",
        '{"mode":"AUTO"}',
      );
    } catch (e) {
      print("Loi gui mqtt: $e");
    }
  }

  Future<void> _initData() async {
    try {
      if (!await NetworkService().hasIntenet()) {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Mất kết nối mạng. Vui lòng kiểm tra lại kết nối để xem dữ liệu.';
            _isLoading = false;
          });
        }
        NetworkService.showNoInternetDialog(context: context);
        return;
      }

      final now = DateTime.now();
      final diff = now.difference(widget.luaGa.ngayNhap).inDays;
      _ngayTuoi = diff <= 0 ? 1 : diff + 1;

      _rawSensorData = await Apiservice.getAllCamBienHomNayByLuaGa(
        widget.luaGa.id!,
        context: context,
      );
      _tieuChuan = await Apiservice.findTCPTByNgayTuoi(
        _ngayTuoi,
        context: context,
      );
      _rawLichSuPhatTrien = await Apiservice.getAllLichSuPhatTrien(
        widget.luaGa.id!,
        context: context,
      );

      _rawSensorData.sort((a, b) => a.logged_at.compareTo(b.logged_at));
      _rawLichSuPhatTrien.sort((a, b) => a.ngay.compareTo(b.ngay));

      _prepareChartSpots(_rawSensorData);
      _prepareChartLSSpots(_rawLichSuPhatTrien);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToEnd();
        });
      }
    } catch (e, st) {
      debugPrint('AnalyticsScreen._initData error: $e');
      debugPrintStack(stackTrace: st);
      if (mounted) {
        setState(() {
          _errorMessage = "Lỗi tải dữ liệu. Vui lòng thử lại!\n${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToEnd() {
    if (_tempChartController.hasClients) {
      _tempChartController.jumpTo(
        _tempChartController.position.maxScrollExtent,
      );
    }
    if (_gasChartController.hasClients) {
      _gasChartController.jumpTo(_gasChartController.position.maxScrollExtent);
    }
    if (_tdsChartController.hasClients) {
      _tdsChartController.jumpTo(_tdsChartController.position.maxScrollExtent);
    }
    if (_trongLuongChartController.hasClients) {
      _trongLuongChartController.jumpTo(
        _trongLuongChartController.position.maxScrollExtent,
      );
    }
    if (_tempLSChartController.hasClients) {
      _tempLSChartController.jumpTo(
        _tempLSChartController.position.maxScrollExtent,
      );
    }
    if (_tdsLSChartController.hasClients) {
      _tdsLSChartController.jumpTo(
        _tdsLSChartController.position.maxScrollExtent,
      );
    }
    if (_gasLSChartController.hasClients) {
      _gasLSChartController.jumpTo(
        _gasLSChartController.position.maxScrollExtent,
      );
    }
  }

  void _prepareChartSpots(List<Cambienhomnay> data) {
    if (data.isEmpty) {
      _tempSpots = [const FlSpot(0, 0), const FlSpot(1, 0)];
      _humiSpots = [const FlSpot(0, 0), const FlSpot(1, 0)];
      _tdsSpots = [const FlSpot(0, 0), const FlSpot(1, 0)];
      _gasSpots = [const FlSpot(0, 0), const FlSpot(1, 0)];
      return;
    }

    _tempSpots = data
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.nhiet_do))
        .toList();
    _humiSpots = data
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.do_am))
        .toList();
    _tdsSpots = data
        .asMap()
        .entries
        .map(
          (entry) => FlSpot(entry.key.toDouble(), entry.value.tds.toDouble()),
        )
        .toList();
    _gasSpots = data
        .asMap()
        .entries
        .map(
          (entry) => FlSpot(entry.key.toDouble(), entry.value.gas.toDouble()),
        )
        .toList();
  }

  void _prepareChartLSSpots(List<Lichsuphattrien> data) {
    if (data.isEmpty) {
      _tempLSSpots = [const FlSpot(0, 0), const FlSpot(1, 0)];
      _humiLSSpots = [const FlSpot(0, 0), const FlSpot(1, 0)];
      _tdsLSSpots = [const FlSpot(0, 0), const FlSpot(1, 0)];
      _trongLuongSpots = [const FlSpot(0, 0), const FlSpot(1, 0)];
      _gasLSSpots = [const FlSpot(0, 0), const FlSpot(1, 0)];
      return;
    }

    _tempLSSpots = data
        .where((item) => item.nhiet_do_tb != null && item.nhiet_do_tb != 0)
        .toList()
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.nhiet_do_tb!))
        .toList();
    _humiLSSpots = data
        .where((item) => item.do_am_tb != null && item.do_am_tb != 0)
        .toList()
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.do_am_tb!))
        .toList();
    _tdsLSSpots = data
        .where((item) => item.tds_tb != null && item.tds_tb != 0)
        .toList()
        .asMap()
        .entries
        .map(
          (entry) =>
              FlSpot(entry.key.toDouble(), entry.value.tds_tb!.toDouble()),
        )
        .toList();
    _trongLuongSpots = data
        .asMap()
        .entries
        .map(
          (entry) =>
              FlSpot(entry.key.toDouble(), entry.value.trong_luong_tb ?? 0),
        )
        .toList();
    _gasLSSpots = data
        .where((item) => item.gas_tb != null && item.gas_tb != 0)
        .toList()
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.gas_tb!))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleLeaveAnalytics();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black87,
              size: 20,
            ),
            onPressed: () async {
              await _handleLeaveAnalytics();
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.luaGa.tenLua!,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                "Ngày tuổi: $_ngayTuoi ngày | Giống: ${widget.luaGa.giongGa}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blueAccent,
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.sensors_rounded), text: "Hôm nay"),
              Tab(icon: Icon(Icons.analytics_rounded), text: "Tăng trưởng"),
              Tab(icon: Icon(Icons.hardware), text: "Điều khiển"),
              Tab(icon: Icon(Icons.vaccines), text: "Vaccine"),
              Tab(icon: Icon(Icons.money), text: "Chi Phí",)
            ],
          ),
        ),
        body: _errorMessage != null
            ? Center(child: Text(_errorMessage!))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildSensorTab(),
                  _buildGrowthTab(),
                  _tieuChuan == null
                      ? const Center(
                          child: Text(
                            'Không thể tải dữ liệu điều khiển. Vui lòng thử lại.',
                          ),
                        )
                      : HardwareControlPage(
                          key: ValueKey('hardware-control-${_isManualMode}'),
                          ngayTuoi: _ngayTuoi,
                          luaGa: widget.luaGa,
                          tieuchuanphattrien: _tieuChuan!,
                          isManualMode: _isManualMode,
                          onManualChanged: (bool val) {
                            setState(() {
                              _isManualMode = val;
                            });
                          },
                        ),
                  VaccineManagementTab(idLuaGa: widget.luaGa.id!),
                  LivestockCostPage(luaGa: widget.luaGa, ngayTuoi: _ngayTuoi,),
                ],
              ),
      ),
    );
  }

  // --- TAB 1: BIỂU ĐỒ CẢM BIẾN ---
  Widget _buildSensorTab() {
    final double minChartWidth = MediaQuery.of(context).size.width - 32;
    final double calculatedWidth = _rawSensorData.isEmpty
        ? minChartWidth
        : _rawSensorData.length * 50.0;
    final double dynamicChartWidth = calculatedWidth < minChartWidth
        ? minChartWidth
        : calculatedWidth;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title1: "Nhiệt độ tiêu chuẩn",
            title2: "Độ ẩm tiêu chuẩn",
            value1:
                "${_tieuChuan?.nhiet_do_toi_thieu ?? 0}°C - ${_tieuChuan?.nhiet_do_toi_da ?? 0}°C",
            color1: Colors.orange,
            icon1: Icons.thermostat,
            value2: "${_tieuChuan?.do_am_tc ?? 0}%",
            color2: Colors.lightBlue,
            icon2: Icons.water_drop_outlined,
          ),
          const SizedBox(height: 16),
          _buildChartSection(
            title: "Biến động Nhiệt độ & Độ ẩm hôm nay",
            chartController: _tempChartController,
            chartWidth: dynamicChartWidth,
            chart: _buildLineChart(
              [
                _createLineData(_tempSpots, Colors.orange),
                _createLineData(_humiSpots, Colors.blue),
              ],
              maxY: 100,
              isHistory: false,
            ),
          ),
          const SizedBox(height: 16),
          _buildChartSection(
            title: "Chất lượng nguồn nước uống TDS (ppm)",
            chartController: _tdsChartController,
            chartWidth: dynamicChartWidth,
            chart: _buildLineChart(
              [_createLineData(_tdsSpots, Colors.teal, isFilled: true)],
              maxY: 700,
              isHistory: false,
            ),
          ),
          const SizedBox(height: 16),
          _buildChartSection(
            title: "Chất lượng không khí (ppm)",
            chartController: _gasChartController,
            chartWidth: dynamicChartWidth,
            chart: _buildLineChart(
              [_createLineData(_gasSpots, Colors.brown, isFilled: true)],
              maxY: 4500,
              isHistory: false,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Nhật ký dữ liệu chi tiết trong ngày",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          _buildSensorLogsList(),
        ],
      ),
    );
  }

  // --- TAB 2: BIỂU ĐỒ TĂNG TRƯỞNG ---
  Widget _buildGrowthTab() {
    final double minChartWidth = MediaQuery.of(context).size.width - 32;
    final double calculatedWidth = _rawLichSuPhatTrien.isEmpty
        ? minChartWidth
        : _rawLichSuPhatTrien.length * 60.0;
    final double dynamicChartWidth = calculatedWidth < minChartWidth
        ? minChartWidth
        : calculatedWidth;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title1: "Cân nặng tiêu chuẩn",
            value1: "${_tieuChuan?.trong_luong_tc ?? 0} gam",
            color1: Colors.green,
            icon1: Icons.scale,
            title2: "Thức ăn tiêu chuẩn",
            value2: "${_tieuChuan?.luong_thuc_an_tc ?? 0} gam",
            color2: Colors.deepOrange,
            icon2: Icons.food_bank_sharp,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 153, 161, 225),
                  const Color.fromARGB(255, 41, 51, 237),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GrowthEvaluationPage(
                        luaGa: widget.luaGa,
                        ngayTuoi: _ngayTuoi,
                        tieuchuanphattrien: _tieuChuan!,
                        history: _rawLichSuPhatTrien,
                      ),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Icon(
                          Icons.analytics_outlined,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Đánh giá tăng trưởng đàn gà",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Cập nhật số gà hao hụt, lấy mẫu cân nặng & tính toán FCR",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildChartSection(
            title: "Biểu đồ phát triển cân nặng (gam)",
            chartController: _trongLuongChartController,
            chartWidth: dynamicChartWidth,
            chart: _buildLineChart(
              [_createLineData(_trongLuongSpots, Colors.green)],
              maxY: 3000,
              isHistory: true,
            ),
          ),
          const SizedBox(height: 16),
          _buildChartSection(
            title: "Biến động Nhiệt độ & Độ ẩm trung bình cả chu trình",
            chartController: _tempLSChartController,
            chartWidth: dynamicChartWidth,
            chart: _buildLineChart(
              [
                _createLineData(_tempLSSpots, Colors.orange),
                _createLineData(_humiLSSpots, Colors.blue),
              ],
              maxY: 100,
              isHistory: true,
            ),
          ),
          const SizedBox(height: 16),
          _buildChartSection(
            title: "Chất lượng nước uống TDS trung bình cả chu trình (ppm)",
            chartController: _tdsLSChartController,
            chartWidth: dynamicChartWidth,
            chart: _buildLineChart(
              [_createLineData(_tdsLSSpots, Colors.teal, isFilled: true)],
              maxY: 700,
              isHistory: true,
            ),
          ),
          const SizedBox(height: 16),
          _buildChartSection(
            title: "Chất lượng không khí trung bình cả chu trình",
            chartController: _gasLSChartController,
            chartWidth: dynamicChartWidth,
            chart: _buildLineChart(
              [_createLineData(_gasLSSpots, Colors.brown, isFilled: true)],
              maxY: 5500,
              isHistory: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(
    List<LineChartBarData> lines, {
    required double maxY,
    required bool isHistory,
  }) {
    final double safeMaxY = maxY * 1.2;
    final double yInterval = maxY / 4;

    final int dataLength = isHistory
        ? _rawLichSuPhatTrien.length
        : _rawSensorData.length;
    final int xLabelStep = dataLength <= 5 ? 1 : (dataLength / 5).ceil();
    double calculatedMaxX = (dataLength - 1).toDouble();
    if (isHistory) {
      if (calculatedMaxX < 5) calculatedMaxX = 5;
    } else {
      if (calculatedMaxX < 6) calculatedMaxX = 6;
    }

    List<ShowingTooltipIndicators> showingTooltips = [];
    if (lines.isNotEmpty) {
      for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
        final currentLine = lines[lineIndex];

        for (final spot in currentLine.spots) {
          showingTooltips.add(
            ShowingTooltipIndicators([
              LineBarSpot(currentLine, lineIndex, spot),
            ]),
          );
        }
      }
    }

    return LineChart(
      LineChartData(
        clipData: const FlClipData.none(),
        minX: 0,
        maxX: calculatedMaxX,
        minY: 0,
        maxY: safeMaxY,

        showingTooltipIndicators: showingTooltips,

        lineTouchData: LineTouchData(
          enabled: false,
          handleBuiltInTouches: false,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.transparent,
            tooltipPadding: EdgeInsets.zero,
            tooltipMargin: 6,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                return LineTooltipItem(
                  touchedSpot.y.toStringAsFixed(1),
                  const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                );
              }).toList();
            },
          ),
        ),

        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: yInterval,
          verticalInterval: 1,
          getDrawingVerticalLine: (value) {
            return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
          },
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade200),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: yInterval,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value > safeMaxY) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: xLabelStep.toDouble(),
              reservedSize: 32,
              getTitlesWidget: (val, meta) {
                final int index = val.toInt();
                if (index < 0 || index >= dataLength)
                  return const SizedBox.shrink();
                if (isHistory && index % xLabelStep != 0)
                  return const SizedBox.shrink();

                String titleText = "";
                if (isHistory) {
                  final DateTime date = _rawLichSuPhatTrien[index].ngay;
                  titleText =
                      "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}";
                } else {
                  final DateTime time = _rawSensorData[index].logged_at;
                  titleText =
                      "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
                }

                return SideTitleWidget(
                  meta: meta,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      titleText,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: lines,
      ),
    );
  }

  Widget _buildChartSection({
    required String title,
    required Widget chart,
    required double chartWidth,
    ScrollController? chartController,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 238,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SingleChildScrollView(
                controller: chartController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(width: chartWidth, child: chart),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorLogsList() {
    if (_rawSensorData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text("Hôm nay chưa có dữ liệu đẩy lên!")),
        ),
      );
    }

    final displayList = _rawSensorData.reversed.toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = displayList[index];
        final timeStr =
            "${item.logged_at.hour.toString().padLeft(2, '0')}:${item.logged_at.minute.toString().padLeft(2, '0')}";

        return Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            title: Text(
              "Nhiệt độ: ${item.nhiet_do}°C | Độ ẩm: ${item.do_am}%",
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              "TDS: ${item.tds} ppm | Chất lượng khí: ${item.gas} ppm",
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey,
            ),
            onTap: () => _showDetailDialog(item),
          ),
        );
      },
    );
  }

  void _showDetailDialog(Cambienhomnay item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Chi tiết mốc ${item.logged_at.hour}:${item.logged_at.minute.toString().padLeft(2, '0')}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              _buildDetailRow(
                "Nhiệt độ môi trường:",
                "${item.nhiet_do} °C",
                Colors.orange,
              ),
              _buildDetailRow(
                "Độ ẩm không khí:",
                "${item.do_am} %",
                Colors.blue,
              ),
              _buildDetailRow(
                "Chỉ số nước TDS:",
                "${item.tds} ppm",
                Colors.teal,
              ),
              _buildDetailRow(
                "Chỉ số khí ga trong không khí:",
                "${item.gas} ppm",
                Colors.brown,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _createLineData(
    List<FlSpot> spots,
    Color color, {
    bool isFilled = false,
    bool isDash = false,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2.5,
      dotData: const FlDotData(show: true),
      dashArray: isDash ? [5, 5] : null,
      belowBarData: BarAreaData(show: isFilled, color: color.withOpacity(0.08)),
    );
  }

  Widget _buildInfoCard({
    required String title1,
    required String title2,
    required String value1,
    required Color color1,
    required IconData icon1,
    required String value2,
    required Color color2,
    required IconData icon2,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color1.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color1.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon1, color: color1),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title1,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  value1,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon2, color: color2),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title2,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  value2,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
