import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'qr_scanner_screen.dart';

/// Màn hình chính cho Chủ Vựa (Role C) — giống POS thu ngân.
/// Tính năng: Hiển thị trạng thái Mở/Đóng cửa, nút Quét QR Khách to ở giữa,
/// thống kê nhanh trong ngày.
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

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      body: _selectedTab == 0 ? _buildHomeTab() : _buildStatsTab(),
      bottomNavigationBar: _buildBottomNav(),
    );
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
            const SizedBox(height: 24),
            _buildQuickStats(),
            const SizedBox(height: 32),
            _buildScanButton(),
            const SizedBox(height: 20),
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
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFF2E7D32)),
              SizedBox(width: 4),
              Text(
                'Chủ Vựa',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
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
            onChanged: (val) => setState(() => _isOpen = val),
            activeColor: Colors.white,
            activeTrackColor: Colors.white30,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.white24,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Lượt khách', '12', Icons.people_outline_rounded, const Color(0xFF1565C0))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Kg thu hôm nay', '87.5', Icons.scale_outlined, const Color(0xFF558B2F))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Doanh thu', '1.2M', Icons.payments_outlined, const Color(0xFFD4770A))),
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

  Widget _buildScanButton() {
    return Column(
      children: [
        const Text(
          'Quét mã khách hàng',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2E22),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Nhấn nút bên dưới để quét QR và nhập số liệu',
          style: TextStyle(fontSize: 13, color: Color(0xFF7A8B80)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ScaleTransition(
          scale: _pulseAnim,
          child: GestureDetector(
            onTap: _isOpen
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
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _isOpen
                      ? [const Color(0xFF1B8E5A), const Color(0xFF43A047)]
                      : [const Color(0xFF78909C), const Color(0xFF546E7A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isOpen
                            ? const Color(0xFF1B8E5A)
                            : const Color(0xFF546E7A))
                        .withOpacity(0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner_rounded, size: 52, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    'QUÉT QR\nKHÁCH',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    final activities = [
      ('Khách #1042', '15 kg Giấy', '30.000 GP', '09:45'),
      ('Khách #1041', '3 Rác điện tử', '15.000 GP', '08:30'),
      ('Khách #1040', '8 kg Nhựa', '24.000 GP', 'Hôm qua'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hoạt động gần đây',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2E22),
          ),
        ),
        const SizedBox(height: 12),
        ...activities.map((a) => _buildActivityItem(a.$1, a.$2, a.$3, a.$4)),
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

  // ─────────────────────────────────────────────────────────────────────────────
  // STATS TAB
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildStatsTab() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1B8E5A).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bar_chart_rounded, size: 48, color: Color(0xFF1B8E5A)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Thống kê Doanh thu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2E22)),
            ),
            const SizedBox(height: 8),
            const Text('Tính năng đang được phát triển', style: TextStyle(color: Color(0xFF7A8B80))),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      (Icons.home_rounded, 'Trang chủ'),
      (Icons.bar_chart_rounded, 'Thống kê'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = _selectedTab == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedTab = i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF1B8E5A).withOpacity(0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[i].$1, size: 24, color: selected ? const Color(0xFF1B8E5A) : const Color(0xFFB0BEC5)),
                      const SizedBox(height: 3),
                      Text(
                        items[i].$2,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? const Color(0xFF1B8E5A) : const Color(0xFFB0BEC5),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
