import 'package:flutter/material.dart';
import '../../data/repositories/yard_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../features/seller/presentation/screens/order_detail_screen.dart';

class YardPickupOrdersScreen extends StatefulWidget {
  final String token;

  const YardPickupOrdersScreen({super.key, required this.token});

  @override
  State<YardPickupOrdersScreen> createState() => _YardPickupOrdersScreenState();
}

class _YardPickupOrdersScreenState extends State<YardPickupOrdersScreen> {
  final YardRepository _yardRepo = YardRepository();
  bool _isLoading = true;
  List<dynamic> _orders = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _yardRepo.getPendingPickupOrders(token: widget.token);
      if (mounted) {
        setState(() {
          _orders = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _assignOrder(int orderId, double? lat, double? lng) async {
    try {
      await _yardRepo.assignPickupOrder(token: widget.token, orderId: orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã nhận đơn thu gom thành công!'),
            backgroundColor: Color(0xFF1B8E5A),
          ),
        );
        _fetchOrders(); // Tải lại danh sách
        
        // Mở bản đồ chỉ đường ngay
        if (lat != null && lng != null) {
          final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        }
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
    }
  }

  String _formatNumber(num value) {
    return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A2E22)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đơn chờ đi lấy',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2E22)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1A2E22)),
            onPressed: _fetchOrders,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1B8E5A)));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchOrders,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B8E5A)),
              child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Không có đơn Pick-up nào\nđang chờ lấy quanh đây.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF7A8B80), fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['orderId'] ?? 0;
    final totalAmount = order['totalEstimatedAmount'] ?? 0;
    final itemsCount = order['itemsCount'] ?? 0;
    final sellerName = order['sellerName'] ?? 'Khách hàng';
    final address = order['pickupAddress'] ?? 'Đang cập nhật địa chỉ...';
    final distanceKm = (order['distanceKm'] as num?)?.toDouble();
    final lat = (order['latitude'] as num?)?.toDouble();
    final lng = (order['longitude'] as num?)?.toDouble();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(
              orderId: orderId,
              token: widget.token,
            ),
          ),
        ).then((_) => _fetchOrders());
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B8E5A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#$orderId',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B8E5A)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$itemsCount loại rác',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF7A8B80)),
                  ),
                ],
              ),
              Text(
                '${_formatNumber(totalAmount)} đ',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFE59835)),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF3F7F4)),
          
          // Khách hàng & Địa chỉ
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF7A8B80)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sellerName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A2E22)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF7A8B80)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF7A8B80), height: 1.4),
                    ),
                    if (distanceKm != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Cách bạn: ${distanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE59835),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          // Nút Nhận Đơn
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B8E5A),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _assignOrder(orderId, lat, lng),
              icon: const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 20),
              label: const Text(
                'NHẬN ĐI LẤY NGAY',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    ));
  }
}
