import 'package:flutter/material.dart';
import 'package:green_cycle_mobile/features/auth/presentation/screens/login_screen.dart';
import 'yard_wallet_screen.dart';
import 'yard_order_history_screen.dart';
import 'yard_edit_profile_screen.dart';

class YardProfileScreen extends StatelessWidget {
  final String token;
  final String fullName;

  const YardProfileScreen({
    super.key,
    required this.token,
    required this.fullName,
  });

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản Chủ Vựa?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header Profile
            Row(
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.store, size: 36, color: Color(0xFF2E7D32)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A2E22)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Chưa cập nhật SĐT',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Menu Items
            _buildMenuItem(
              icon: Icons.account_balance_wallet,
              title: 'Ví Ký Quỹ',
              subtitle: 'Nạp tiền thanh toán cho khách',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => YardWalletScreen(token: token)));
              },
            ),
            _buildMenuItem(
              icon: Icons.history,
              title: 'Lịch sử Thu mua',
              subtitle: 'Xem lại các đơn đã gom',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => YardOrderHistoryScreen(token: token)));
              },
            ),
            _buildMenuItem(
              icon: Icons.storefront,
              title: 'Hồ sơ Vựa',
              subtitle: 'Cập nhật tên, địa chỉ, giờ hoạt động',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => YardEditProfileScreen(token: token)));
              },
            ),
            _buildMenuItem(
              icon: Icons.price_change,
              title: 'Bảng giá Thu mua',
              subtitle: 'Tính năng đang phát triển',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng đang phát triển')));
              },
            ),
            
            const SizedBox(height: 24),
            _buildMenuItem(
              icon: Icons.logout,
              title: 'Đăng xuất',
              titleColor: Colors.redAccent,
              iconColor: Colors.redAccent,
              hideArrow: true,
              onTap: () => _handleLogout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color titleColor = const Color(0xFF1A2E22),
    Color iconColor = const Color(0xFF2E7D32),
    bool hideArrow = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: titleColor)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)) : null,
        trailing: hideArrow ? null : const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
