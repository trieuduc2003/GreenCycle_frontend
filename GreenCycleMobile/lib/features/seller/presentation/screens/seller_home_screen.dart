import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../data/models/wallet_dto.dart';
import 'create_order_screen.dart';
import 'order_history_screen.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../transaction/data/models/transaction_dto.dart';
import '../../../transaction/data/repositories/transaction_repository.dart';
import '../../../yard/presentation/screens/nearby_yards_screen.dart';
import '../../../yard/data/services/yard_api_service.dart';
import '../../../yard/data/models/scrap_yard_model.dart';
import 'reward_store_screen.dart';
import 'user_profile_screen.dart';
import 'saved_addresses_screen.dart';
import '../../../notification/presentation/screens/notifications_screen.dart';
import '../../../settings/presentation/screens/app_settings_screen.dart';
import '../../../support/presentation/screens/support_screen.dart';
import '../../../policy/presentation/screens/policy_screen.dart';


/// Màn hình Home của Người bán (Seller) — A05 trong UI spec.
/// Hiển thị: số dư GreenPoints, 3 lối tắt (Bán rác / Đổi quà / Vựa gần),
/// gần nhất vựa và thanh nav phía dưới.
class SellerHomeScreen extends StatefulWidget {
  final String token;
  final String fullName;

  const SellerHomeScreen({
    super.key,
    required this.token,
    required this.fullName,
  });

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  int _selectedTab = 0;
  bool _isLoadingWallet = true;
  bool _isBalanceHidden = false;
  bool _isLoggingOut = false;
  WalletBalanceDto? _wallet;
  String? _walletError;

  // Nearby yards state
  List<ScrapYardModel> _nearbyYards = [];
  bool _isLoadingYards = false;

  late final AnimationController _cardController;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  final _walletRepo = WalletRepository();
  final _yardApiService = YardApiService();
  HubConnection? _hubConnection;

  @override
  void initState() {
    super.initState();
    _initSignalR();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _cardFade = CurvedAnimation(parent: _cardController, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic));

