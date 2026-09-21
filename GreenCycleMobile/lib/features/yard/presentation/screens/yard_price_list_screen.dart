import 'package:flutter/material.dart';
import 'package:green_cycle_mobile/features/seller/data/repositories/order_repository.dart';
import 'package:green_cycle_mobile/features/seller/data/models/waste_category_dto.dart';
import '../../../../core/constants/app_colors.dart';

class YardPriceListScreen extends StatefulWidget {
  final String token;

  const YardPriceListScreen({super.key, required this.token});

  @override
  State<YardPriceListScreen> createState() => _YardPriceListScreenState();
}

class _YardPriceListScreenState extends State<YardPriceListScreen> {
  final _orderRepo = OrderRepository();
  bool _isLoading = true;
  List<WasteCategoryDto> _categories = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPrices();
  }

  Future<void> _fetchPrices() async {
    try {
      final data = await _orderRepo.getWasteCategories();
      if (mounted) {
        setState(() {
          _categories = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
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
        title: const Text('Bảng giá niêm yết', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text('Lỗi: $_error', style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => _isLoading = true);
                _fetchPrices();
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildInfoBanner(),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _categories.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              return _buildCategoryCard(cat);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: const [
          Icon(Icons.lock_outline, color: Colors.blueGrey, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Giá do GreenCycle khoá - cập nhật mỗi 24h\nKhông cho sửa để chống mặc cả (Price Freeze).',
              style: TextStyle(color: Colors.blueGrey, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(WasteCategoryDto cat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIconData(cat.iconName),
              size: 24,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2E22),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đơn vị: ${cat.unit}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_formatNumber(cat.unitPrice)} GP',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
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
}
