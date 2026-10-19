import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/location_helper.dart';
import '../../data/models/collector_order_dto.dart';
import '../../data/repositories/collector_repository.dart';
import '../../../seller/presentation/screens/create_order_screen.dart';

class CollectorHomeScreen extends StatefulWidget {
  final String token;
  const CollectorHomeScreen({super.key, required this.token});

  @override
  State<CollectorHomeScreen> createState() => _CollectorHomeScreenState();
}

class _CollectorHomeScreenState extends State<CollectorHomeScreen> {
  final MapController _mapController = MapController();
  final _repo = CollectorRepository();

  double _currentLat = 10.8231; // Mặc định TP.HCM
  double _currentLon = 106.6297;
  String _currentAddressDisplay = 'Vị trí hiện tại';
  bool _isUsingGps = false;

  final List<Marker> _markers = [];
  List<CollectorOrderDto> _orders = [];
  bool _isLoading = true;
  bool _isLocating = false;
  String? _warningMessage;

  double _selectedRadiusKm = 10.0;
  final List<double> _radiusOptions = [3.0, 5.0, 10.0, 20.0];

  void _onRadiusChanged(double radius) {
    if (_selectedRadiusKm == radius) return;
    setState(() {
      _selectedRadiusKm = radius;
      _isLoading = true;
    });
    _fetchOrdersAt(_currentLat, _currentLon);
  }

  @override
  void initState() {
    super.initState();
    _initCollectorLocation();
  }

  // ─── Khởi tạo vị trí khi mở màn hình ───────────────────────────────────
  Future<void> _initCollectorLocation() async {
    setState(() {
      _isLoading = true;
      _warningMessage = null;
    });

    try {
      final pos = await LocationHelper.getCurrentPosition();
      if (pos != null) {
        _currentLat = pos.latitude;
        _currentLon = pos.longitude;
        _isUsingGps = true;
        _currentAddressDisplay = 'Vị trí GPS của bạn';

        // Lấy tên địa chỉ ngầm (không bắt buộc)
        LocationHelper.getAddressFromCoordinates(pos.latitude, pos.longitude).then((name) {
          if (name != null && mounted) {
            setState(() => _currentAddressDisplay = name);
          }
        });
      }
    } catch (e) {
      _warningMessage = e.toString().replaceAll('Exception: ', '');
      _isUsingGps = false;
      _currentAddressDisplay = 'Khu vực TP. Hồ Chí Minh (ước tính)';
    }

    await _fetchOrdersAt(_currentLat, _currentLon);

    if (mounted) {
      setState(() => _isLoading = false);
      _mapController.move(LatLng(_currentLat, _currentLon), 14.0);
    }
  }

  // ─── Cập nhật lại GPS máy ──────────────────────────────────────────────
  Future<void> _refreshGpsLocation() async {
    setState(() => _isLocating = true);
    try {
      final pos = await LocationHelper.getCurrentPosition();
      if (pos == null) {
        throw Exception('Không nhận được tín hiệu GPS.');
      }

      _currentLat = pos.latitude;
      _currentLon = pos.longitude;
      _isUsingGps = true;
      _warningMessage = null;
      _currentAddressDisplay = 'Vị trí GPS của bạn';

      LocationHelper.getAddressFromCoordinates(pos.latitude, pos.longitude).then((name) {
        if (name != null && mounted) {
          setState(() => _currentAddressDisplay = name);
        }
      });

      await _fetchOrdersAt(_currentLat, _currentLon);

      if (mounted) {
        setState(() => _isLocating = false);
        _mapController.move(LatLng(_currentLat, _currentLon), 14.5);
        _showSnack('Đã cập nhật vị trí GPS và tải các cuốc xe gần bạn!', isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLocating = false);
        final msg = e.toString().replaceAll('Exception: ', '');
        _showLocationError(msg);
      }
    }
  }

