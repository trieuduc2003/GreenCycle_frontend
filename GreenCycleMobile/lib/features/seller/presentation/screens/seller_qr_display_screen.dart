import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Màn hình Người Bán hiển thị mã QR để Chủ Vựa quét.
/// QR chứa chuỗi: "GREENCYCLE_ORDER_{orderId}"
class SellerQrDisplayScreen extends StatelessWidget {
  final int orderId;
  final String orderInfo; // mô tả tóm tắt đơn hàng

  const SellerQrDisplayScreen({
    super.key,
    required this.orderId,
    required this.orderInfo,
  });

  String get _qrData => 'GREENCYCLE_ORDER_$orderId';

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
          'Mã QR Giao dịch',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A2E22)),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Instruction
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1B8E5A).withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF1B8E5A), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đưa điện thoại cho Chủ Vựa quét mã QR này để hoàn tất giao dịch.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF2E7D32)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // QR Code Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Logo at top
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B8E5A),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.recycling_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'GreenCycle',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B8E5A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // QR Code
                    QrImageView(
                      data: _qrData,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF1A2E22),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF1A2E22),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Order ID
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F7F4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Đơn hàng #$orderId',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2E22),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Order summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined, color: Color(0xFF1B8E5A), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        orderInfo,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF1A2E22)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Waiting indicator
              const _WaitingIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animation "đang chờ..." phía dưới QR
class _WaitingIndicator extends StatefulWidget {
  const _WaitingIndicator();

  @override
  State<_WaitingIndicator> createState() => _WaitingIndicatorState();
}

class _WaitingIndicatorState extends State<_WaitingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            color: const Color(0xFF1B8E5A),
            strokeWidth: 3,
            value: null,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Đang chờ Chủ Vựa quét mã...',
          style: TextStyle(color: Color(0xFF7A8B80), fontSize: 13),
        ),
        const SizedBox(height: 4),
        const Text(
          'Bạn sẽ nhận thông báo xác nhận sau khi quét',
          style: TextStyle(color: Color(0xFFB0BEC5), fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
