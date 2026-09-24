import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/voucher_dto.dart';
import '../../data/models/wallet_dto.dart';
import '../../data/repositories/voucher_repository.dart';
import '../../data/repositories/wallet_repository.dart';
import 'my_vouchers_screen.dart';

class RewardStoreScreen extends StatefulWidget {
  final String token;
  final VoidCallback? onWalletChanged;
  final VoidCallback? onBackToHome;

  const RewardStoreScreen({
    super.key,
    required this.token,
    this.onWalletChanged,
    this.onBackToHome,
  });

  @override
  State<RewardStoreScreen> createState() => _RewardStoreScreenState();
}

class _RewardStoreScreenState extends State<RewardStoreScreen> {
  final _voucherRepo = VoucherRepository();
  final _walletRepo = WalletRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<VoucherDto> _vouchers = [];
  WalletBalanceDto? _wallet;

  String _selectedCategory = 'Tất cả';
  final List<String> _categories = [
    'Tất cả',
    'F&B',
    'Sống xanh',
    'Mua sắm',
    'Giải trí',
    'Vận chuyển',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _voucherRepo.getAvailableVouchers(),
        _walletRepo.getBalance(widget.token),
      ]);

      if (mounted) {
        setState(() {
          _vouchers = results[0] as List<VoucherDto>;
          _wallet = results[1] as WalletBalanceDto;
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

  List<VoucherDto> get _filteredVouchers {
    if (_selectedCategory == 'Tất cả') {
      return _vouchers;
    }
    return _vouchers.where((v) => v.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
  }

  Future<void> _handleRedeem(VoucherDto voucher) async {
    final balance = _wallet?.balance ?? 0.0;
    if (balance < voucher.pointCost) {
      final needed = voucher.pointCost - balance;
      _showInsufficientPointsDialog(voucher, needed);
      return;
    }

    _showConfirmRedeemDialog(voucher);
  }

  void _showInsufficientPointsDialog(VoucherDto voucher, double needed) {
    final numFmt = NumberFormat('#,###');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('Chưa đủ GreenPoints', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Để đổi món quà "${voucher.title}", bạn cần ${numFmt.format(voucher.pointCost)} GP.',
              style: const TextStyle(fontSize: 14, color: Color(0xFF2A3E30)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFF57F17), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bạn cần tích lũy thêm ${numFmt.format(needed)} GP nữa từ việc bán rác tái chế!',
                      style: const TextStyle(color: Color(0xFFE65100), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  void _showConfirmRedeemDialog(VoucherDto voucher) {
    final numFmt = NumberFormat('#,###');
    final balance = _wallet?.balance ?? 0.0;
    final remaining = balance - voucher.pointCost;

    showModalBottomSheet(
      context: context,
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
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.card_giftcard_rounded, color: AppColors.primaryGreen, size: 36),
            ),
            const SizedBox(height: 14),
            const Text(
              'Xác nhận đổi quà tặng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B3D2F)),
            ),
            const SizedBox(height: 8),
            Text(
              voucher.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 18),
            // Balance breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAF8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0EBE4)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Số dư hiện tại:', style: TextStyle(color: Color(0xFF7A8B80), fontSize: 13.5)),
                      Text('${numFmt.format(balance)} GP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Điểm trừ để đổi quà:', style: TextStyle(color: Color(0xFFE53935), fontSize: 13.5)),
                      Text('-${numFmt.format(voucher.pointCost)} GP', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE53935), fontSize: 14)),
                    ],
                  ),
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Số dư sau khi đổi:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B3D2F), fontSize: 14)),
                      Text('${numFmt.format(remaining)} GP', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen, fontSize: 15)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text('Huỷ bỏ', style: TextStyle(color: Color(0xFF555555), fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _executeRedeem(voucher);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Đồng ý đổi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeRedeem(VoucherDto voucher) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      ),
    );

    try {
      final res = await _voucherRepo.redeemVoucher(widget.token, voucher.voucherId);
      if (mounted) {
        Navigator.pop(context); // close loading
        _showSocialFlexSuccessModal(res);
        _loadData(); // reload vouchers and balance
        widget.onWalletChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Social Flexing (FR-SOC-01) & Celebration Modal
  void _showSocialFlexSuccessModal(RedeemVoucherResponseDto res) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Celebration badge
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🎉', style: TextStyle(fontSize: 34)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Đổi Quà Thành Công!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B3D2F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                res.userVoucher?.title ?? 'Quà tặng GreenCycle',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 16),
              // Voucher Code Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8F4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'MÃ QUÀ TẶNG CỦA BẠN:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7A8B80)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      res.userVoucher?.voucherCode ?? 'GC-VOUCHER',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Color(0xFF1B8E5A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Environmental Impact Flexing Box (SRS FR-SOC-01)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.forest_rounded, color: Color(0xFF2E7D32), size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tác động sống xanh:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Bạn vừa góp phần giảm ~${res.co2ReducedKg}kg CO₂ và bảo vệ tương đương ${res.treesSaved} cây xanh! 🌲',
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF1B3D2F)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MyVouchersScreen(token: widget.token)),
                    );
                  },
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Xem trong Kho quà'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tiếp tục xem quà', style: TextStyle(color: Color(0xFF7A8B80))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primaryGreen,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildTopBar()),
              SliverToBoxAdapter(child: _buildBalanceHeaderCard()),
              SliverToBoxAdapter(child: _buildCategoryChips()),
              _buildVouchersSliver(),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final canPop = Navigator.canPop(context);
    final hasBackAction = canPop || widget.onBackToHome != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 12),
      child: Row(
        children: [
          if (hasBackAction)
            GestureDetector(
              onTap: () {
                if (canPop) {
                  Navigator.pop(context);
                } else if (widget.onBackToHome != null) {
                  widget.onBackToHome!();
                }
              },
              child: Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Color(0xFF1B3D2F),
                ),
              ),
            ),
          const Text(
            'Cửa Hàng Đổi Quà',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B3D2F),
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MyVouchersScreen(token: widget.token)),
              );
            },
            icon: const Icon(Icons.inventory_2_rounded, size: 16),
            label: const Text('Kho quà', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryGreen,
              elevation: 1,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFC8E6C9)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceHeaderCard() {
    final numFmt = NumberFormat('#,###');
    final balance = _wallet?.balance ?? 0.0;
    final vnd = _wallet?.balanceInVnd ?? 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B8E5A), Color(0xFF0D6B41)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B8E5A).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ĐIỂM GREENPOINTS KHẢ DỤNG',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        numFmt.format(balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'GP',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '≈ ${numFmt.format(vnd)}đ giá trị quy đổi',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isSelected ? 0.15 : 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF555555),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVouchersSliver() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    if (_errorMessage != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: Color(0xFF555555))),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final list = _filteredVouchers;
    if (list.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text(
            'Chưa có quà tặng nào trong danh mục này.',
            style: TextStyle(color: Color(0xFF7A8B80), fontSize: 14),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final voucher = list[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildVoucherCard(voucher),
            );
          },
          childCount: list.length,
        ),
      ),
    );
  }

  Widget _buildVoucherCard(VoucherDto voucher) {
    final numFmt = NumberFormat('#,###');
    final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final balance = _wallet?.balance ?? 0.0;
    final isAffordable = balance >= voucher.pointCost;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left image/icon
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: _getCategoryBgColor(voucher.category),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getCategoryIcon(voucher.category),
                color: _getCategoryColor(voucher.category),
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            // Middle Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(voucher.category).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          voucher.category,
                          style: TextStyle(
                            color: _getCategoryColor(voucher.category),
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (voucher.quantity != null)
                        Text(
                          'Còn ${voucher.quantity} suất',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF8A9A90)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    voucher.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B3D2F),
                    ),
                  ),
                  if (voucher.description != null && voucher.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      voucher.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7A8B80),
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.stars_rounded, color: Color(0xFF2E7D32), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${numFmt.format(voucher.pointCost)} GP',
                              style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (voucher.discountValue > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          currencyFmt.format(voucher.discountValue),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A9A90),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => _handleRedeem(voucher),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAffordable ? AppColors.primaryGreen : const Color(0xFF9E9E9E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: Text(
                          isAffordable ? 'Đổi quà' : 'Cần thêm GP',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