  // ─── Tìm đơn theo địa chỉ nhập tay ────────────────────────────────────
  Future<void> _showCustomAddressDialog() async {
    final controller = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        bool searching = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Đổi địa chỉ tìm kiếm',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2E22)),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nhập địa chỉ hoặc khu vực bạn muốn tìm kiếm cuốc xe thu gom:',
                    style: TextStyle(fontSize: 13.5, color: Color(0xFF7A8B80)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'VD: Quận Bình Thạnh, TP.HCM hoặc tên đường...',
                      prefixIcon: const Icon(Icons.location_searching_rounded, color: AppColors.primaryGreen),
                      filled: true,
                      fillColor: const Color(0xFFF3F7F4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: searching
                          ? null
                          : () async {
                              final text = controller.text.trim();
                              if (text.isEmpty) return;

                              setModalState(() => searching = true);
                              final res = await LocationHelper.getCoordinatesFromAddress(text);
                              setModalState(() => searching = false);

                              if (res != null) {
                                if (context.mounted) Navigator.pop(context);
                                setState(() {
                                  _currentLat = res.latitude;
                                  _currentLon = res.longitude;
                                  _isUsingGps = false;
                                  _currentAddressDisplay = res.address ?? text;
                                  _warningMessage = null;
                                  _isLoading = true;
                                });
                                await _fetchOrdersAt(_currentLat, _currentLon);
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                  _mapController.move(LatLng(_currentLat, _currentLon), 14.0);
                                  _showSnack('Đã chuyển sang khu vực: $text', isError: false);
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Không tìm thấy địa chỉ này. Hãy nhập chi tiết hơn (VD: kèm Quận/Huyện, Tỉnh/TP)'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: searching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Tìm cuốc xe tại đây',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Tải danh sách đơn hàng quanh tọa độ ──────────────────────────────
  Future<void> _fetchOrdersAt(double lat, double lon) async {
    try {
      final rawOrders = await _repo.getPendingPickupOrders(
        token: widget.token,
        latitude: lat,
        longitude: lon,
        radiusKm: _selectedRadiusKm,
      );

      final distanceCalc = const Distance();
      final List<CollectorOrderDto> orders = [];

      for (final o in rawOrders) {
        double? dist = o.distance;
        if (dist == null && o.latitude != 0 && o.longitude != 0) {
          final m = distanceCalc.as(LengthUnit.Meter, LatLng(lat, lon), LatLng(o.latitude, o.longitude));
          dist = double.parse((m / 1000.0).toStringAsFixed(2));
        }

        // Đảm bảo không lọt đơn vượt quá bán kính đã chọn
        if (dist != null && dist > _selectedRadiusKm) {
          continue;
        }

        orders.add(CollectorOrderDto(
          orderId: o.orderId,
          sellerName: o.sellerName,
          sellerPhone: o.sellerPhone,
          address: o.address,
          latitude: o.latitude,
          longitude: o.longitude,
          totalEstimatedWeight: o.totalEstimatedWeight,
          status: o.status,
          createdAt: o.createdAt,
          distance: dist,
        ));
      }

      // Sắp xếp đơn gần nhất lên đầu
      orders.sort((a, b) => (a.distance ?? 9999).compareTo(b.distance ?? 9999));

      final markers = <Marker>[
        Marker(
          width: 50.0,
          height: 50.0,
          point: LatLng(lat, lon),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.my_location, color: Colors.blueAccent, size: 30.0),
            ),
          ),
        ),
      ];

      for (final order in orders) {
        markers.add(
          Marker(
            width: 44.0,
            height: 44.0,
            point: LatLng(order.latitude, order.longitude),
            child: GestureDetector(
              onTap: () {
                _mapController.move(LatLng(order.latitude, order.longitude), 16.0);
              },
              child: const Icon(Icons.location_on, color: AppColors.primaryGreen, size: 38.0),
            ),
          ),
        );
      }

      if (mounted) {
        setState(() {
          _orders = orders;
          _markers.clear();
          _markers.addAll(markers);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ─── Điều hướng & Nhận đơn ───────────────────────────────────────────
  Future<void> _startNavigation(CollectorOrderDto order) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${order.latitude},${order.longitude}'
      '&travelmode=driving',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('Không thể mở ứng dụng chỉ đường');
    }
  }

  Future<void> _acceptOrder(CollectorOrderDto order) async {
    try {
      await _repo.assignCollector(token: widget.token, orderId: order.orderId);
      _showSnack('Đã nhận đơn thành công! Hãy xem trong mục "Đơn của tôi".', isError: false);
      _fetchOrdersAt(_currentLat, _currentLon);
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _callCustomer(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showSnack('Không thể gọi đến số: $cleanPhone');
    }
  }

  void _showSnack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : AppColors.primaryGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showLocationError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      action: SnackBarAction(
        label: 'Cài đặt',
        textColor: Colors.white,
        onPressed: () {
          if (msg.contains('Cài đặt')) {
            LocationHelper.openAppSettings();
          } else {
            LocationHelper.openLocationSettings();
          }
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildFlutterMap(),
          _buildTopHeader(),
          _buildDraggableOrderList(),
          _buildGpsFab(),
        ],
      ),
    );
  }

  Widget _buildFlutterMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(_currentLat, _currentLon),
        initialZoom: 14.0,
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

  // ─── Header: Địa chỉ + Đổi địa chỉ + Bán cho Vựa + Lọc bán kính ─────
  Widget _buildTopHeader() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Thanh địa chỉ có thể bấm để đổi
              Expanded(
                child: GestureDetector(
                  onTap: _showCustomAddressDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isUsingGps ? Icons.my_location : Icons.location_on,
                          color: _isUsingGps ? Colors.blueAccent : AppColors.primaryGreen,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentAddressDisplay,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1A2E22)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Nút Bán cho Vựa
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateOrderScreen(
                        token: widget.token,
                        fullName: 'Người thu gom',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.storefront_outlined, size: 16),
                label: const Text('Bán cho Vựa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 3,
                ),
              ),
            ],
          ),
          if (_warningMessage != null) ...[
            const SizedBox(height: 8),
            _buildWarningBanner(),
          ],
          const SizedBox(height: 8),
          _buildRadiusFilterBar(),
        ],
      ),
    );
  }

  // ─── Warning Banner khi GPS chưa bật ──────────────────────────────────
  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _warningMessage ?? 'Đang hiển thị vị trí ước tính.',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: _refreshGpsLocation,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(40, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Bật GPS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  // ─── Thanh lọc bán kính (3km, 5km, 10km, 20km) ────────────────────────
  Widget _buildRadiusFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _radiusOptions.map((r) {
          final isSelected = _selectedRadiusKm == r;
          final km = r.toInt();
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

  // ─── Nút Floating Cập nhật GPS nhanh ──────────────────────────────────
  Widget _buildGpsFab() {
    return Positioned(
      bottom: 290,
      right: 16,
      child: Material(
        elevation: 4,
        shape: const CircleBorder(),
        color: Colors.white,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _isLocating ? null : _refreshGpsLocation,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _isLocating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primaryGreen),
                  )
                : const Icon(Icons.gps_fixed_rounded, color: AppColors.primaryGreen, size: 24),
          ),
        ),
      ),
    );
  }

  // ─── Danh sách đơn hàng bên dưới ──────────────────────────────────────
  Widget _buildDraggableOrderList() {
    return DraggableScrollableSheet(
      initialChildSize: 0.36,
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFDDE3E0), borderRadius: BorderRadius.circular(2)),
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
                      child: const Icon(Icons.local_shipping, color: AppColors.primaryGreen, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Đơn thu gom gần bạn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1A2E22))),
                          Text(
                            _orders.isEmpty
                                ? 'Không có đơn nào trong bán kính ${_selectedRadiusKm.toInt()} km'
                                : '${_orders.length} đơn trong bán kính ${_selectedRadiusKm.toInt()} km',
                            style: const TextStyle(color: Color(0xFF7A8B80), fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _fetchOrdersAt(_currentLat, _currentLon),
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryGreen),
                      tooltip: 'Tải lại danh sách đơn',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFEAF4EE)),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                    : _orders.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_off_outlined, size: 48, color: Colors.grey),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Không có cuốc thu gom nào quanh khu vực này',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Color(0xFF7A8B80), fontSize: 14),
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed: _showCustomAddressDialog,
                                    icon: const Icon(Icons.search, size: 18),
                                    label: const Text('Tìm cuốc tại khu vực khác'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primaryGreen,
                                      side: const BorderSide(color: AppColors.primaryGreen),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
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
        _mapController.move(LatLng(order.latitude, order.longitude), 15.5);
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
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: AppColors.primaryGreen, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              order.sellerName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A2E22)),
                            ),
                          ),
                          if (order.sellerPhone != null && order.sellerPhone!.isNotEmpty)
                            InkWell(
                              onTap: () => _callCustomer(order.sellerPhone!),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFA5D6A7)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.phone, size: 13, color: AppColors.primaryGreen),
                                    const SizedBox(width: 4),
                                    Text(
                                      order.sellerPhone!,
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF7A8B80)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              order.address,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF7A8B80)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.scale_outlined, size: 14, color: Color(0xFF7A8B80)),
                          const SizedBox(width: 4),
                          Text(
                            '~${order.totalEstimatedWeight} kg',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF7A8B80), fontWeight: FontWeight.w600),
                          ),
                          if (order.distance != null) ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.directions_car_outlined, size: 14, color: Color(0xFF7A8B80)),
                            const SizedBox(width: 4),
                            Text(
                              '${order.distance!.toStringAsFixed(1)} km',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF7A8B80), fontWeight: FontWeight.w600),
                            ),
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
