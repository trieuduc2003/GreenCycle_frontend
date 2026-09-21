import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'qr_scanner_screen.dart';
import '../../data/repositories/yard_repository.dart';
import '../../data/models/yard_stats_model.dart';
import '../../data/models/yard_activity_model.dart';
import '../../data/models/yard_chart_data_model.dart';
import 'yard_profile_screen.dart';
import 'yard_price_list_screen.dart';
import 'yard_pickup_orders_screen.dart';
import 'yard_edit_profile_screen.dart';
import 'package:green_cycle_mobile/features/seller/data/repositories/wallet_repository.dart';
import 'package:green_cycle_mobile/features/seller/data/models/wallet_dto.dart';

class YardDashboardScreen extends StatefulWidget {
  final String token;
  final String fullName;

  const YardDashboardScreen({
    super.key,
    required this.token,
    required this.fullName,
  });

  @override
  State<YardDashboardScreen> createState() => _YardDashboardScreenState();
}

class _YardDashboardScreenState extends State<YardDashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isOpen = true;
  int _selectedTab = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  final _yardRepo = YardRepository();
  bool _isLoadingStats = true;
  bool _isLoadingActivities = true;
  YardStatsModel? _stats;
  List<YardActivityModel> _activities = [];
  bool _isLoadingChart = true;
  List<YardChartDataModel> _chartData = [];
  DateTime _statsMonth = DateTime.now();
  bool _isCheckingProfile = true;

  final _walletRepo = WalletRepository();
  bool _isLoadingWallet = true;
  WalletBalanceDto? _wallet;
  String? _walletError;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fetchData();
  }

  Future<void> _fetchData() async {
    await _checkProfile();
    if (mounted && !_isCheckingProfile) {
      _fetchStats();
      _fetchActivities();
      _fetchChart();
      _fetchWallet();
    }
  }

  Future<void> _checkProfile() async {
    try {
      final profile = await _yardRepo.getProfile(token: widget.token);
      final address = profile['address'] as String?;
      final lat = profile['latitude'];
      final lng = profile['longitude'];
      
      if (address == null || address.trim().isEmpty || address == 'Chưa cập nhật' || lat == null || lng == null) {
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => YardEditProfileScreen(
                token: widget.token,
                isInitialSetup: true,
              ),
            ),
          );
        }
      } else {
        setState(() {
          _isOpen = profile['isOpening'] ?? true;
        });
      }
    } catch (e) {
      // Ignore if failed to load
    } finally {
      if (mounted) {
        setState(() => _isCheckingProfile = false);
      }
    }
  }

  Future<void> _fetchWallet() async {
    setState(() {
      _isLoadingWallet = true;
      _walletError = null;
    });
    try {
      final wallet = await _walletRepo.getBalance(widget.token);
      if (mounted) {
        setState(() {
          _wallet = wallet;
          _isLoadingWallet = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _walletError = e.toString().replaceAll('Exception: ', '');
          _isLoadingWallet = false;
        });
      }
    }
  }

  Future<void> _fetchChart() async {
    setState(() => _isLoadingChart = true);
    try {
      final data = await _yardRepo.getChartStats(
        token: widget.token, 
        month: _statsMonth.month, 
        year: _statsMonth.year
      );
      if (mounted) {
        setState(() {
          _chartData = data;
          _isLoadingChart = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingChart = false);
    }
  }

  void _changeStatsMonth(int offsetMonths) {
    setState(() {
      _statsMonth = DateTime(_statsMonth.year, _statsMonth.month + offsetMonths, 1);
    });
    _fetchChart();
  }

  Future<void> _fetchStats() async {
    try {
      final stats = await _yardRepo.getStats(token: widget.token);
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _fetchActivities() async {
    try {
      final activities = await _yardRepo.getRecentActivities(token: widget.token);
      if (mounted) {
        setState(() {
          _activities = activities;
          _isLoadingActivities = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingActivities = false);
    }
  }

  Future<void> _toggleStatus(bool val) async {
    final oldState = _isOpen;
    setState(() => _isOpen = val);
    try {
      await _yardRepo.updateStatus(token: widget.token, isOpening: val);
    } catch (e) {
      if (mounted) {
        setState(() => _isOpen = oldState);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    if (_isCheckingProfile) {
      return Scaffold(
        backgroundColor: const Color(0xFFF3F7F4),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(color: Color(0xFF1B8E5A)),
              SizedBox(height: 16),
              Text('Đang kiểm tra hồ sơ...', style: TextStyle(color: Color(0xFF7A8B80))),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    switch (_selectedTab) {
      case 0: return _buildHomeTab();
      case 1: return YardPriceListScreen(token: widget.token);
      case 2: return _buildStatsTab();
      case 3: return YardProfileScreen(token: widget.token, fullName: widget.fullName);
      default: return _buildHomeTab();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // HOME TAB
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildHomeTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildStatusCard(),
            const SizedBox(height: 20),
            _buildWalletCard(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildScanButton()),
                const SizedBox(width: 12),
                Expanded(child: _buildPickUpButton()),
              ],
            ),
            const SizedBox(height: 24),
            _buildQuickStats(),
            const SizedBox(height: 10),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final firstName = widget.fullName.split(' ').last;
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Xin chào,',
              style: TextStyle(fontSize: 13, color: Color(0xFF7A8B80)),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  firstName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2E22),
                  ),
                ),
                const SizedBox(width: 6),
                const Text('🏭', style: TextStyle(fontSize: 20)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isOpen
              ? [const Color(0xFF1B8E5A), const Color(0xFF0D6B41)]
              : [const Color(0xFF546E7A), const Color(0xFF37474F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (_isOpen ? const Color(0xFF1B8E5A) : const Color(0xFF546E7A))
                .withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trạng thái vựa',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                _isOpen ? '🟢 Đang mở cửa' : '🔴 Đã đóng cửa',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isOpen
                    ? 'Khách hàng có thể tìm thấy bạn'
                    : 'Vựa đang ẩn khỏi bản đồ',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          Switch.adaptive(
            value: _isOpen,
            onChanged: _toggleStatus,
            activeColor: Colors.white,
            activeTrackColor: Colors.white30,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.white24,
          ),
        ],
      ),
    );
  }

  String _formatNumber(num value) {
    return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  Widget _buildWalletCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFC78330), // Orange-ish matching the UI
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC78330).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ví Trả Trước',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingWallet)
            const CircularProgressIndicator(color: Colors.white)
          else if (_walletError != null)
            Text('Lỗi: $_walletError', style: const TextStyle(color: Colors.white))
          else
            Text(
              '${_formatNumber(_wallet?.balanceInVnd ?? 0)}đ',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Trên mức tối thiểu 50k',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QrScannerScreen(token: widget.token),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFE59835),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE59835).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
            SizedBox(height: 8),
            Text(
              'Quét nhận hàng',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickUpButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => YardPickupOrdersScreen(token: widget.token),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF1B8E5A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B8E5A).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.local_shipping_outlined, color: Colors.white, size: 28),
            SizedBox(height: 8),
            Text(
              'Đơn chờ đi lấy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    if (_isLoadingStats) {
      return const Center(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: CircularProgressIndicator(color: Color(0xFF1B8E5A)),
      ));
    }
    
    final customers = _stats?.totalCustomers.toString() ?? '0';
    final kg = _stats?.totalKgCollected.toStringAsFixed(1) ?? '0';
    
    // Format revenue (e.g. 1,200,000 -> 1.2M)
    String revenueStr = '0';
    final revenue = _stats?.totalRevenue ?? 0;
    if (revenue >= 1000000) {
      revenueStr = '${(revenue / 1000000).toStringAsFixed(1)}M';
    } else if (revenue >= 1000) {
      revenueStr = '${(revenue / 1000).toStringAsFixed(1)}k';
    } else {
      revenueStr = revenue.toStringAsFixed(0);
    }

    return Row(
      children: [
        Expanded(child: _buildStatCard('Lượt khách', customers, Icons.people_outline_rounded, const Color(0xFF1565C0))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Kg thu hôm nay', kg, Icons.scale_outlined, const Color(0xFF558B2F))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Doanh thu', revenueStr, Icons.payments_outlined, const Color(0xFFD4770A))),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2E22),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF7A8B80)),
          ),
        ],
      ),
    );
  }


  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Hoạt động gần đây',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2E22),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF7A8B80)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                setState(() => _isLoadingActivities = true);
                _fetchActivities();
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingActivities)
          const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(color: Color(0xFF1B8E5A)),
          ))
        else if (_activities.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('Chưa có giao dịch nào hôm nay', style: TextStyle(color: Color(0xFF7A8B80))),
          ))
        else
          ..._activities.map((a) => _buildActivityItem(a.customerName, a.wasteDescription, a.pointsAwarded, a.timeAgo)),
      ],
    );
  }

  Widget _buildActivityItem(String customer, String waste, String points, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F4EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long_rounded, size: 20, color: Color(0xFF1B8E5A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1A2E22))),
                Text(waste, style: const TextStyle(fontSize: 12, color: Color(0xFF7A8B80))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(points, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B8E5A))),
              Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFFB0BEC5))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingScanButton() {
    return ScaleTransition(
      scale: _pulseAnim,
      child: FloatingActionButton(
        onPressed: _isOpen
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QrScannerScreen(token: widget.token),
                  ),
                );
              }
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hãy mở cửa vựa trước khi quét QR!'),
                    backgroundColor: Color(0xFF546E7A),
                  ),
                );
              },
        backgroundColor: _isOpen ? const Color(0xFF1B8E5A) : const Color(0xFF78909C),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: const Icon(Icons.qr_code_scanner_rounded, size: 28, color: Colors.white),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STATS TAB
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildStatsTab() {
    if (_isLoadingChart) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
    }

    if (_chartData.isEmpty) {
      return const Center(child: Text('Chưa có dữ liệu thống kê'));
    }

    // Đảo ngược list để hiển thị từ cũ nhất -> mới nhất từ trái sang phải
    final dataReversed = _chartData.reversed.toList();
    final maxRev = dataReversed.fold<double>(0, (prev, element) => element.totalRevenue > prev ? element.totalRevenue : prev);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thống kê Doanh thu',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A2E22)),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 20),
                        onPressed: () => _changeStatsMonth(-1),
                      ),
                      Text('T${_statsMonth.month}/${_statsMonth.year}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 20),
                        onPressed: () => _changeStatsMonth(1),
                      ),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),
            Container(
              height: 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: dataReversed.map((d) {
                    final double heightRatio = maxRev > 0 ? (d.totalRevenue / maxRev) : 0;
                    final double barHeight = heightRatio * 160;

                    return Container(
                      width: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            d.totalRevenue >= 1000 ? '${(d.totalRevenue / 1000).toStringAsFixed(0)}k' : d.totalRevenue.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 10, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            width: 24,
                            height: barHeight == 0 ? 4 : barHeight,
                            decoration: BoxDecoration(
                              color: barHeight == 0 ? Colors.grey.shade300 : const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(d.date, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Khối lượng Thu gom',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A2E22)),
            ),
            const SizedBox(height: 16),
            ...dataReversed.map((d) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ngày ${d.date}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2E22))),
                  Text('${d.totalKg.toStringAsFixed(1)} kg', style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // BOTTOM NAV
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedTab,
      onTap: (index) => setState(() => _selectedTab = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF1B8E5A),
      unselectedItemColor: const Color(0xFF9E9E9E),
      showUnselectedLabels: true,
      elevation: 20,
      backgroundColor: Colors.white,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Trang chủ',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.sell_outlined),
          activeIcon: Icon(Icons.sell_rounded),
          label: 'Bảng giá',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          activeIcon: Icon(Icons.bar_chart_rounded),
          label: 'Doanh thu',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Tôi',
        ),
      ],
    );
  }
}
