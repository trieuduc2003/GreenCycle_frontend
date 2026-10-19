import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../transaction/data/models/double_confirmation_payload.dart';
import '../../../transaction/data/repositories/transaction_repository.dart';
import '../../../transaction/presentation/widgets/celebration_success_dialog.dart';
import '../../../yard/data/repositories/yard_repository.dart';
import '../../../yard/presentation/screens/weight_input_screen.dart';

/// Màn hình Người Bán hiển thị mã QR để Chủ Vựa quét.
/// Tự động lắng nghe SignalR + Polling kiểm tra số liệu cân thực tế.
/// Khi Vựa hoàn tất cân -> Hiện ngay Dialog Xác Nhận Chéo cho Người Bán!
class SellerQrDisplayScreen extends StatefulWidget {
  final int orderId;
  final String orderInfo;
  final String? token;

  const SellerQrDisplayScreen({
    super.key,
    required this.orderId,
    required this.orderInfo,
    this.token,
  });

  @override
  State<SellerQrDisplayScreen> createState() => _SellerQrDisplayScreenState();
}

class _SellerQrDisplayScreenState extends State<SellerQrDisplayScreen> {
  HubConnection? _hubConnection;
  Timer? _pollingTimer;
  final _txRepo = TransactionRepository();
  final _yardRepo = YardRepository();

  bool _isChecking = false;
  bool _hasTriggeredConfirmation = false;
  bool _isConfirming = false;

  String get _qrData => 'GREENCYCLE_ORDER_${widget.orderId}';

  @override
  void initState() {
    super.initState();
    _initSignalR();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _hubConnection?.stop();
    super.dispose();
  }

  // ── SignalR Setup ──────────────────────────────────────────────────────────
  Future<void> _initSignalR() async {
    if (widget.token == null || widget.token!.isEmpty) return;

    try {
      _hubConnection = HubConnectionBuilder()
          .withUrl(
            ApiEndpoints.transactionHub,
            options: HttpConnectionOptions(
              accessTokenFactory: () async => widget.token!,
            ),
          )
          .withAutomaticReconnect()
          .build();

      _hubConnection?.on('ReceiveDoubleConfirmation', _handleDoubleConfirmationSignalR);

      await _hubConnection?.start();
      print('SellerQrDisplayScreen: SignalR Connected');
    } catch (e) {
      print('SellerQrDisplayScreen: SignalR connect failed: $e');
    }
  }

  void _handleDoubleConfirmationSignalR(List<Object?>? args) {
    if (args != null && args.isNotEmpty && mounted && !_hasTriggeredConfirmation) {
      final payloadMap = args.first as Map<String, dynamic>;
      final payload = DoubleConfirmationPayload.fromJson(payloadMap);
      if (payload.orderId == widget.orderId) {
        _onReceivedConfirmation(payload);
      }
    }
  }

