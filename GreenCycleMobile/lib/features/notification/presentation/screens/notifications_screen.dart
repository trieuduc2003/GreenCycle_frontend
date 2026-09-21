import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';

// ─── DTO ──────────────────────────────────────────────────────────────────────

class WalletTransactionDto {
  final int transactionId;
  final double amount;
  final String transactionType;
  final int? referenceOrderId;
  final int? referenceVoucherId;
  final DateTime createdAt;
  final String? description;

  bool get isCredit => amount > 0;

  WalletTransactionDto({
    required this.transactionId,
    required this.amount,
    required this.transactionType,
    this.referenceOrderId,
    this.referenceVoucherId,
    required this.createdAt,
    this.description,
  });

  factory WalletTransactionDto.fromJson(Map<String, dynamic> json) {
    return WalletTransactionDto(
      transactionId: json['transactionId'] ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      transactionType: json['transactionType'] ?? '',
      referenceOrderId: json['referenceOrderId'],
      referenceVoucherId: json['referenceVoucherId'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      description: json['description'],
    );
  }
}

// ─── Repository ───────────────────────────────────────────────────────────────

class _TransactionRepo {
  Future<List<WalletTransactionDto>> fetchTransactions(String token) async {
    try {
      final res = await http.get(
        Uri.parse(ApiEndpoints.walletTransactions),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = (body['data'] as List<dynamic>?) ?? [];
        return list
            .map((e) => WalletTransactionDto.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

/// Màn hình Thông báo — hiển thị lịch sử giao dịch ví dưới dạng feed thông báo.
class NotificationsScreen extends StatefulWidget {
  final String token;

  const NotificationsScreen({super.key, required this.token});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repo = _TransactionRepo();
  bool _isLoading = true;
  List<WalletTransactionDto> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await _repo.fetchTransactions(widget.token);
    if (mounted) {
      setState(() {
        _items = result;
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
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1A2E22)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thông báo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2E22),
          ),
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1A2E22)),
              onPressed: _load,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : _items.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: AppColors.primaryGreen,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _NotificationCard(item: _items[index]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 44,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chưa có thông báo nào',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2E22),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Các hoạt động giao dịch của bạn\nsẽ xuất hiện tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF7A8B80), height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final WalletTransactionDto item;

  const _NotificationCard({required this.item});

  // Ánh xạ loại giao dịch → icon + màu + tiêu đề
  ({IconData icon, Color color, Color bg, String title}) get _meta {
    final type = item.transactionType.toLowerCase();

    if (type.contains('earn') || type.contains('receive') || type.contains('credit')) {
      return (
        icon: Icons.arrow_downward_rounded,
        color: const Color(0xFF1B8E5A),
        bg: const Color(0xFFE0F4EB),
        title: 'Nhận GreenPoints',
      );
    } else if (type.contains('redeem') || type.contains('voucher')) {
      return (
        icon: Icons.card_giftcard_rounded,
        color: const Color(0xFFD4770A),
        bg: const Color(0xFFFFF3E0),
        title: 'Đổi Voucher',
      );
    } else if (type.contains('debit') || type.contains('spend')) {
      return (
        icon: Icons.arrow_upward_rounded,
        color: const Color(0xFFE53935),
        bg: const Color(0xFFFFEBEE),
        title: 'Chi GreenPoints',
      );
    } else {
      return (
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF1565C0),
        bg: const Color(0xFFE3F2FD),
        title: 'Giao dịch ví',
      );
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
    if (diff.inDays < 1) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return DateFormat('dd/MM/yyyy HH:mm').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final m = _meta;
    final amountText = item.isCredit
        ? '+${item.amount.toStringAsFixed(0)} GP'
        : '${item.amount.toStringAsFixed(0)} GP';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Icon ──
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: m.bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(m.icon, color: m.color, size: 22),
          ),
          const SizedBox(width: 12),

          // ── Content ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        m.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1A2E22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      amountText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: item.isCredit ? const Color(0xFF1B8E5A) : const Color(0xFFE53935),
                      ),
                    ),
                  ],
                ),
                if (item.description != null && item.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF7A8B80)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (item.referenceOrderId != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Đơn hàng #${item.referenceOrderId}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  _formatDate(item.createdAt),
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFFB0BEC5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
