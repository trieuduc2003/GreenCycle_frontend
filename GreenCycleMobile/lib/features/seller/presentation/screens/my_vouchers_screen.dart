import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/voucher_dto.dart';
import '../../data/repositories/voucher_repository.dart';

class MyVouchersScreen extends StatefulWidget {
  final String token;

  const MyVouchersScreen({super.key, required this.token});

  @override
  State<MyVouchersScreen> createState() => _MyVouchersScreenState();
}

class _MyVouchersScreenState extends State<MyVouchersScreen>
    with SingleTickerProviderStateMixin {
  final _voucherRepo = VoucherRepository();
  bool _isLoading = true;
  String? _errorMessage;
  List<UserVoucherDto> _allVouchers = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMyVouchers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMyVouchers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _voucherRepo.getMyVouchers(widget.token);
      if (mounted) {
        setState(() {
          _allVouchers = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleUseVoucher(UserVoucherDto voucher) async {
    try {
      await _voucherRepo.useVoucher(widget.token, voucher.userVoucherId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã sử dụng thành công voucher: ${voucher.title}'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        _loadMyVouchers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text(
          'Kho Quà Của Tôi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B3D2F),
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGreen,
          indicatorWeight: 3,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: const Color(0xFF7A8B80),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Khả dụng'),
            Tab(text: 'Đã dùng'),
            Tab(text: 'Hết hạn'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : _errorMessage != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildVoucherList(_allVouchers.where((v) => !v.isUsed && !v.isExpired).toList(), 0),
                    _buildVoucherList(_allVouchers.where((v) => v.isUsed).toList(), 1),
                    _buildVoucherList(_allVouchers.where((v) => !v.isUsed && v.isExpired).toList(), 2),
                  ],
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 56, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Đã có lỗi xảy ra',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF555555), fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadMyVouchers,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherList(List<UserVoucherDto> vouchers, int tabIndex) {
    if (vouchers.isEmpty) {
      final messages = [
        'Bạn chưa có mã quà nào khả dụng.\nHãy đổi điểm GreenPoints tại Cửa hàng nhé!',
        'Bạn chưa sử dụng mã quà nào.',
        'Không có mã quà nào hết hạn.'
      ];
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                tabIndex == 0 ? Icons.card_giftcard_rounded : Icons.inventory_2_outlined,
                size: 64,
                color: const Color(0xFFB0BEC5),
              ),
              const SizedBox(height: 16),
              Text(
                messages[tabIndex],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF7A8B80),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFmt = DateFormat('dd/MM/yyyy');

    return RefreshIndicator(
      onRefresh: _loadMyVouchers,
      color: AppColors.primaryGreen,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: vouchers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final item = vouchers[index];
          final isUsable = !item.isUsed && !item.isExpired;

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category icon badge
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _getCategoryBgColor(item.category),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _getCategoryIcon(item.category),
                          color: _getCategoryColor(item.category),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(item.category).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.category,
                                    style: TextStyle(
                                      color: _getCategoryColor(item.category),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (item.isUsed)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Đã sử dụng',
                                      style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  )
                                else if (item.isExpired)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Đã hết hạn',
                                      style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Sẵn sàng dùng',
                                      style: TextStyle(color: Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B3D2F),
                              ),
                            ),
                            if (item.discountValue > 0) ...[
                              const SizedBox(height: 3),
                              Text(
                                'Trị giá: ${currencyFmt.format(item.discountValue)}',
                                style: const TextStyle(
                                  color: Color(0xFFE65100),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              'Hạn dùng: ${dateFmt.format(item.expiredAt)}',
                              style: const TextStyle(
                                color: Color(0xFF8A9A90),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Dashed separator line
                _buildDottedLine(),
                // Bottom voucher code & action
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBFDFB),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_2_rounded, size: 20, color: Color(0xFF43A047)),
                      const SizedBox(width: 8),
                      Text(
                        item.voucherCode,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: Color(0xFF1B3D2F),
                        ),
                      ),
                      const Spacer(),
                      if (isUsable)
                        ElevatedButton(
                          onPressed: () => _showVoucherDetailModal(item),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: const Text('Dùng mã', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                        )
                      else
                        TextButton.icon(
                          onPressed: () => _showVoucherDetailModal(item),
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text('Chi tiết', style: TextStyle(fontSize: 12.5)),
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFF7A8B80)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showVoucherDetailModal(UserVoucherDto item) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final isUsable = !item.isUsed && !item.isExpired;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B3D2F),
              ),
            ),
            if (item.description != null && item.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.description!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF7A8B80)),
              ),
            ],
            const SizedBox(height: 20),
            // QR Code display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: item.voucherCode,
                version: QrVersions.auto,
                size: 180.0,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF1B3D2F)),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1B3D2F)),
              ),
            ),
            const SizedBox(height: 16),
            // Voucher Code Text with Copy
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8F4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.voucherCode,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Color(0xFF1B8E5A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20, color: Color(0xFF1B8E5A)),
                    tooltip: 'Sao chép mã',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: item.voucherCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép mã voucher vào bộ nhớ tạm!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF8A9A90)),
                const SizedBox(width: 6),
                Text(
                  'Hạn sử dụng: ${dateFmt.format(item.expiredAt)}',
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF8A9A90)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (isUsable)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmUseVoucher(item);
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Xác nhận đã dùng tại quầy'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmUseVoucher(UserVoucherDto item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Xác nhận dùng voucher?'),
        content: Text('Bạn có chắc chắn muốn đánh dấu đã sử dụng mã voucher "${item.title}" không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleUseVoucher(item);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đã dùng'),
          ),
        ],
      ),
    );
  }

  Widget _buildDottedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFE0E0E0))),
            );
          }),
        );
      },
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'f&b':
        return const Color(0xFFE65100);
      case 'sống xanh':
        return const Color(0xFF2E7D32);
      case 'vận chuyển':
        return const Color(0xFF0277BD);
      case 'giải trí':
        return const Color(0xFF7B1FA2);
      default:
        return const Color(0xFFD84315);
    }
  }

  Color _getCategoryBgColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'f&b':
        return const Color(0xFFFFF3E0);
      case 'sống xanh':
        return const Color(0xFFE8F5E9);
      case 'vận chuyển':
        return const Color(0xFFE1F5FE);
      case 'giải trí':
        return const Color(0xFFF3E5F5);
      default:
        return const Color(0xFFFBE9E7);
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'f&b':
        return Icons.restaurant_rounded;
      case 'sống xanh':
        return Icons.eco_rounded;
      case 'vận chuyển':
        return Icons.local_shipping_rounded;
      case 'giải trí':
        return Icons.movie_creation_rounded;
      default:
        return Icons.shopping_bag_rounded;
    }
  }
}
