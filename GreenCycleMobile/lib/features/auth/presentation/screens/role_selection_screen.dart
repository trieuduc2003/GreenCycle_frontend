import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../seller/presentation/screens/seller_home_screen.dart';
import '../../../yard/presentation/screens/yard_dashboard_screen.dart';
import 'login_screen.dart';

/// Màn hình chọn vai trò sau khi đăng nhập thành công
/// Dựa theo UI.pdf: 3 Card lớn, icon minh họa cho từng role
class RoleSelectionScreen extends StatelessWidget {
  final String token;
  final String fullName;

  const RoleSelectionScreen({
    super.key,
    required this.token,
    required this.fullName,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = fullName.split(' ').last;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.eco_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'GreenCycle',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2E22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              Text(
                'Chào, $firstName! 👋',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2E22),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bạn muốn vào với vai trò nào hôm nay?',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF7A8B80),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

              // Role Cards
              Expanded(
                child: Column(
                  children: [
                    _RoleCard(
                      icon: Icons.eco_rounded,
                      iconBg: const Color(0xFFE0F4EB),
                      iconColor: const Color(0xFF1B8E5A),
                      title: 'Người bán',
                      subtitle: 'Bán rác tái chế & nhận GreenPoints',
                      gradientColors: const [Color(0xFF1B8E5A), Color(0xFF0D6B41)],
                      onTap: () => _navigate(context, 'Seller'),
                    ),
                    const SizedBox(height: 16),
                    _RoleCard(
                      icon: Icons.local_shipping_rounded,
                      iconBg: const Color(0xFFE3F2FD),
                      iconColor: const Color(0xFF1565C0),
                      title: 'Người thu gom',
                      subtitle: 'Nhận đơn & vận chuyển phế liệu',
                      gradientColors: const [Color(0xFF1565C0), Color(0xFF0D47A1)],
                      onTap: () => _navigate(context, 'Collector'),
                    ),
                    const SizedBox(height: 16),
                    _RoleCard(
                      icon: Icons.storefront_rounded,
                      iconBg: const Color(0xFFFFF3E0),
                      iconColor: const Color(0xFFE65100),
                      title: 'Chủ vựa',
                      subtitle: 'Quản lý & xử lý phế liệu đầu vào',
                      gradientColors: const [Color(0xFFE65100), Color(0xFFBF360C)],
                      onTap: () => _navigate(context, 'YardOwner'),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              // Switch account
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18, color: Color(0xFF7A8B80)),
                  label: const Text(
                    'Đổi tài khoản',
                    style: TextStyle(color: Color(0xFF7A8B80), fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String role) {
    Widget destination;
    switch (role) {
      case 'Seller':
        destination = SellerHomeScreen(token: token, fullName: fullName);
        break;
      case 'Collector':
        destination = _ComingSoonScreen(
          role: 'Người thu gom',
          icon: Icons.local_shipping_rounded,
          description: 'Tính năng nhận đơn & định tuyến thu gom đang được phát triển.',
        );
        break;
      case 'YardOwner':
        destination = YardDashboardScreen(token: token, fullName: fullName);
        break;
      default:
        destination = SellerHomeScreen(token: token, fullName: fullName);
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2E22),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF7A8B80),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonScreen extends StatelessWidget {
  final String role;
  final IconData icon;
  final String description;

  const _ComingSoonScreen({
    required this.role,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A2E22)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          role,
          style: const TextStyle(color: Color(0xFF1A2E22), fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 64, color: AppColors.primaryGreen),
              ),
              const SizedBox(height: 24),
              const Text(
                'Sắp ra mắt! 🚀',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2E22),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF7A8B80), fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Quay lại', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
