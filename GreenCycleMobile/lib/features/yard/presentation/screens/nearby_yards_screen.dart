import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/scrap_yard_model.dart';
import '../../data/services/yard_api_service.dart';
import '../../../seller/presentation/screens/seller_qr_display_screen.dart';

/// Màn hình A07: Tìm vựa rác gần đây.
///
/// Cấu trúc UI:
/// - Nền: Google Map toàn màn hình (hiển thị vị trí người dùng + markers vựa)
/// - Phía trên: AppBar mờ với nút quay lại
/// - Phía dưới: DraggableScrollableSheet — kéo lên/xuống để xem danh sách vựa
class NearbyYardsScreen extends StatefulWidget {
  /// JWT token — cần thiết để gọi API backend
  final String token;
  
  /// Nếu người dùng đã tạo đơn hàng trước đó, ta truyền orderId vào để có thể quét QR
  final int? orderId;

  const NearbyYardsScreen({super.key, required this.token, this.orderId});

  @override
  State<NearbyYardsScreen> createState() => _NearbyYardsScreenState();
}

class _NearbyYardsScreenState extends State<NearbyYardsScreen> {
  // ── State Variables ────────────────────────────────────────────────────────

  /// Controller để điều khiển bản đồ (camera, markers...)
  final MapController _mapController = MapController();

  /// Vị trí GPS hiện tại của người dùng
  Position? _currentPosition;

  /// Tập hợp các marker hiển thị trên bản đồ
  final List<Marker> _markers = [];

  /// Danh sách vựa rác trả về từ API
  List<ScrapYardModel> _yards = [];

  /// Trạng thái loading khi đang xử lý
  bool _isLoading = true;

  /// Thông báo lỗi nếu có
  String? _errorMessage;

  /// Service gọi API
  final _apiService = YardApiService();

  // ── Default location: TP.HCM (dùng khi chưa lấy được GPS) ─────────────────
  static const LatLng _defaultLocation = LatLng(10.7769, 106.7009);

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Khởi động quá trình: Lấy GPS → Gọi API → Hiển thị kết quả
    _initializeLocationAndYards();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // ── Core Logic ─────────────────────────────────────────────────────────────

