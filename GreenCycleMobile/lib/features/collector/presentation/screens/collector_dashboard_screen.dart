import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'collector_home_screen.dart';
import 'collector_orders_screen.dart';
import 'collector_wallet_screen.dart';
import 'collector_profile_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../data/repositories/collector_repository.dart';

class CollectorDashboardScreen extends StatefulWidget {
  final String token;
  final String fullName;

  const CollectorDashboardScreen({
    super.key,
    required this.token,
    required this.fullName,
  });

  @override
  State<CollectorDashboardScreen> createState() => _CollectorDashboardScreenState();
}

class _CollectorDashboardScreenState extends State<CollectorDashboardScreen> {
  int _selectedTab = 0;
  late final List<Widget> _screens;
  
  StreamSubscription<Position>? _positionStreamSub;
  Timer? _pollingTimer;
  final _repo = CollectorRepository();
  int? _activeOrderId; // Order currently being tracked

  @override
  void initState() {
    super.initState();
    _screens = [
      CollectorHomeScreen(token: widget.token),
      CollectorOrdersScreen(token: widget.token),
      CollectorWalletScreen(token: widget.token),
      CollectorProfileScreen(token: widget.token, fullName: widget.fullName),
    ];
    _startTrackingLogic();
  }

  void _startTrackingLogic() {
    // 1. Poll to check if we have an active order
    _checkActiveOrder();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkActiveOrder());

    // 2. Start location stream
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStreamSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      if (_activeOrderId != null) {
        _repo.updateLiveLocation(
          token: widget.token,
          orderId: _activeOrderId!,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
    });
  }

  Future<void> _checkActiveOrder() async {
    try {
      final orders = await _repo.getMyOrders(token: widget.token);
      final activeOrders = orders.where((o) => 
        o.statusName.toLowerCase() == 'driverassigned' || 
        o.statusName.toLowerCase() == 'inprogress'
      ).toList();

      if (activeOrders.isNotEmpty) {
        _activeOrderId = activeOrders.first.orderId;
      } else {
        _activeOrderId = null;
      }
    } catch (e) {
      // Ignore error for polling
    }
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedTab,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            currentIndex: _selectedTab,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primaryGreen,
            unselectedItemColor: const Color(0xFF94A3B8),
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            items: const [
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.map_outlined)),
                activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.map)),
                label: 'Bản đồ',
              ),
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.list_alt)),
                activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.list_alt)),
                label: 'Đơn của tôi',
              ),
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.account_balance_wallet_outlined)),
                activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.account_balance_wallet)),
                label: 'Ví Ký Quỹ',
              ),
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_outline)),
                activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person)),
                label: 'Hồ sơ',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
