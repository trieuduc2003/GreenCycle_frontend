import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/yard_repository.dart';

class YardOrderHistoryScreen extends StatefulWidget {
  final String token;
  const YardOrderHistoryScreen({super.key, required this.token});

  @override
  State<YardOrderHistoryScreen> createState() => _YardOrderHistoryScreenState();
}

class _YardOrderHistoryScreenState extends State<YardOrderHistoryScreen> {
  final _yardRepo = YardRepository();
  bool _isLoading = false;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final data = await _yardRepo.getYardOrderHistory(token: widget.token);
      setState(() {
        _orders = data;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text('Lịch sử Thu mua', style: TextStyle(color: Color(0xFF1A2E22), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1A2E22)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : RefreshIndicator(
              onRefresh: _fetchHistory,
              child: _orders.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        const Icon(Icons.history, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Center(child: Text('Chưa có lịch sử thu mua', style: TextStyle(color: Colors.grey, fontSize: 16))),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        final dateStr = order['createdAt'] as String?;
                        final dateObj = dateStr != null ? DateTime.tryParse(dateStr)?.toLocal() : null;
                        final dateText = dateObj != null ? DateFormat('dd/MM/yyyy HH:mm').format(dateObj) : '';
                        final total = order['totalEstimatedAmount'] as num? ?? 0;
                        final status = order['statusName'] as String? ?? 'Không rõ';
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Đơn hàng #${order['orderId']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: status == 'Completed' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: status == 'Completed' ? Colors.green : Colors.orange,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Ngày tạo: $dateText', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                const SizedBox(height: 8),
                                const Divider(),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${order['itemsCount'] ?? 0} mặt hàng', style: const TextStyle(color: Color(0xFF1A2E22))),
                                    Text(
                                      '${NumberFormat('#,###').format(total)} GP',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32), fontSize: 16),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
