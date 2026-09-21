import 'package:flutter/material.dart';
import '../../data/repositories/yard_repository.dart';
import '../../../../features/transaction/data/models/transaction_dto.dart';
import '../../../../features/transaction/data/repositories/transaction_repository.dart';
import 'transaction_complete_screen.dart';

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

  // Lưu trữ giá trị gộp và khấu hao tạm thời cho từng item
  // key = orderDetailId
  final Map<int, double> _grossWeights = {};
  final Map<int, double> _deductions = {};

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
        for (var d in _details) {
          _grossWeights[d.orderDetailId] = 0;
          _deductions[d.orderDetailId] = 0;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _updateWeight(int detailId, double gross, double deduction) {
    setState(() {
      _grossWeights[detailId] = gross;
      _deductions[detailId] = deduction;
      
      final netWeight = gross * (1 - deduction / 100);
      final index = _details.indexWhere((d) => d.orderDetailId == detailId);
      if (index != -1) {
        _details[index] = _details[index].copyWith(actualWeight: netWeight);
      }
    });
  }

  Future<void> _sendConfirmation() async {
    for (final d in _details) {
      if (d.actualWeight <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập khối lượng lớn hơn 0!'),
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionCompleteScreen(
              token: widget.token,
              orderId: widget.orderId,
            ),
          ),
        );
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
                Text('Khối lượng lớn', style: TextStyle(fontSize: 16)),
              ],
            ),
            content: Text(
              '$name: ${weight.toStringAsFixed(1)} kg.\nBạn có chắc số liệu này đúng?',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Nhập lại')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Đã kiểm tra', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập số liệu thực tế',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2E22)),
            ),
            Text(
              'Đơn #${widget.orderId}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF7A8B80)),
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
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE59835).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE59835).withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.lock_outline, color: Color(0xFFC78330), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Đơn giá được áp dụng chính sách Price Freeze. Bạn chỉ cần nhập khối lượng và tỷ lệ khấu hao.',
                  style: TextStyle(fontSize: 13, color: Color(0xFFC78330), height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._details.map((d) => _buildWeightInputCard(d)),
      ],
    );
  }

  Widget _buildWeightInputCard(OrderDetailItem detail) {
    final id = detail.orderDetailId;
    final gross = _grossWeights[id] ?? 0;
    final deduction = _deductions[id] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B8E5A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.category_outlined, size: 24, color: Color(0xFF1B8E5A)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(detail.categoryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A2E22))),
                    const SizedBox(height: 2),
                    Text('Ước tính: ${detail.estimatedWeight} ${detail.unit}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF7A8B80))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${_formatNumber(detail.unitPrice)} đ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFC78330))),
                  const Text('Khóa giá', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF3F7F4), thickness: 1.5),
          
          // Inputs
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng gộp (kg)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF7A8B80))),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showInputDialog(id, 'Tổng gộp', gross, (val) => _updateWeight(id, val, deduction)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F7F4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDDE4E0)),
                        ),
                        child: Text(
                          gross > 0 ? gross.toStringAsFixed(1) : 'Nhập...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: gross > 0 ? const Color(0xFF1A2E22) : const Color(0xFFB0BEC5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Khấu hao (%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF7A8B80))),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showInputDialog(id, 'Khấu hao %', deduction, (val) => _updateWeight(id, gross, val)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F7F4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDDE4E0)),
                        ),
                        child: Text(
                          deduction > 0 ? '${deduction.toStringAsFixed(0)}%' : '0%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: deduction > 0 ? const Color(0xFF1A2E22) : const Color(0xFFB0BEC5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          // Actual Weight Result
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B8E5A).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Thực nhận:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B8E5A))),
                Text(
                  '${detail.actualWeight.toStringAsFixed(1)} ${detail.unit}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B8E5A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showInputDialog(int id, String title, double current, Function(double) onSaved) async {
    final controller = TextEditingController(
      text: current > 0 ? (title.contains('%') ? current.toStringAsFixed(0) : current.toStringAsFixed(1)) : '',
    );
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nhập số liệu',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B8E5A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val >= 0) {
                onSaved(val);
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
            backgroundColor: const Color(0xFFC78330),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 18),
            elevation: 8,
            shadowColor: const Color(0xFFC78330).withOpacity(0.5),
          ),
          onPressed: _isSending ? null : _sendConfirmation,
          child: _isSending
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
              : const Text(
                  'GỬI XÁC NHẬN GIAO DỊCH',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                ),
        ),
      ),
    );
  }
}

class OrderDetailItem {
  final int orderDetailId;
  final String categoryName;
  final String unit;
  final double estimatedWeight;
  final double unitPrice;
  double actualWeight;

  OrderDetailItem({
    required this.orderDetailId,
    required this.categoryName,
    required this.unit,
    required this.estimatedWeight,
    required this.unitPrice,
    this.actualWeight = 0,
  });

  OrderDetailItem copyWith({double? actualWeight}) {
    return OrderDetailItem(
      orderDetailId: orderDetailId,
      categoryName: categoryName,
      unit: unit,
      estimatedWeight: estimatedWeight,
      unitPrice: unitPrice,
      actualWeight: actualWeight ?? this.actualWeight,
    );
  }
}
