import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../seller/data/models/order_history_dto.dart';
import '../../data/repositories/collector_repository.dart';
import '../../../yard/presentation/screens/qr_scanner_screen.dart';

class CollectorOrdersScreen extends StatefulWidget {
  final String token;
  const CollectorOrdersScreen({super.key, required this.token});

  @override
  State<CollectorOrdersScreen> createState() => _CollectorOrdersScreenState();
}

class _CollectorOrdersScreenState extends State<CollectorOrdersScreen> {
  final _repo = CollectorRepository();
  bool _isLoading = true;
  List<OrderHistoryDto> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _repo.getMyOrders(token: widget.token);
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  void _openQrScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(token: widget.token, isCollector: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Đơn của tôi', style: TextStyle(color: Color(0xFF1A2E22), fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : RefreshIndicator(
              color: AppColors.primaryGreen,
              onRefresh: _fetchOrders,
              child: _orders.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildOrderCard(_orders[index]);
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openQrScanner,
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        label: const Text('Quét QR Giao dịch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Icon(Icons.assignment_outlined, size: 80, color: Color(0xFFC2E0CE)),
        const SizedBox(height: 16),
        const Text('Chưa có đơn hàng nào', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A5D50))),
        const SizedBox(height: 8),
        const Text('Bạn chưa nhận cuốc xe nào.\nHãy chuyển sang màn hình Bản đồ để nhận đơn mới!', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF7A8B80))),
      ],
    );
  }

  Widget _buildOrderCard(OrderHistoryDto order) {
    final bool isCompleted = order.statusName.toLowerCase() == 'completed';
    final bool isAssigned = order.statusName.toLowerCase() == 'assigned';
    
    Color statusColor = Colors.grey;
    if (isCompleted) statusColor = AppColors.primaryGreen;
    if (isAssigned) statusColor = Colors.blue;

    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt.toLocal());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Đơn #${order.orderId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A2E22))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  order.statusName,
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEAF4EE)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF7A8B80)),
              const SizedBox(width: 8),
              Text('${order.itemsCount} loại rác', style: const TextStyle(fontSize: 13, color: Color(0xFF4A5D50))),
              const Spacer(),
              const Icon(Icons.monetization_on_outlined, size: 16, color: AppColors.primaryGreen),
              const SizedBox(width: 4),
              Text(
                '${NumberFormat.currency(locale: 'vi', symbol: 'đ').format(order.totalEstimatedAmount)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Color(0xFF7A8B80)),
              const SizedBox(width: 8),
              Text(formattedDate, style: const TextStyle(fontSize: 13, color: Color(0xFF7A8B80))),
            ],
          ),
        ],
      ),
    );
  }
}
