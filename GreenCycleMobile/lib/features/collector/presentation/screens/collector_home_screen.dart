import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/collector_order_dto.dart';
import '../../data/repositories/collector_repository.dart';

class CollectorHomeScreen extends StatefulWidget {
  final String token;
  const CollectorHomeScreen({super.key, required this.token});

  @override
  State<CollectorHomeScreen> createState() => _CollectorHomeScreenState();
}

class _CollectorHomeScreenState extends State<CollectorHomeScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  final List<Marker> _markers = [];
  List<CollectorOrderDto> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _repo = CollectorRepository();

  @override
  void initState() {
    super.initState();
    _initializeLocationAndOrders();
  }

  Future<void> _initializeLocationAndOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final hasService = await Geolocator.isLocationServiceEnabled();
      if (!hasService) throw Exception('Dịch vụ vị trí đang bị tắt.');

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Cần quyền vị trí để tìm đơn thu gom gần bạn.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Quyền vị trí bị chặn vĩnh viễn. Hãy cấp quyền trong Cài đặt.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      ).timeout(const Duration(seconds: 12), onTimeout: () async {
        return await Geolocator.getLastKnownPosition() ?? (throw Exception('Timeout'));
      });

      final orders = await _repo.getPendingPickupOrders(
        token: widget.token,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      final markers = <Marker>[
        Marker(
          width: 48.0, height: 48.0,
          point: LatLng(position.latitude, position.longitude),
          child: const Icon(Icons.my_location, color: Colors.blue, size: 32.0),
        ),
      ];

      for (final order in orders) {
        markers.add(
          Marker(
            width: 40.0, height: 40.0,
            point: LatLng(order.latitude, order.longitude),
            child: const Icon(Icons.location_on, color: AppColors.primaryGreen, size: 36.0),
          ),
        );
      }

      setState(() {
        _currentPosition = position;
        _orders = orders;
        _markers.clear();
        _markers.addAll(markers);
        _isLoading = false;
      });

      _mapController.move(LatLng(position.latitude, position.longitude), 14.0);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _startNavigation(CollectorOrderDto order) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${order.latitude},${order.longitude}'
      '&travelmode=driving',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở Google Maps.')),
        );
      }
    }
  }

  Future<void> _acceptOrder(CollectorOrderDto order) async {
    try {
      await _repo.assignCollector(token: widget.token, orderId: order.orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã nhận đơn thành công! Hãy xem trong mục "Đơn của tôi".'), backgroundColor: AppColors.primaryGreen),
        );
      }
      _initializeLocationAndOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildFlutterMap(),
          _buildTopBar(),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          else if (_errorMessage != null)
            _buildErrorOverlay()
          else
            _buildDraggableOrderList(),
        ],
      ),
    );
  }

  Widget _buildFlutterMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentPosition != null
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : const LatLng(10.8231, 106.6297), // HCMC default
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.greencycle.app',
        ),
        MarkerLayer(markers: _markers),
      ],
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: const Text('Bản đồ cuốc xe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.white.withOpacity(0.8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeLocationAndOrders,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
              child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableOrderList() {
    return DraggableScrollableSheet(
      initialChildSize: 0.38,
      minChildSize: 0.12,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFDDE3E0), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.local_shipping, color: AppColors.primaryGreen, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Đơn thu gom gần bạn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1A2E22))),
                          Text(
                            _orders.isEmpty ? 'Không có đơn nào' : '${_orders.length} đơn đang chờ',
                            style: const TextStyle(color: Color(0xFF7A8B80), fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _initializeLocationAndOrders,
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryGreen),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFEAF4EE)),
              Expanded(
                child: _orders.isEmpty
                    ? const Center(child: Text('Không tìm thấy cuốc xe nào quanh đây'))
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(CollectorOrderDto order) {
    return GestureDetector(
      onTap: () {
        _mapController.move(LatLng(order.latitude, order.longitude), 15.0);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAF4EE)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.inventory_2_outlined, color: AppColors.primaryGreen, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.sellerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A2E22))),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF7A8B80)),
                          const SizedBox(width: 4),
                          Expanded(child: Text(order.address, style: const TextStyle(fontSize: 12, color: Color(0xFF7A8B80)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.scale_outlined, size: 14, color: Color(0xFF7A8B80)),
                          const SizedBox(width: 4),
                          Text('~${order.totalEstimatedWeight} kg', style: const TextStyle(fontSize: 12, color: Color(0xFF7A8B80), fontWeight: FontWeight.w600)),
                          if (order.distance != null) ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.directions_car_outlined, size: 14, color: Color(0xFF7A8B80)),
                            const SizedBox(width: 4),
                            Text('${order.distance!.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 12, color: Color(0xFF7A8B80), fontWeight: FontWeight.w600)),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _startNavigation(order),
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text('Chỉ đường'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      side: const BorderSide(color: AppColors.primaryGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptOrder(order),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Nhận đơn'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
