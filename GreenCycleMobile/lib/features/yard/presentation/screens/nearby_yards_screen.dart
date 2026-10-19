import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/location_helper.dart';
import '../../data/models/scrap_yard_model.dart';
import '../../data/services/yard_api_service.dart';
import '../../../seller/presentation/screens/seller_qr_display_screen.dart';
import '../../../seller/presentation/screens/create_order_screen.dart';

/// Màn hình Bản đồ & Danh sách các Vựa rác gần người dùng nhất.
class NearbyYardsScreen extends StatefulWidget {
  final String token;
  final int? orderId;

  const NearbyYardsScreen({
    super.key,
    required this.token,
    this.orderId,
  });

  @override
  State<NearbyYardsScreen> createState() => _NearbyYardsScreenState();
}

class _NearbyYardsScreenState extends State<NearbyYardsScreen> {
  final MapController _mapController = MapController();
  final YardApiService _apiService = YardApiService();

  static const LatLng _defaultLocation = LatLng(10.7769, 106.7009); // Bưu điện Trung tâm Sài Gòn

  Position? _currentPosition;
  List<ScrapYardModel> _yards = [];
  final List<Marker> _markers = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Bán kính tìm kiếm (mặc định 10km)
  double _radiusMeters = 10000;
  final List<double> _radiusOptions = [3000, 5000, 10000, 20000];