  /// Bước 1: Xin quyền và lấy tọa độ GPS của người dùng.
  /// Bước 2: Dùng tọa độ đó gọi API backend lấy danh sách vựa gần đây.
  Future<void> _initializeLocationAndYards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ── BƯỚC 1: Xin quyền GPS ──────────────────────────────────────────────
      // Kiểm tra xem dịch vụ Location có bật không
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
          'Dịch vụ định vị đang tắt.\nVui lòng bật GPS trong Cài đặt.',
        );
      }

      // Kiểm tra và xin quyền truy cập vị trí
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Hiện hộp thoại xin quyền
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Quyền truy cập vị trí bị từ chối.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Người dùng từ chối vĩnh viễn → hướng đến Cài đặt hệ thống
        throw Exception(
          'Quyền vị trí bị chặn vĩnh viễn.\nVui lòng cấp quyền trong Cài đặt ứng dụng.',
        );
      }

      // Lấy tọa độ hiện tại với LocationSettings (API mới)
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        ).timeout(const Duration(seconds: 12));
      } catch (_) {
        // Fallback: Nếu không lấy được GPS tức thời (do ở trong nhà hoặc máy bị treo GPS), lấy vị trí cũ gần nhất
        position = await Geolocator.getLastKnownPosition();
        if (position == null) {
          throw Exception('Không thể xác định vị trí. Vui lòng bật định vị GPS và thử lại.');
        }
      }

      // ── BƯỚC 2: Gọi API Backend ────────────────────────────────────────────
      final yards = await _apiService.getNearbyYards(
        token: widget.token,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // ── BƯỚC 3: Cập nhật Markers trên bản đồ ──────────────────────────────
      final markers = <Marker>[];

      // Marker vị trí người dùng (màu xanh lam)
      markers.add(
        Marker(
          width: 48.0,
          height: 48.0,
          point: LatLng(position.latitude, position.longitude),
          child: const Icon(Icons.my_location, color: Colors.blue, size: 32.0),
        ),
      );

      // Marker cho từng vựa rác (màu xanh lá)
      for (final yard in yards) {
        markers.add(
          Marker(
            width: 40.0,
            height: 40.0,
            point: LatLng(yard.latitude, yard.longitude),
            child: Icon(
              Icons.location_on, 
              color: yard.isOpening ? AppColors.primaryGreen : Colors.red, 
              size: 36.0,
            ),
          ),
        );
      }

      // Cập nhật state
      setState(() {
        _currentPosition = position;
        _yards = yards;
        _markers.clear();
        _markers.addAll(markers);
        _isLoading = false;
      });

      // Di chuyển camera đến vị trí người dùng
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        14.0, // zoom level: 14 = nhìn được khu vực vài km
      );
    } catch (e) {
      // Hiển thị lỗi lên màn hình
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// Mở Google Maps chỉ đường đến vựa khi người dùng bấm "Bắt đầu đi".
  ///
  /// Sử dụng [url_launcher] để mở app Google Maps bên ngoài.
  /// URL format: https://www.google.com/maps/dir/?api=1&destination={lat},{lng}&travelmode=driving
  Future<void> _startNavigation(ScrapYardModel yard) async {
    // Nếu có orderId, lưu lại vựa người dùng đã chọn
    if (widget.orderId != null) {
      try {
        await _apiService.selectYardForOrder(
          token: widget.token,
          orderId: widget.orderId!,
          yardId: yard.yardId,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi lưu vựa: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        // Vẫn cho phép đi tiếp nếu lỗi (tuỳ policy, nhưng cứ cho mở Map)
      }
    }

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${yard.latitude},${yard.longitude}'
      '&travelmode=driving',
    );

    // Kiểm tra xem device có thể mở URL này không
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Fallback: Thông báo nếu không mở được
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể mở Google Maps. Vui lòng cài đặt ứng dụng.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // ── UI Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Không có AppBar cố định — dùng Stack để overlay bản đồ
      body: Stack(
        children: [
          // ── LAYER 1: OpenStreetMap (nền toàn màn hình) ────────────────────────
          _buildFlutterMap(),

          // ── LAYER 2: Nút quay lại (floating, không che bản đồ nhiều) ───────
          _buildBackButton(),

          // ── LAYER 3: Nút hiện QR nhanh (nếu có orderId) ────────────────────
          if (widget.orderId != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SellerQrDisplayScreen(
                        orderId: widget.orderId!,
                        orderInfo: 'Đơn hàng tự mang đi',
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
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 3)),
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
              ),
            ),

          // ── LAYER 4: Loading overlay ────────────────────────────────────────
          if (_isLoading) _buildLoadingOverlay(),

          // ── LAYER 5: Error overlay ──────────────────────────────────────────
          if (!_isLoading && _errorMessage != null) _buildErrorOverlay(),

          // ── LAYER 6: Draggable sheet danh sách vựa (kéo lên/xuống) ─────────
          if (!_isLoading && _errorMessage == null) _buildDraggableYardList(),
        ],
      ),
    );
  }

  /// Bản đồ OpenStreetMap chiếm toàn bộ màn hình
  Widget _buildFlutterMap() {
    final initialTarget = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : _defaultLocation;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialTarget,
        initialZoom: 14.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.greencycle.mobile',
        ),
        MarkerLayer(
          markers: _markers,
        ),
      ],
    );
  }

  /// Nút quay lại góc trên trái, dạng pill (viên thuốc) với nền mờ
  Widget _buildBackButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF1A2E22)),
              SizedBox(width: 6),
              Text(
                'Vựa gần tôi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1A2E22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Overlay loading khi đang lấy GPS và gọi API
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primaryGreen, strokeWidth: 3),
            SizedBox(height: 16),
            Text(
              'Đang tìm vựa gần bạn...',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  /// Overlay lỗi với nút thử lại
  Widget _buildErrorOverlay() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, -4)),
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

  /// DraggableScrollableSheet — sheet kéo lên xuống hiển thị danh sách vựa
  Widget _buildDraggableYardList() {
    return DraggableScrollableSheet(
      // Chiều cao khởi tạo: 35% màn hình
      initialChildSize: 0.38,
      // Chiều cao tối thiểu: 12% (vẫn thấy tab)
      minChildSize: 0.12,
      // Chiều cao tối đa: 85%
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
              // ── Drag handle ──────────────────────────────────────────────────
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE3E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // ── Header ───────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.12),
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
                              fontSize: 17,
                              color: Color(0xFF1A2E22),
                            ),
                          ),
                          Text(
                            _yards.isEmpty
                                ? 'Không tìm thấy vựa trong 5km'
                                : '${_yards.length} vựa trong bán kính 5km',
                            style: const TextStyle(color: Color(0xFF7A8B80), fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    // Nút làm mới
                    IconButton(
                      onPressed: _initializeLocationAndYards,
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryGreen),
                      tooltip: 'Tải lại',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Divider ──────────────────────────────────────────────────────
              const Divider(height: 1, color: Color(0xFFEAF4EE)),
              const SizedBox(height: 8),

              // ── Danh sách vựa ────────────────────────────────────────────────
              Expanded(
                child: _yards.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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

  /// Trạng thái rỗng khi không tìm thấy vựa
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.storefront_outlined, size: 64, color: Color(0xFFC2E0CE)),
          const SizedBox(height: 12),
          const Text(
            'Chưa có vựa nào gần bạn',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4A5D50)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Không tìm thấy vựa rác trong bán kính 5km',
            style: TextStyle(color: Color(0xFF7A8B80), fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// Card hiển thị thông tin một vựa rác.
  ///
  /// Thiết kế:
  /// - Bên trái: Icon vựa
  /// - Giữa: Tên, địa chỉ, trạng thái + khoảng cách
  /// - Bên phải: Nút "Bắt đầu đi" màu xanh
  Widget _buildYardCard(ScrapYardModel yard) {
    return GestureDetector(
      // Khi tap vào card → di chuyển camera bản đồ tới vựa đó
      onTap: () {
        _mapController.move(
          LatLng(yard.latitude, yard.longitude),
          15.0,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAF4EE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Icon vựa ─────────────────────────────────────────────────────
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: yard.isOpening
                    ? AppColors.primaryGreen.withOpacity(0.12)
                    : Colors.grey.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.storefront_rounded,
                color: yard.isOpening ? AppColors.primaryGreen : Colors.grey,
                size: 24,
              ),
            ),

            const SizedBox(width: 12),

            // ── Thông tin vựa ─────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên vựa
                  Text(
                    yard.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: Color(0xFF1A2E22),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),

                  // Địa chỉ
                  Text(
                    yard.address,
                    style: const TextStyle(color: Color(0xFF7A8B80), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Row: Badge trạng thái + khoảng cách
                  Row(
                    children: [
                      // Badge mở/đóng cửa
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: yard.isOpening
                              ? const Color(0xFFE0F4EB)
                              : const Color(0xFFFCE4E4),
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

                      // Khoảng cách
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

            // ── Nút Bắt đầu đi ────────────────────────────────────────────────
            // Sử dụng url_launcher để mở Google Maps bên ngoài
            GestureDetector(
              onTap: () => _startNavigation(yard),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B8E5A), Color(0xFF0D6B41)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
                    SizedBox(height: 4),
                    Text(
                      'Đi\nthôi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
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
