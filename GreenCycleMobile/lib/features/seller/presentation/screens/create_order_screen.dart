import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/order_dto.dart';
import '../../data/repositories/order_repository.dart';

/// Màn hình A06: Tạo đơn & khai báo rác (Người bán)
class CreateOrderScreen extends StatefulWidget {
  final String token;
  final String fullName;

  const CreateOrderScreen({
    super.key,
    required this.token,
    required this.fullName,
  });

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _orderRepo = OrderRepository();
  final _quantityController = TextEditingController(text: '15');

  // State
  int _selectedMethodId = 1; // 1: Drop-off (Tự mang đi), 2: Pick-up (Gọi thu gom)
  WasteCategoryDto? _selectedCategory;
  List<WasteCategoryDto> _categories = [];
  bool _isLoadingCategories = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    final list = await _orderRepo.getWasteCategories();
    if (mounted) {
      setState(() {
        _categories = list;
        if (list.isNotEmpty) {
          _selectedCategory = list.first; // Default to "Giấy / Carton"
        }
        _isLoadingCategories = false;
      });
    }
  }

  double get _quantity {
    final text = _quantityController.text.trim();
    return double.tryParse(text) ?? 0.0;
  }

  double get _unitPrice => _selectedCategory?.unitPrice ?? 0.0;

  double get _totalEstimated => _quantity * _unitPrice;

  double get _platformFee => _selectedMethodId == 2 ? _totalEstimated * 0.20 : 0.0;

  double get _netEstimated => _totalEstimated - _platformFee;

  String get _currentUnit => _selectedCategory?.unit ?? 'kg';

  Future<void> _onSubmitOrder() async {
    if (_selectedCategory == null) {
      _showMessage('Vui lòng chọn loại rác!');
      return;
    }

    if (_quantity <= 0) {
      _showMessage('Vui lòng nhập số lượng ước tính lớn hơn 0!');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = CreateOrderRequestDto(
        methodId: _selectedMethodId,
        details: [
          CreateOrderDetailDto(
            categoryId: _selectedCategory!.categoryId,
            estimatedWeight: _quantity,
          ),
        ],
      );

      final response = await _orderRepo.createOrder(widget.token, request);

      setState(() => _isSubmitting = false);

      if (!mounted) return;

      // Hiển thị thông báo thành công
      _showSuccessDialog(response);
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showMessage(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showSuccessDialog(CreateOrderResponseDto response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDropOff = response.methodId == 1;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                isDropOff ? 'Tạo đơn mang đi thành công!' : 'Đã phát sóng thu gom!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2E22),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isDropOff
                    ? 'Đơn hàng #${response.orderId} đã tạo. Ước tính nhận được ${response.netEstimatedAmount.toInt()} GreenPoints.'
                    : 'Đơn hàng #${response.orderId} đã phát sóng radar. Hệ thống đang kết nối tài xế thu gom gần nhất.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF4A5D50), height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Đóng Dialog
                    Navigator.pop(context); // Quay về Home
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    isDropOff ? 'Xem bản đồ vựa gần tôi' : 'Hoàn tất',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A2E22), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tạo đơn bán rác',
          style: TextStyle(
            color: Color(0xFF1A2E22),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section 1: Phương thức
                          _buildSectionTitle('Phương thức'),
                          const SizedBox(height: 10),
                          _buildMethodSelection(),

                          const SizedBox(height: 24),

                          // Section 2: Loại rác
                          _buildSectionTitle('Loại rác'),
                          const SizedBox(height: 10),
                          _buildCategoryList(),

                          const SizedBox(height: 24),

                          // Section 3: Số lượng ước tính
                          _buildSectionTitle('Số lượng ước tính'),
                          const SizedBox(height: 10),
                          _buildQuantityCard(),

                          const SizedBox(height: 20),

                          // Summary Card
                          _buildSummaryCard(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Primary Button Bar
                  _buildBottomActionButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF7A8B80),
        letterSpacing: 0.2,
      ),
    );
  }

  // ── 1. Method Selection Cards ──────────────────────────────────────────────
  Widget _buildMethodSelection() {
    return Row(
      children: [
        // Card 1: Tự mang đi (Drop-off)
        Expanded(
          child: _buildMethodCard(
            methodId: 1,
            title: 'Tự mang đi',
            subtitle: 'Drop-off · Miễn phí',
            icon: Icons.inventory_2_outlined,
          ),
        ),
        const SizedBox(width: 14),
        // Card 2: Gọi thu gom (Pick-up)
        Expanded(
          child: _buildMethodCard(
            methodId: 2,
            title: 'Gọi thu gom',
            subtitle: 'Pick-up · phí 20%',
            icon: Icons.local_shipping_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildMethodCard({
    required int methodId,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedMethodId == methodId;

    return GestureDetector(
      onTap: () => setState(() => _selectedMethodId = methodId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : Colors.transparent,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.08 : 0.03),
              blurRadius: 12,
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
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryGreen.withOpacity(0.12) : const Color(0xFFF3F7F4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? AppColors.primaryGreen : const Color(0xFF7A8B80),
                    size: 20,
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 16),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF1A2E22) : const Color(0xFF4A5D50),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF7A8B80),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 2. Waste Category Selection List ───────────────────────────────────────
  Widget _buildCategoryList() {
    return Column(
      children: _categories.map((category) {
        final isSelected = _selectedCategory?.categoryId == category.categoryId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                  width: isSelected ? 2.0 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isSelected ? 0.06 : 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryGreen.withOpacity(0.12)
                          : const Color(0xFFEEF5F0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getIconData(category.iconName),
                      color: isSelected ? AppColors.primaryGreen : const Color(0xFF2A5C3F),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Name & Unit Price
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A2E22),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Tính theo ${category.unit} · ${category.unitPrice.toInt()} GP/${category.unit}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF7A8B80),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Checkmark
                  if (isSelected)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'description_outlined':
        return Icons.description_outlined;
      case 'devices_outlined':
        return Icons.devices_outlined;
      case 'local_drink_outlined':
        return Icons.local_drink_outlined;
      case 'takeout_dining_outlined':
        return Icons.takeout_dining_outlined;
      default:
        return Icons.eco_outlined;
    }
  }

  // ── 3. Quantity Card with Dynamic Unit ──────────────────────────────────────
  Widget _buildQuantityCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Decrement Button
          IconButton(
            onPressed: () {
              final val = (_quantity - 1).clamp(0, 999);
              _quantityController.text = val.toInt().toString();
              setState(() {});
            },
            icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF7A8B80), size: 26),
          ),
          // Input field
          Expanded(
            child: TextField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2E22),
              ),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          // Increment Button
          IconButton(
            onPressed: () {
              final val = _quantity + 1;
              _quantityController.text = val.toInt().toString();
              setState(() {});
            },
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryGreen, size: 26),
          ),
          const SizedBox(width: 8),
          // Dynamic Unit Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _currentUnit,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary Box ────────────────────────────────────────────────────────────
  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4EE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng tích điểm ước tính:',
                style: TextStyle(fontSize: 14, color: Color(0xFF4A5D50), fontWeight: FontWeight.w500),
              ),
              Text(
                '${_totalEstimated.toInt()} GP',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A2E22)),
              ),
            ],
          ),
          if (_selectedMethodId == 2) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Phí tiện lợi (20% Pick-up):',
                  style: TextStyle(fontSize: 13, color: Colors.redAccent, fontWeight: FontWeight.w500),
                ),
                Text(
                  '-${_platformFee.toInt()} GP',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: Color(0xFFC2E0CE)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Điểm nhận thực tế (ước tính):',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                ),
                Text(
                  '${_netEstimated.toInt()} GP',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Action Button Bar ──────────────────────────────────────────────────────
  Widget _buildBottomActionButton() {
    final buttonText = _selectedMethodId == 1 ? 'Tìm vựa gần tôi' : 'Đặt thu gom rác';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _onSubmitOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isSubmitting
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
              : Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}
