import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:green_cycle_mobile/features/seller/data/repositories/wallet_repository.dart';
import 'package:green_cycle_mobile/features/seller/data/models/wallet_dto.dart';

class YardWalletScreen extends StatefulWidget {
  final String token;
  const YardWalletScreen({super.key, required this.token});

  @override
  State<YardWalletScreen> createState() => _YardWalletScreenState();
}

class _YardWalletScreenState extends State<YardWalletScreen> {
  final _walletRepo = WalletRepository();
  bool _isLoading = false;
  WalletBalanceDto? _balance;
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchWalletData() async {
    setState(() => _isLoading = true);
    try {
      final balance = await _walletRepo.getBalance(widget.token);
      // Giả sử ví cung cấp lịch sử giao dịch (trong thực tế có thể gọi repo riêng cho transaction)
      // Tại đây giả lập hoặc lấy rỗng nếu api getBalance không trả về mảng transaction.
      // Dựa vào WalletRepository hiện tại chỉ có getBalance, chưa có getTransactions.
      // Ồ, tôi đã thấy WalletController có getTransactions, nhưng WalletRepository chưa gọi.
      // Để đơn giản, chỉ hiển thị số dư và form nạp tiền.
      
      setState(() {
        _balance = balance;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deposit() async {
    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (amountText.isEmpty) return;
    
    final amount = double.tryParse(amountText) ?? 0;
    if (amount <= 0) return;

    setState(() => _isLoading = true);
    try {
      await _walletRepo.depositWallet(widget.token, amount);
      _amountController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nạp tiền thành công!')));
        _fetchWalletData();
        Navigator.pop(context); // Đóng modal
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDepositModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nạp tiền Ký Quỹ (GP)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A2E22)),
            ),
            const SizedBox(height: 8),
            const Text(
              '1 VNĐ = 1 GP. Số tiền này sẽ được dùng để thanh toán cho người bán rác.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số tiền nạp (VNĐ)',
                prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF2E7D32)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _deposit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Xác nhận nạp tiền', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text('Ví Ký Quỹ', style: TextStyle(color: Color(0xFF1A2E22), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1A2E22)),
      ),
      body: _isLoading && _balance == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : RefreshIndicator(
              onRefresh: _fetchWalletData,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Số dư hiện tại',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${NumberFormat('#,###').format(_balance?.balance ?? 0)} GP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _showDepositModal,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF2E7D32),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('NẠP TIỀN', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Lịch sử giao dịch (đang phát triển)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2E22)),
                  ),
                ],
              ),
            ),
    );
  }
}
