import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Màn hình Cài đặt ứng dụng.
class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  // Trạng thái toggle — trong thực tế sẽ lưu qua SharedPreferences
  bool _pushNotifications = true;
  bool _orderNotifications = true;
  bool _promotionNotifications = false;
  bool _hideBalanceDefault = false;

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
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
          'Cài đặt ứng dụng',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2E22)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Thông báo ──────────────────────────────────────────────────────
          _buildSectionHeader('Thông báo'),
          _buildCard([
            _buildSwitch(
              icon: Icons.notifications_active_outlined,
              iconColor: const Color(0xFF1B8E5A),
              bgColor: const Color(0xFFE0F4EB),
              title: 'Thông báo đẩy',
              subtitle: 'Nhận thông báo về đơn hàng và ví',
              value: _pushNotifications,
              onChanged: (v) => setState(() => _pushNotifications = v),
            ),
            const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFEFF2F0)),
            _buildSwitch(
              icon: Icons.receipt_long_outlined,
              iconColor: const Color(0xFF1565C0),
              bgColor: const Color(0xFFE3F2FD),
              title: 'Thông báo đơn hàng',
              subtitle: 'Cập nhật trạng thái đơn hàng của bạn',
              value: _orderNotifications,
              onChanged: (v) => setState(() => _orderNotifications = v),
            ),
            const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFEFF2F0)),
            _buildSwitch(
              icon: Icons.local_offer_outlined,
              iconColor: const Color(0xFFD4770A),
              bgColor: const Color(0xFFFFF3E0),
              title: 'Khuyến mãi',
              subtitle: 'Tin tức và ưu đãi từ GreenCycle',
              value: _promotionNotifications,
              onChanged: (v) => setState(() => _promotionNotifications = v),
            ),
          ]),

          const SizedBox(height: 20),

          // ── Hiển thị ──────────────────────────────────────────────────────
          _buildSectionHeader('Hiển thị'),
          _buildCard([
            _buildSwitch(
              icon: Icons.visibility_off_outlined,
              iconColor: const Color(0xFF7A8B80),
              bgColor: const Color(0xFFF0F4F1),
              title: 'Ẩn số dư mặc định',
              subtitle: 'Số dư ví sẽ bị ẩn khi mở ứng dụng',
              value: _hideBalanceDefault,
              onChanged: (v) => setState(() => _hideBalanceDefault = v),
            ),
          ]),

          const SizedBox(height: 20),

          // ── Ngôn ngữ ──────────────────────────────────────────────────────
          _buildSectionHeader('Ngôn ngữ & Khu vực'),
          _buildCard([
            _buildNavTile(
              icon: Icons.language_outlined,
              iconColor: const Color(0xFF1565C0),
              bgColor: const Color(0xFFE3F2FD),
              title: 'Ngôn ngữ',
              trailing: 'Tiếng Việt',
              onTap: () => _showSnack('Chức năng đang được phát triển 🚀'),
            ),
          ]),

          const SizedBox(height: 20),

          // ── Bộ nhớ & Cache ────────────────────────────────────────────────
          _buildSectionHeader('Bộ nhớ'),
          _buildCard([
            _buildNavTile(
              icon: Icons.delete_sweep_outlined,
              iconColor: const Color(0xFFE53935),
              bgColor: const Color(0xFFFFEBEE),
              title: 'Xóa bộ nhớ cache',
              trailing: '',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('Xóa cache?'),
                    content: const Text('Hành động này sẽ xóa dữ liệu tạm trên thiết bị của bạn.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showSnack('Đã xóa cache thành công!');
                        },
                        child: const Text('Xóa', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ]),

          const SizedBox(height: 20),

          // ── Phiên bản ─────────────────────────────────────────────────────
          _buildSectionHeader('Thông tin ứng dụng'),
          _buildCard([
            _buildNavTile(
              icon: Icons.info_outline_rounded,
              iconColor: AppColors.primaryGreen,
              bgColor: const Color(0xFFE0F4EB),
              title: 'Phiên bản',
              trailing: '1.0.0',
              onTap: null,
            ),
          ]),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF7A8B80),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitch({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A2E22))),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF7A8B80))),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryGreen,
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String trailing,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A2E22))),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing.isNotEmpty)
            Text(trailing, style: const TextStyle(fontSize: 13, color: Color(0xFF7A8B80))),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFFB0BEC5)),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}