  @override
  void initState() {
    super.initState();
    _initializeLocationAndYards();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocationAndYards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final position = await LocationHelper.getCurrentPosition();
      if (position == null) {
        throw Exception('Không thể xác định vị trí. Vui lòng bật định vị GPS và cấp quyền cho GreenCycle.');
      }

      await _fetchYardsForPosition(position, _radiusMeters);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchYardsForPosition(Position position, double radius) async {
    final yards = await _apiService.getNearbyYards(
      token: widget.token,
      latitude: position.latitude,
      longitude: position.longitude,
      radiusMeters: radius,
    );

    final markers = <Marker>[];

    // Marker vị trí người dùng
    markers.add(
      Marker(
        width: 48.0,
        height: 48.0,
        point: LatLng(position.latitude, position.longitude),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.my_location_rounded, color: Colors.blue, size: 28.0),
          ),
        ),
      ),
    );

    // Marker cho từng vựa rác
    for (final yard in yards) {
      markers.add(
        Marker(
          width: 44.0,
          height: 44.0,
          point: LatLng(yard.latitude, yard.longitude),
          child: GestureDetector(
            onTap: () => _selectYardAction(yard),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.storefront_rounded,
                  color: yard.isOpening ? AppColors.primaryGreen : Colors.redAccent,
                  size: 26.0,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _currentPosition = position;
        _yards = yards;
        _markers.clear();
        _markers.addAll(markers);
        _isLoading = false;
      });

      _mapController.move(
        LatLng(position.latitude, position.longitude),
        13.5,
      );
    }
  }

  void _onRadiusChanged(double newRadius) {
    if (_radiusMeters == newRadius || _currentPosition == null) return;
    setState(() {
      _radiusMeters = newRadius;
      _isLoading = true;
    });
    _fetchYardsForPosition(_currentPosition!, newRadius);
  }

  Future<void> _startNavigation(ScrapYardModel yard) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${yard.latitude},${yard.longitude}'
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

  Future<void> _selectYardAction(ScrapYardModel yard) async {
    _mapController.move(LatLng(yard.latitude, yard.longitude), 15.0);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: AppColors.primaryGreen, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        yard.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1A2E22)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: yard.isOpening ? const Color(0xFFE0F4EB) : const Color(0xFFFCE4E4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              yard.isOpening ? 'Mở cửa' : 'Đóng cửa',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: yard.isOpening ? AppColors.primaryGreen : Colors.redAccent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•  Cách bạn: ${yard.distanceFormatted}',
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7D72), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF7A8B80)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    yard.address,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF4A5D50)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _startNavigation(yard);
                    },
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: const Text('Chỉ đường'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      side: const BorderSide(color: AppColors.primaryGreen),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      if (widget.orderId != null) {
                        try {
                          await _apiService.selectYardForOrder(
                            token: widget.token,
                            orderId: widget.orderId!,
                            yardId: yard.yardId,
                          );
                        } catch (_) {}

                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SellerQrDisplayScreen(
                                orderId: widget.orderId!,
                                orderInfo: 'Đơn mang đến: ${yard.name}',
                                token: widget.token,
                              ),
                            ),
                          );
                        }
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateOrderScreen(token: widget.token),
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      widget.orderId != null ? Icons.qr_code_rounded : Icons.add_circle_outline_rounded,
                      size: 18,
                    ),
                    label: Text(
                      widget.orderId != null ? 'Chọn & Mở mã QR' : 'Tạo đơn mang đến đây',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── LAYER 1: Bản đồ CartoDB Voyager Retina (Load cực nhanh, không trắng màn hình)
          _buildFlutterMap(),

          // ── LAYER 2: Nút quay lại & Nút Mở QR
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBackButton(),
                if (widget.orderId != null) _buildQrButton(),
              ],
            ),
          ),

          // ── LAYER 3: Thanh chọn bán kính (Radius Filter)
          Positioned(
            top: MediaQuery.of(context).padding.top + 65,
            left: 16,
            right: 16,
            child: _buildRadiusFilterBar(),
          ),

          // ── LAYER 4: Loading overlay
          if (_isLoading) _buildLoadingOverlay(),

          // ── LAYER 5: Error overlay
          if (!_isLoading && _errorMessage != null) _buildErrorOverlay(),

          // ── LAYER 6: Draggable sheet danh sách vựa
          if (!_isLoading && _errorMessage == null) _buildDraggableYardList(),
        ],
      ),
    );
  }

  Widget _buildFlutterMap() {
    final initialTarget = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : _defaultLocation;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialTarget,
        initialZoom: 13.5,
      ),
      children: [
        // OpenStreetMap tiêu chuẩn, miễn phí và không yêu cầu API key
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.greencycle.app',
          maxZoom: 19,
        ),
        MarkerLayer(
          markers: _markers,
        ),
      ],
    );
  }

  Widget _buildRadiusFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _radiusOptions.map((r) {
          final isSelected = _radiusMeters == r;
          final km = (r / 1000).toInt();
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                'Bán kính $km km',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF1A2E22),
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primaryGreen,
              backgroundColor: Colors.white,
              elevation: 3,
              pressElevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.15),
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onSelected: (_) => _onRadiusChanged(r),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF1A2E22)),
            SizedBox(width: 6),
            Text(
              'Vựa gần tôi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A2E22)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SellerQrDisplayScreen(
              orderId: widget.orderId!,
              orderInfo: 'Đơn hàng tự mang đi',
              token: widget.token,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner_rounded, size: 16, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'Mã QR',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.25),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primaryGreen, strokeWidth: 3),
            SizedBox(height: 16),
            Text(
              'Đang tìm vựa rác quanh bạn...',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, -4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Đã xảy ra lỗi',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF4A5D50), fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _initializeLocationAndYards,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableYardList() {
    return DraggableScrollableSheet(
      initialChildSize: 0.36,
      minChildSize: 0.12,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4)),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE3E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: AppColors.primaryGreen, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vựa rác gần bạn',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.5,
                              color: Color(0xFF1A2E22),
                            ),
                          ),
                          Text(
                            _yards.isEmpty
                                ? 'Không có vựa trong bán kính ${(_radiusMeters / 1000).toInt()}km'
                                : '${_yards.length} vựa trong bán kính ${(_radiusMeters / 1000).toInt()}km',
                            style: const TextStyle(color: Color(0xFF7A8B80), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _initializeLocationAndYards,
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryGreen),
                      tooltip: 'Tải lại',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFEAF4EE)),
              Expanded(
                child: _yards.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _yards.length,
                        itemBuilder: (context, index) => _buildYardCard(_yards[index]),
                      ),
              ),
            ],
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
          const Icon(Icons.storefront_outlined, size: 56, color: Color(0xFFC2E0CE)),
          const SizedBox(height: 10),
          Text(
            'Không tìm thấy vựa trong ${(_radiusMeters / 1000).toInt()}km',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF4A5D50)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Hãy chọn bán kính rộng hơn ở thanh trên để tìm thêm vựa',
            style: TextStyle(color: Color(0xFF7A8B80), fontSize: 12.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildYardCard(ScrapYardModel yard) {
    return GestureDetector(
      onTap: () => _selectYardAction(yard),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAF4EE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: yard.isOpening
                    ? AppColors.primaryGreen.withValues(alpha: 0.12)
                    : Colors.grey.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.storefront_rounded,
                color: yard.isOpening ? AppColors.primaryGreen : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    yard.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF1A2E22)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    yard.address,
                    style: const TextStyle(color: Color(0xFF7A8B80), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: yard.isOpening ? const Color(0xFFE0F4EB) : const Color(0xFFFCE4E4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          yard.isOpening ? 'Mở cửa' : 'Đóng cửa',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: yard.isOpening ? AppColors.primaryGreen : Colors.redAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Icon(Icons.near_me_rounded, size: 12, color: Color(0xFF7A8B80)),
                          const SizedBox(width: 3),
                          Text(
                            yard.distanceFormatted,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4A5D50),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Nút Thao tác
            GestureDetector(
              onTap: () => _selectYardAction(yard),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B8E5A), Color(0xFF0D6B41)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.orderId != null ? Icons.check_circle_outline : Icons.navigation_rounded, color: Colors.white, size: 18),
                    const SizedBox(height: 4),
                    Text(
                      widget.orderId != null ? 'Chọn\nvựa' : 'Đi\nthôi',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