    _fetchWallet();
    _fetchNearbyYards();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _hubConnection?.stop();
    super.dispose();
  }

  // ── SignalR ────────────────────────────────────────────────────────────────
  Future<void> _initSignalR() async {
    _hubConnection = HubConnectionBuilder()
        .withUrl(
          ApiEndpoints.transactionHub,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => widget.token,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _hubConnection?.on('ReceiveDoubleConfirmation', _handleDoubleConfirmation);

    try {
      await _hubConnection?.start();
      print('SignalR Connected');
    } catch (e) {
      print('SignalR Connect Error: $e');
    }
  }

  void _handleDoubleConfirmation(List<Object?>? args) {
    if (args != null && args.isNotEmpty) {
      final payloadMap = args.first as Map<String, dynamic>;
      final payload = DoubleConfirmationPayload.fromJson(payloadMap);
      _showDoubleConfirmationDialog(payload);
    }
  }

  void _showDoubleConfirmationDialog(DoubleConfirmationPayload payload) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DoubleConfirmationDialog(
        payload: payload,
        token: widget.token,
        onConfirmed: () {
          _fetchWallet(); // Reload wallet balance after success
        },
      ),
    );
  }

  // ── Data fetching ──────────────────────────────────────────────────────────
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
        _cardController.forward(from: 0);
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

  /// Lấy vựa gần nhất từ GPS để hiển thị trong Home Tab (không block UI).
  Future<void> _fetchNearbyYards() async {
    setState(() => _isLoadingYards = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isLoadingYards = false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isLoadingYards = false);
        return;
      }

      // Dùng vị trí cũ trước cho nhanh, sau đó nếu có GPS mới thì update
      Position? position = await Geolocator.getLastKnownPosition();
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 8),
          ),
        ).timeout(const Duration(seconds: 10));
      } catch (_) {}

      if (position == null) {
        if (mounted) setState(() => _isLoadingYards = false);
        return;
      }

      final yards = await _yardApiService.getNearbyYards(
        token: widget.token,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (mounted) {
        setState(() {
          _nearbyYards = yards.take(3).toList();
          _isLoadingYards = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingYards = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    switch (_selectedTab) {
      case 0:
        return _buildHomeTab();
      case 1:
        return OrderHistoryScreen(
          token: widget.token,
          onBackToHome: () => setState(() => _selectedTab = 0),
        );
      case 2:
        return RewardStoreScreen(
          token: widget.token,
          onWalletChanged: _fetchWallet,
          onBackToHome: () => setState(() => _selectedTab = 0),
        );
      case 3:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primaryGreen,
        onRefresh: _fetchWallet,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildWalletCard()),
            SliverToBoxAdapter(child: _buildShortcutGrid()),
            SliverToBoxAdapter(child: _buildNearbySection()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderTab(String title, IconData icon) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.primaryGreen),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2E22),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tính năng đang được phát triển',
              style: TextStyle(color: Color(0xFF7A8B80), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper format tên người dùng ───────────────────────────────────────────
  String _getCleanFullName(String name) {
    final clean = name.replaceAll(RegExp(r'\s*[\(\[][^()\[\]]*[\)\]]\s*'), '').trim();
    return clean.isNotEmpty ? clean : name;
  }

  String _getGreetingName(String name) {
    final clean = _getCleanFullName(name);
    final parts = clean.split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.last : clean;
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final firstName = _getGreetingName(widget.fullName);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Xin chào,',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7A8B80),
                  fontWeight: FontWeight.w500,
                ),
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
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('👋', style: TextStyle(fontSize: 20)),
                ],
              ),
            ],
          ),
          const Spacer(),
          _buildNotifBell(),
        ],
      ),
    );
  }

  Widget _buildNotifBell() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NotificationsScreen(token: widget.token),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF2A5C3F),
              size: 22,
            ),
          ),
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFFF5252),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Wallet Card ────────────────────────────────────────────────────────────
  Widget _buildWalletCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: SlideTransition(
        position: _cardSlide,
        child: FadeTransition(
          opacity: _cardFade,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B8E5A), Color(0xFF0D6B41)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B8E5A).withOpacity(0.38),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Card header ──
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Ví Điểm (GreenPoints)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _isBalanceHidden = !_isBalanceHidden),
                      child: Icon(
                        _isBalanceHidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white54,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // ── Balance ──
                _buildBalanceDisplay(),
                const SizedBox(height: 10),
                // ── VND equivalent ──
                _buildVndEquivalent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceDisplay() {
    if (_isLoadingWallet) {
      return const SizedBox(
        height: 44,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: Colors.white60,
              strokeWidth: 2.5,
            ),
          ),
        ),
      );
    }

    if (_walletError != null) {
      return Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _walletError!,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      );
    }

    final gpText = _isBalanceHidden
        ? '••••• GP'
        : '${_formatNumber(_wallet?.balance ?? 0)} GP';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          gpText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildVndEquivalent() {
    if (_isLoadingWallet || _walletError != null) return const SizedBox.shrink();

    final vnd = _wallet?.balanceInVnd ?? 0;
    final vndText = _isBalanceHidden
        ? '≈ ••••• đ giá trị quà'
        : '≈ ${_formatNumber(vnd)}đ giá trị quà';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        vndText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ── Shortcut Grid ──────────────────────────────────────────────────────────
  Widget _buildShortcutGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildShortcut(
            icon: Icons.add_circle_outline_rounded,
            label: 'Bán rác',
            color: const Color(0xFF1B8E5A),
            bgColor: const Color(0xFFE0F4EB),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateOrderScreen(
                    token: widget.token,
                    fullName: widget.fullName,
                  ),
                ),
              );
            },
          ),
          _buildShortcut(
            icon: Icons.card_giftcard_rounded,
            label: 'Đổi quà',
            color: const Color(0xFFD4770A),
            bgColor: const Color(0xFFFFF3E0),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RewardStoreScreen(
                    token: widget.token,
                    onWalletChanged: _fetchWallet,
                  ),
                ),
              ).then((_) => _fetchWallet());
            },
          ),
          _buildShortcut(
            icon: Icons.storefront_outlined,
            label: 'Vựa gần',
            color: const Color(0xFF1565C0),
            bgColor: const Color(0xFFE3F2FD),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NearbyYardsScreen(token: widget.token),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShortcut({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2A3E30),
            ),
          ),
        ],
      ),
    );
  }

  // ── Nearby Section ─────────────────────────────────────────────────────────
  Widget _buildNearbySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Vựa gần tôi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E22)),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NearbyYardsScreen(token: widget.token)),
                ),
                child: const Text('Xem tất cả', style: TextStyle(color: AppColors.primaryGreen, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Content
          if (_isLoadingYards)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(color: AppColors.primaryGreen, strokeWidth: 2.5),
              ),
            )
          else if (_nearbyYards.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: const Color(0xFFF0F4F1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.search_off_rounded, color: Color(0xFF7A8B80), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Chưa tìm thấy vựa nào', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A2E22))),
                        SizedBox(height: 4),
                        Text('Hãy mở GPS và thử xem tất cả vựa.', style: TextStyle(fontSize: 12.5, color: Color(0xFF7A8B80))),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            ..._nearbyYards.map((yard) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildNearbyCard(yard: yard),
            )),
        ],
      ),
    );
  }

  Widget _buildNearbyCard({required ScrapYardModel yard}) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NearbyYardsScreen(token: widget.token)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F4EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: Color(0xFF1B8E5A),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    yard.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2E22),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          yard.address,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7A8B80),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: Color(0xFFB0BEC5),
            ),
          ],
        ),
      ),
    );
  }


  // ── Bottom Nav ─────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    const items = [
      _NavItem(icon: Icons.home_rounded, label: 'Trang chủ'),
      _NavItem(icon: Icons.receipt_long_outlined, label: 'Đơn hàng'),
      _NavItem(icon: Icons.card_giftcard_outlined, label: 'Đổi quà'),
      _NavItem(icon: Icons.person_outline_rounded, label: 'Tôi'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryGreen.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[i].icon,
                        size: 24,
                        color: selected
                            ? AppColors.primaryGreen
                            : const Color(0xFFB0BEC5),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i].label,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? AppColors.primaryGreen
                              : const Color(0xFFB0BEC5),
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

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _formatNumber(double number) {
    final n = number.toInt();
    if (n >= 1000) {
      final formatted = n.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
      return formatted;
    }
    return n.toString();
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — Sắp ra mắt! 🚀'),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  // ── Profile Tab & Logout ───────────────────────────────────────────────────
  Widget _buildProfileTab() {
    final cleanName = _getCleanFullName(widget.fullName);
    final initials = cleanName.isNotEmpty
        ? cleanName.trim().split(RegExp(r'\s+')).map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'GC';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Title
            const Text(
              'Tài khoản của tôi',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2E22),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 16),

            // Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primaryGreen,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cleanName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A2E22),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '🌱 Người bán (Seller)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Stats / Balance Widget
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B8E5A), Color(0xFF0D6B41)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.eco, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'GreenPoints khả dụng',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Text(
                    '${_wallet != null ? _formatNumber(_wallet!.balance) : '0'} GP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Menu Section: Cá nhân
            const Text(
              'Cá nhân',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF7A8B80)),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  _buildProfileMenuItem(
                    icon: Icons.person_outline_rounded,
                    title: 'Thông tin cá nhân',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfileScreen(
                          token: widget.token,
                          fullName: widget.fullName,
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFEFF2F0)),
                  _buildProfileMenuItem(
                    icon: Icons.recycling_rounded,
                    title: 'Lịch sử thu gom rác',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderHistoryScreen(
                          token: widget.token,
                          onBackToHome: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFEFF2F0)),
                  _buildProfileMenuItem(
                    icon: Icons.location_on_outlined,
                    title: 'Địa chỉ đã lưu',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SavedAddressesScreen(token: widget.token),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Menu Section: Cài đặt & Khác
            const Text(
              'Cài đặt & Hỗ trợ',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF7A8B80)),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  _buildProfileMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Cài đặt ứng dụng',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
                    ),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFEFF2F0)),
                  _buildProfileMenuItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Trung tâm hỗ trợ',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SupportScreen()),
                    ),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFEFF2F0)),
                  _buildProfileMenuItem(
                    icon: Icons.shield_outlined,
                    title: 'Điều khoản & Chính sách',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PolicyScreen()),
                    ),
                  ),
                ],
              ),
            ),


            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoggingOut ? null : _showLogoutConfirmationDialog,
                icon: _isLoggingOut
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                      )
                    : const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                label: Text(
                  _isLoggingOut ? 'Đang đăng xuất...' : 'Đăng xuất',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFEBEE),
                  foregroundColor: Colors.redAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFFFCDD2), width: 1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F7F4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF2A5C3F), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A2E22),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0BEC5), size: 22),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  Future<void> _showLogoutConfirmationDialog() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent, size: 26),
              SizedBox(width: 10),
              Text(
                'Xác nhận đăng xuất',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2E22),
                ),
              ),
            ],
          ),
          content: const Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản GreenCycle?',
            style: TextStyle(fontSize: 14, color: Color(0xFF4A5D50), height: 1.4),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Hủy',
                style: TextStyle(color: Color(0xFF7A8B80), fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Đăng xuất',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      await _handleLogout();
    }
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);

    try {
      await AuthRepository().logout(widget.token);
    } catch (_) {}

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 10),
            Text('Đã đăng xuất thành công!'),
          ],
        ),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

