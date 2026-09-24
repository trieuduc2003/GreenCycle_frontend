import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/order_detail_dto.dart';
import '../../data/repositories/order_repository.dart';
import 'live_tracking_screen.dart';
import 'seller_qr_display_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  final String token;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.token,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _orderRepo = OrderRepository();
  bool _isLoading = true;
  OrderDetailViewDto? _order;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    final detail = await _orderRepo.getOrderDetail(widget.token, widget.orderId);
    if (mounted) {
      setState(() {
        _order = detail;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A2E22), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Đơn hàng #${widget.orderId}',
          style: const TextStyle(
            color: Color(0xFF1A2E22),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : _order == null
              ? _buildNotFoundView()
              : RefreshIndicator(
                  color: AppColors.primaryGreen,
                  onRefresh: _fetchDetail,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusHeaderCard(),
                        const SizedBox(height: 14),
                        // Pick-up status stepper
                        if (_order!.methodId == 2) ...[
                          _buildPickupStatusStepper(),
                          const SizedBox(height: 14),
                        ],
                        _buildDestinationCard(),
                        const SizedBox(height: 14),
                        _buildItemsCard(),
                        const SizedBox(height: 14),
                        _buildLedgerSummaryCard(),
                        if (_order!.estimatedCo2ReducedKg > 0) ...[
                          const SizedBox(height: 14),
                          _buildEcoImpactCard(),
                        ],
                        const SizedBox(height: 24),
                        if (_order!.statusName.toLowerCase() == 'pending') ...[
                          _buildQrButton(),
                          const SizedBox(height: 16),
                        ],
                        if (_order!.methodId == 2 && 
                            (_order!.statusName.toLowerCase() == 'driverassigned' || 
                             _order!.statusName.toLowerCase() == 'inprogress')) ...[
                          _buildLiveTrackingButton(),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildNotFoundView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey),
          const SizedBox(height: 12),
          const Text(
            'Không tìm thấy thông tin đơn hàng này',
            style: TextStyle(color: Color(0xFF7A8B80), fontSize: 15),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchDetail,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 1. Thẻ Trạng thái & Mốc thời gian
  Widget _buildStatusHeaderCard() {
    final statusName = _order!.statusName.toLowerCase();
    final isCompleted = statusName == 'completed';
    final isPending = statusName == 'pending';
    final isDriverAssigned = statusName == 'driverassigned';
    final isInProgress = statusName == 'inprogress';

    Color color = Colors.grey;
    IconData icon = Icons.info_outline;
    if (isCompleted) {
      color = AppColors.primaryGreen;
      icon = Icons.check_circle_rounded;
    } else if (isPending) {
      color = Colors.orange;
      icon = Icons.access_time_rounded;
    } else if (isDriverAssigned) {
      color = Colors.blue;
      icon = Icons.directions_bike_rounded;
    } else if (isInProgress) {
      color = const Color(0xFF7B1FA2);
      icon = Icons.local_shipping_rounded;
    }

    final dateFmt = DateFormat('dd/MM/yyyy • HH:mm');

    return Container(
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _translateStatus(_order!.statusName),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateFmt.format(_order!.createdAt.toLocal()),
                  style: const TextStyle(color: Color(0xFF7A8B80), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8F4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFC8E6C9)),
            ),
            child: Text(
              _translateMethod(_order!.methodName),
              style: const TextStyle(
                color: Color(0xFF1B8E5A),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1b. Pick-up Status Stepper
  Widget _buildPickupStatusStepper() {
    final steps = [
      _PickupStep(id: 1, label: 'Chờ nhận', icon: Icons.hourglass_empty_rounded, statusKey: 'pending'),
      _PickupStep(id: 2, label: 'Tài xế nhận', icon: Icons.directions_bike_rounded, statusKey: 'driverassigned'),
      _PickupStep(id: 3, label: 'Đang lấy', icon: Icons.local_shipping_rounded, statusKey: 'inprogress'),
      _PickupStep(id: 4, label: 'Hoàn tất', icon: Icons.check_circle_rounded, statusKey: 'completed'),
    ];

    final currentStatusKey = _order!.statusName.toLowerCase();
    int currentStepIndex = steps.indexWhere((s) => s.statusKey == currentStatusKey);
    if (currentStepIndex < 0) currentStepIndex = 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline_rounded, size: 18, color: AppColors.primaryGreen),
              SizedBox(width: 6),
              Text(
                'Tiến trình thu gom',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A2E22)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                // Connector line
                final stepIndex = i ~/ 2;
                final isDone = stepIndex < currentStepIndex;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: isDone ? AppColors.primaryGreen : const Color(0xFFE0E0E0),
                  ),
                );
              }
              final stepIndex = i ~/ 2;
              final step = steps[stepIndex];
              final isDone = stepIndex < currentStepIndex;
              final isCurrent = stepIndex == currentStepIndex;
              final color = isDone || isCurrent ? AppColors.primaryGreen : const Color(0xFFBDBDBD);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.primaryGreen
                          : isCurrent
                              ? AppColors.primaryGreen.withOpacity(0.15)
                              : const Color(0xFFF5F5F5),
                      shape: BoxShape.circle,
                      border: isCurrent
                          ? Border.all(color: AppColors.primaryGreen, width: 2)
                          : null,
                    ),
                    child: Icon(
                      isDone ? Icons.check_rounded : step.icon,
                      size: 18,
                      color: isDone ? Colors.white : color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? AppColors.primaryGreen : const Color(0xFF7A8B80),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // 2. Thẻ Địa điểm / Vựa hoặc Tài xế
  Widget _buildDestinationCard() {
    final isDropOff = _order!.methodId == 1;

    return Container(
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
            children: [
              Icon(
                isDropOff ? Icons.storefront_rounded : Icons.local_shipping_rounded,
                size: 20,
                color: isDropOff ? AppColors.primaryGreen : const Color(0xFF1565C0),
              ),
              const SizedBox(width: 8),
              Text(
                isDropOff ? 'Điểm vựa tiếp nhận' : 'Thu gom tại nhà',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  color: Color(0xFF1A2E22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isDropOff) ...[
            Text(
              _order!.scrapYardName ?? 'Vựa thu mua GreenCycle',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              _order!.scrapYardAddress ?? 'Địa chỉ đang cập nhật',
              style: const TextStyle(color: Color(0xFF555555), fontSize: 13),
            ),
          ] else ...[
            // Địa chỉ lấy hàng
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF7A8B80)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _order!.pickupAddress ?? 'Địa chỉ thu gom tại nhà',
                    style: const TextStyle(color: Color(0xFF2A3E30), fontSize: 13.5),
                  ),
                ),
              ],
            ),
            // Thông tin Collector (nếu đã có)
            if (_order!.collectorName != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF90CAF9), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin tài xế',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xFF1565C0),
                          child: Icon(Icons.person, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _order!.collectorName!,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A2E22)),
                              ),
                              if (_order!.collectorPhone != null)
                                Text(
                                  _order!.collectorPhone!,
                                  style: const TextStyle(color: Color(0xFF555555), fontSize: 12.5),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_order!.collectorVehicleType != null || _order!.collectorLicensePlate != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.local_shipping_outlined, size: 16, color: Color(0xFF7A8B80)),
                          const SizedBox(width: 6),
                          Text(
                            '${_order!.collectorVehicleType ?? 'Xe thu gom'}'  
                            '${_order!.collectorLicensePlate != null ? ' • ${_order!.collectorLicensePlate}' : ''}',
                            style: const TextStyle(color: Color(0xFF7A8B80), fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ] else if (_order!.statusName.toLowerCase() == 'pending') ...[
              // Chưa có tài xế nhận
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFCC02), width: 1),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search_rounded, size: 18, color: Color(0xFFF57C00)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hệ thống đang tìm tài xế gần nhất…',
                        style: TextStyle(fontSize: 13, color: Color(0xFFF57C00), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // 3. Thẻ Danh sách các loại rác
  Widget _buildItemsCard() {
    final numFmt = NumberFormat('#,###');

    return Container(
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
              const Text(
                'Danh mục rác khai báo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  color: Color(0xFF1A2E22),
                ),
              ),
              Text(
                '${_order!.items.length} loại',
                style: const TextStyle(color: Color(0xFF7A8B80), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _order!.items.length,
            separatorBuilder: (_, __) => const Divider(height: 18),
            itemBuilder: (context, index) {
              final item = _order!.items[index];
              final hasActual = item.actualWeight != null;
              final weightDisplay = hasActual
                  ? '${item.actualWeight} ${item.unit}'
                  : '${item.estimatedWeight} ${item.unit} (ước tính)';

              final subTotal = hasActual && item.actualSubTotal != null
                  ? item.actualSubTotal!
                  : item.estimatedSubTotal;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.recycling_rounded, color: AppColors.primaryGreen, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.categoryName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Đơn giá: ${numFmt.format(item.unitPrice)} GP / ${item.unit}',
                          style: const TextStyle(color: Color(0xFF7A8B80), fontSize: 12),
                        ),
                        Text(
                          'Khối lượng: $weightDisplay',
                          style: TextStyle(
                            color: hasActual ? const Color(0xFF1B8E5A) : const Color(0xFF555555),
                            fontWeight: hasActual ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${numFmt.format(subTotal)} GP',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: Color(0xFF1A2E22),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // 4. Thẻ Bảng kê tài chính (Ledger Summary)
  Widget _buildLedgerSummaryCard() {
    final numFmt = NumberFormat('#,###');
    final isCompleted = _order!.statusName.toLowerCase() == 'completed';

    final totalAmount = isCompleted && _order!.totalActualAmount != null
        ? _order!.totalActualAmount!
        : _order!.totalEstimatedAmount;

    final netAmount = isCompleted && _order!.netActualAmount != null
        ? _order!.netActualAmount!
        : _order!.netEstimatedAmount;

    return Container(
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
          const Text(
            'Bảng tính điểm GreenPoints',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.5,
              color: Color(0xFF1A2E22),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCompleted ? 'Tổng giá trị thực tế:' : 'Tổng giá trị ước tính:',
                style: const TextStyle(color: Color(0xFF555555), fontSize: 13.5),
              ),
              Text(
                '${numFmt.format(totalAmount)} GP',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          if (_order!.platformFee > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Phí dịch vụ thu gom tận nhà (20%):',
                  style: TextStyle(color: Color(0xFFE53935), fontSize: 13.5),
                ),
                Text(
                  '-${numFmt.format(_order!.platformFee)} GP',
                  style: const TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ],
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCompleted ? 'Thực nhận vào Ví:' : 'Ước tính thực nhận:',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1A2E22),
                ),
              ),
              Text(
                '${numFmt.format(netAmount)} GP',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '≈ ${numFmt.format(netAmount * 10)}đ giá trị quà tặng',
              style: const TextStyle(color: Color(0xFF7A8B80), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Thẻ Tác động môi trường
  Widget _buildEcoImpactCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Row(
        children: [
          const Icon(Icons.forest_rounded, color: Color(0xFF2E7D32), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tác động bảo vệ môi trường',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32), fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'Đơn hàng này giúp giảm phát thải ~${_order!.estimatedCo2ReducedKg} kg CO₂ tương đương bảo tồn cây xanh! 🌲',
                  style: const TextStyle(color: Color(0xFF1B3D2F), fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 6. Nút Mở QR
  Widget _buildQrButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SellerQrDisplayScreen(
                orderId: _order!.orderId,
                orderInfo: '${_order!.items.length} loại rác • ${_translateMethod(_order!.methodName)}',
              ),
            ),
          );
        },
        icon: const Icon(Icons.qr_code_2_rounded, size: 22),
        label: const Text('Mở mã QR cho Bên Mua quét', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildLiveTrackingButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LiveTrackingScreen(
                token: widget.token,
                orderId: _order!.orderId,
                pickupLatitude: _order!.pickupLatitude ?? 0.0,
                pickupLongitude: _order!.pickupLongitude ?? 0.0,
              ),
            ),
          );
        },
        icon: const Icon(Icons.location_on_outlined, size: 22),
        label: const Text('Theo dõi tài xế', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ xử lý';
      case 'driverassigned':
        return 'Đã có tài xế nhận';
      case 'inprogress':
        return 'Đang thực hiện thu gom';
      case 'completed':
        return 'Giao dịch hoàn tất';
      case 'cancelled':
        return 'Đơn hàng đã hủy';
      default:
        return status;
    }
  }

  String _translateMethod(String method) {
    if (method.toLowerCase().contains('drop')) return 'Tự mang đi';
    return 'Gọi thu gom tận nơi';
  }
}

// Data class hỗ trợ cho Pickup Stepper
class _PickupStep {
  final int id;
  final String label;
  final IconData icon;
  final String statusKey;
  const _PickupStep({
    required this.id,
    required this.label,
    required this.icon,
    required this.statusKey,
  });
}
