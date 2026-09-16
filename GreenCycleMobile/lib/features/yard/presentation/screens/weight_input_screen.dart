import 'package:flutter/material.dart';
import '../../data/repositories/yard_repository.dart';
import '../../../../features/transaction/data/models/transaction_dto.dart';
import '../../../../features/transaction/data/repositories/transaction_repository.dart';

/// Màn hình Chủ Vựa nhập số liệu cân thực tế sau khi quét QR.
/// Sau khi nhập và gửi, hệ thống trigger pop-up Xác nhận chéo trên máy Người Bán.
class WeightInputScreen extends StatefulWidget {
  final String token;
  final int orderId;

  const WeightInputScreen({
    super.key,
    required this.token,
    required this.orderId,
  });

  @override
  State<WeightInputScreen> createState() => _WeightInputScreenState();
}

class _WeightInputScreenState extends State<WeightInputScreen> {
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;

  List<OrderDetailItem> _details = [];
  final _txRepo = TransactionRepository();
  final _yardRepo = YardRepository();

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      final details = await _yardRepo.getOrderDetails(
        token: widget.token,
        orderId: widget.orderId,
      );
      setState(() {
        _details = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _sendConfirmation() async {
    for (final d in _details) {
      if (d.actualWeight <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập khối lượng thực tế cho tất cả loại rác!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      if (d.actualWeight > 30) {
        final confirm = await _showHardLimitWarning(d.categoryName, d.actualWeight);
        if (!confirm) return;
      }
    }

    setState(() => _isSending = true);
    try {
      await _txRepo.initiateTransaction(
        token: widget.token,
        request: InitiateTransactionRequest(
          orderId: widget.orderId,
          actualWeights: _details.map((d) => ActualWeightDto(
            orderDetailId: d.orderDetailId,
            actualWeight: d.actualWeight,
          )).toList(),
        ),
      );

      if (mounted) {
        _showSuccessDialog();
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
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<bool> _showHardLimitWarning(String name, double weight) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text('Cảnh báo khối lượng lớn', style: TextStyle(fontSize: 16)),
              ],
            ),
            content: Text(
              '$name: ${weight.toStringAsFixed(1)} kg vượt giới hạn 30kg.\n\nBạn có chắc số liệu này đúng không?',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Nhập lại')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xác nhận vẫn đúng', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 64, color: Color(0xFF1B8E5A)),
            SizedBox(height: 16),
            Text(
              'Đã gửi xác nhận!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A2E22)),
            ),
            SizedBox(height: 8),
            Text(
              'Đang chờ khách hàng xác nhận trên ứng dụng của họ...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF7A8B80)),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B8E5A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back to dashboard
              },
              child: const Text('Quay về Trang chủ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A2E22)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập số liệu thực tế',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E22)),
            ),
            Text(
              'Đơn #${widget.orderId}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF7A8B80)),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B8E5A)))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : _buildContent(),
      bottomNavigationBar: _buildSubmitButton(),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
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
                  'Nhập khối lượng thực tế sau khi cân. Hệ thống sẽ gửi thông báo xác nhận cho khách hàng.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF2E7D32)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ..._details.asMap().entries.map((entry) => _buildWeightInputCard(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildWeightInputCard(int index, OrderDetailItem detail) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F4EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.category_outlined, size: 18, color: Color(0xFF1B8E5A)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(detail.categoryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A2E22))),
                    Text('Ước tính: ${detail.estimatedWeight} ${detail.unit}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF7A8B80))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Khối lượng thực tế', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF7A8B80))),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildAdjustBtn(
                icon: Icons.remove_rounded,
                onTap: () {
                  setState(() {
                    if (_details[index].actualWeight > 0) {
                      _details[index] = _details[index].copyWith(
                        actualWeight: (_details[index].actualWeight - 0.5).clamp(0, 9999),
                      );
                    }
                  });
                },
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showWeightDialog(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F7F4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: detail.actualWeight > 0
                          ? const Color(0xFF1B8E5A).withOpacity(0.4)
                          : const Color(0xFFDDE4E0)),
                    ),
                    child: Center(
                      child: Text(
                        '${detail.actualWeight.toStringAsFixed(1)} ${detail.unit}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: detail.actualWeight > 0 ? const Color(0xFF1B8E5A) : const Color(0xFFB0BEC5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _buildAdjustBtn(
                icon: Icons.add_rounded,
                onTap: () {
                  setState(() {
                    _details[index] = _details[index].copyWith(
                      actualWeight: _details[index].actualWeight + 0.5,
                    );
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1B8E5A),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: const Color(0xFF1B8E5A).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Future<void> _showWeightDialog(int index) async {
    final controller = TextEditingController(
      text: _details[index].actualWeight > 0 ? _details[index].actualWeight.toStringAsFixed(1) : '',
    );
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Nhập cân nặng (${_details[index].unit})'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ví dụ: 15.5',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B8E5A)),
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val >= 0) {
                setState(() {
                  _details[index] = _details[index].copyWith(actualWeight: val);
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B8E5A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 56),
          ),
          onPressed: _isSending ? null : _sendConfirmation,
          child: _isSending
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : const Text(
                  'Gửi xác nhận cho khách hàng →',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────
class OrderDetailItem {
  final int orderDetailId;
  final String categoryName;
  final String unit;
  final double estimatedWeight;
  double actualWeight;

  OrderDetailItem({
    required this.orderDetailId,
    required this.categoryName,
    required this.unit,
    required this.estimatedWeight,
    this.actualWeight = 0,
  });

  OrderDetailItem copyWith({double? actualWeight}) {
    return OrderDetailItem(
      orderDetailId: orderDetailId,
      categoryName: categoryName,
      unit: unit,
      estimatedWeight: estimatedWeight,
      actualWeight: actualWeight ?? this.actualWeight,
    );
  }
}