// ── Helper data class ──────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _DoubleConfirmationDialog extends StatefulWidget {
  final DoubleConfirmationPayload payload;
  final String token;
  final VoidCallback onConfirmed;

  const _DoubleConfirmationDialog({
    super.key,
    required this.payload,
    required this.token,
    required this.onConfirmed,
  });

  @override
  State<_DoubleConfirmationDialog> createState() => _DoubleConfirmationDialogState();
}

class _DoubleConfirmationDialogState extends State<_DoubleConfirmationDialog> {
  bool _isConfirming = false;
  final _txRepo = TransactionRepository();

  Future<void> _confirm() async {
    setState(() => _isConfirming = true);
    try {
      await _txRepo.confirmTransaction(
        token: widget.token,
        orderId: widget.payload.orderId,
      );
      if (mounted) {
        Navigator.pop(context); // close dialog
        widget.onConfirmed();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thành công! Nhận ${widget.payload.netGreenPoints} GP'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPickup = widget.payload.isPickup;
    final partnerName = widget.payload.partnerDisplayName;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPickup ? Icons.local_shipping_rounded : Icons.verified_user_outlined,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Xác nhận giao dịch',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Chip loại giao dịch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isPickup
                  ? const Color(0xFFE3F2FD)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isPickup ? '🚚 Giao dịch Pick-up' : '🏪 Giao dịch Drop-off',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isPickup ? const Color(0xFF1565C0) : AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          // Tên đối tác
          Row(
            children: [
              Icon(
                isPickup ? Icons.person_rounded : Icons.storefront_rounded,
                size: 18,
                color: const Color(0xFF7A8B80),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isPickup ? 'Tài xế: $partnerName' : 'Vựa: $partnerName',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // SĐT tài xế (chỉ hiện cho Pick-up)
          if (isPickup && widget.payload.collectorPhone != null && widget.payload.collectorPhone!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF7A8B80)),
                const SizedBox(width: 6),
                Text(
                  widget.payload.collectorPhone!,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF4A5D50)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _buildRow('Tổng trị giá', '${widget.payload.totalActualAmount.toStringAsFixed(0)} GP'),
          if (widget.payload.platformFee > 0)
            _buildRow(
              isPickup ? 'Phí tiện lợi (20%)' : 'Phí dịch vụ (10%)',
              '- ${widget.payload.platformFee.toStringAsFixed(0)} GP',
              isMinus: true,
            ),
          const Divider(height: 24, thickness: 1),
          _buildRow('Thực nhận', '${widget.payload.netGreenPoints.toStringAsFixed(0)} GP', isTotal: true),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Bằng việc xác nhận, bạn đồng ý với số liệu khối lượng thực tế đã được nhập. Giao dịch sẽ không thể hoàn tác.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF795548)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isConfirming ? null : () => Navigator.pop(context),
          child: const Text('Hủy bỏ', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          onPressed: _isConfirming ? null : _confirm,
          child: _isConfirming
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Đồng ý', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value, {bool isMinus = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? AppColors.primaryGreen : (isMinus ? Colors.red : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
