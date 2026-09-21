import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/order_dto.dart';
import '../../data/repositories/order_repository.dart';
import 'seller_qr_display_screen.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  final String token;

  final VoidCallback? onBackToHome;

  const OrderHistoryScreen({
    super.key,
    required this.token,
    this.onBackToHome,
  });

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final _orderRepo = OrderRepository();
  bool _isLoading = true;
  List<OrderHistoryDto> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    final orders = await _orderRepo.getOrderHistory(widget.token);
    if (mounted) {
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Lịch sử đơn hàng',
          style: TextStyle(
            color: Color(0xFF1A2E22),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: (Navigator.canPop(context) || widget.onBackToHome != null)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A2E22), size: 18),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else if (widget.onBackToHome != null) {
                    widget.onBackToHome!();
                  }
                },
              )
            : null,
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
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Icon(Icons.receipt_long_outlined, size: 80, color: Color(0xFFC2E0CE)),
        const SizedBox(height: 16),
        const Text(
          'Chưa có đơn hàng nào',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A5D50),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Bạn chưa thực hiện giao dịch bán rác nào.\nHãy tạo đơn ngay nhé!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF7A8B80)),
        ),
      ],
    );
  }

  Widget _buildOrderCard(OrderHistoryDto order) {
    final bool isCompleted = order.statusName.toLowerCase() == 'completed';
    final bool isPending = order.statusName.toLowerCase() == 'pending';

    Color statusColor = Colors.grey;
    if (isCompleted) statusColor = AppColors.primaryGreen;
    if (isPending) statusColor = Colors.orange;

    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt.toLocal());

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(
              orderId: order.orderId,
              token: widget.token,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đơn #${order.orderId}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1A2E22),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _translateStatus(order.statusName),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                order.methodName.contains('Drop') ? Icons.inventory_2_outlined : Icons.local_shipping_outlined,
                size: 18,
                color: const Color(0xFF7A8B80),
              ),
              const SizedBox(width: 8),
              Text(
                order.methodName.contains('Drop') ? 'Tự mang đi' : 'Gọi thu gom',
                style: const TextStyle(color: Color(0xFF4A5D50)),
              ),
              const Spacer(),
              Text(
                formattedDate,
                style: const TextStyle(color: Color(0xFF7A8B80), fontSize: 12),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFEAF4EE)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ước tính', style: TextStyle(color: Color(0xFF7A8B80), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    '${order.totalEstimatedAmount.toInt()} GP',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              if (isPending)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SellerQrDisplayScreen(
                          orderId: order.orderId,
                          orderInfo: '${order.itemsCount} loại rác • ${_translateMethod(order.methodName)}',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code, size: 16),
                  label: const Text('Mở QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEEF5F0),
                    foregroundColor: AppColors.primaryGreen,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ xử lý';
      case 'driverassigned':
        return 'Đã có tài xế';
      case 'inprogress':
        return 'Đang thực hiện';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  String _translateMethod(String method) {
    if (method.contains('Drop')) return 'Tự mang đi';
    return 'Gọi thu gom';
  }
}