  // ── Smart Polling dự phòng ────────────────────────────────────────────────
  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_hasTriggeredConfirmation && mounted) {
        _checkOrderStatus();
      }
    });
  }

  Future<void> _checkOrderStatus() async {
    if (_isChecking || _hasTriggeredConfirmation || widget.token == null) return;
    setState(() => _isChecking = true);

    try {
      final details = await _yardRepo.getOrderDetails(
        token: widget.token!,
        orderId: widget.orderId,
      );

      // Nếu có chi tiết nào đã có actualWeight > 0, tức là Vựa đã cân xong
      final hasActual = details.any((d) => d.actualWeight > 0);
      if (hasActual && !_hasTriggeredConfirmation && mounted) {
        decimalCalculateAndShow(details);
      }
    } catch (_) {
      // Ignored for polling
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void decimalCalculateAndShow(List<OrderDetailItem> details) {
    double totalActual = 0;
    for (var d in details) {
      totalActual += d.actualWeight * d.unitPrice;
    }

    final platformFee = 0.0; // Drop-off: phí vựa chịu
    final netPoints = totalActual;

    final payload = DoubleConfirmationPayload(
      orderId: widget.orderId,
      methodId: 1, // Drop-off
      yardName: 'Vựa rác GreenCycle',
      totalActualAmount: totalActual,
      platformFee: platformFee,
      netGreenPoints: netPoints,
    );

    _onReceivedConfirmation(payload);
  }

  void _onReceivedConfirmation(DoubleConfirmationPayload payload) {
    _hasTriggeredConfirmation = true;
    _pollingTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildConfirmationDialog(ctx, payload),
    );
  }

  Widget _buildConfirmationDialog(BuildContext dialogCtx, DoubleConfirmationPayload payload) {
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_rounded, color: AppColors.primaryGreen, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Xác nhận số liệu cân ⚖️',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A2E22)),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chủ Vựa (${payload.partnerDisplayName}) đã hoàn tất cân đơn hàng #${payload.orderId}. Vui lòng đối chiếu số tiền:',
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF4A5D50), height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7F4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0EAE3)),
                ),
                child: Column(
                  children: [
                    _buildRowItem('Tổng giá trị thực tế:', '${payload.totalActualAmount.toInt()} VNĐ'),
                    const SizedBox(height: 8),
                    _buildRowItem('Phí nền tảng:', '0 VNĐ (Vựa chịu)'),
                    const Divider(height: 20, color: Color(0xFFDDE7E0)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bạn nhận được:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A2E22)),
                        ),
                        Text(
                          '+${payload.netGreenPoints.toInt()} GP',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: AppColors.primaryGreen),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '1 GreenPoint (GP) = 1 VNĐ. Điểm được cộng thẳng vào ví.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF7A8B80)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isConfirming ? null : () => Navigator.pop(dialogCtx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Xem lại'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isConfirming
                        ? null
                        : () async {
                            setDialogState(() => _isConfirming = true);
                            await _confirmTransaction(dialogCtx, payload);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isConfirming
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Xác nhận & Nhận tiền', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildRowItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7D72))),
        Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF1A2E22))),
      ],
    );
  }

  Future<void> _confirmTransaction(BuildContext dialogCtx, DoubleConfirmationPayload payload) async {
    try {
      if (widget.token != null && widget.token!.isNotEmpty) {
        await _txRepo.confirmTransaction(
          token: widget.token!,
          orderId: payload.orderId,
        );
      }

      if (mounted) {
        Navigator.pop(dialogCtx); // Đóng pop-up xác nhận

        // Tính toán thông số môi trường
        final co2Saved = (payload.netGreenPoints * 0.05).clamp(1.5, 999.0);
        final treesSaved = co2Saved / 20.0;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (celebrationCtx) => CelebrationSuccessDialog(
            title: 'Giao Dịch Thành Công! 🎉',
            message: 'Đơn hàng #${payload.orderId} đã hoàn tất. Điểm thưởng GreenPoints đã được nạp thẳng vào ví của bạn!',
            greenPointsEarned: payload.netGreenPoints,
            amountEarned: payload.netGreenPoints.toDouble(),
            co2ReducedKg: co2Saved,
            treesSaved: treesSaved,
            partnerName: payload.partnerDisplayName,
            onClose: () => Navigator.pop(celebrationCtx),
          ),
        );

        // Đóng màn hình QR và trả về kết quả true để reload
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xác nhận: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
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
                        'Đưa điện thoại cho Chủ Vựa quét mã QR này để bắt đầu cân và thanh toán.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF2E7D32)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
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
                          'GreenCycle Pay',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B8E5A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F7F4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Đơn hàng #${widget.orderId}',
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
                        widget.orderInfo,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF1A2E22)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Waiting indicator & manual refresh
              Column(
                children: [
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      color: Color(0xFF1B8E5A),
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Đang chờ Chủ Vựa quét và nhập cân...',
                    style: TextStyle(color: Color(0xFF4A5D50), fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Màn hình sẽ tự động hiển thị số tiền ngay khi vựa cân xong',
                    style: TextStyle(color: Color(0xFF7A8B80), fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: _isChecking ? null : _checkOrderStatus,
                    icon: _isChecking
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF1B8E5A)),
                    label: const Text(
                      'Làm mới trạng thái',
                      style: TextStyle(color: Color(0xFF1B8E5A), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
