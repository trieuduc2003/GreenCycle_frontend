import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';

/// Màn hình Trung tâm hỗ trợ — FAQ, hotline, email, form phản hồi.
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _feedbackController = TextEditingController();

  static const _faqs = [
    (
      q: 'GreenPoints là gì?',
      a: 'GreenPoints (GP) là điểm thưởng tích lũy từ hoạt động bán rác tái chế. 1 GP = 10 VND. Bạn có thể dùng GP để đổi voucher và quà tặng trong cửa hàng phần thưởng.'
    ),
    (
      q: 'Làm thế nào để bán rác?',
      a: 'Mở ứng dụng → Bấm "Bán rác" → Chọn loại rác và số lượng → Chọn phương thức (Tự mang đến vựa hoặc Gọi người thu gom đến nhà). Sau khi hoàn tất, GreenPoints sẽ được cộng vào ví của bạn.'
    ),
    (
      q: 'Đơn hàng của tôi ở đâu?',
      a: 'Vào Tab "Đơn hàng" → Xem danh sách lịch sử. Bấm vào từng đơn để xem chi tiết và mã QR giao dịch.'
    ),
    (
      q: 'Voucher có hạn sử dụng không?',
      a: 'Có. Mỗi voucher đều có ngày hết hạn được hiển thị rõ ràng. Voucher hết hạn sẽ chuyển sang tab "Hết hạn" và không thể sử dụng.'
    ),
    (
      q: 'Tôi không nhận được GreenPoints sau khi bán rác?',
      a: 'GreenPoints chỉ được cộng sau khi chủ vựa hoặc người thu gom xác nhận và cân rác thực tế. Quá trình này có thể mất vài phút. Nếu sau 24h vẫn chưa nhận được, hãy liên hệ hotline hỗ trợ.'
    ),
    (
      q: 'Làm sao để thêm địa chỉ nhà?',
      a: 'Vào Tab "Tôi" → "Địa chỉ đã lưu" → Bấm nút "+" để thêm địa chỉ mới. Bạn có thể nhập địa chỉ thủ công hoặc sử dụng GPS của thiết bị để xác định vị trí tự động.'
    ),
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _callHotline() async {
    final uri = Uri.parse('tel:18001234');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail() async {
    final uri = Uri.parse('mailto:support@greencycle.vn?subject=Hỗ%20trợ%20GreenCycle');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _submitFeedback() {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng nhập nội dung phản hồi.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
      return;
    }
    _feedbackController.clear();
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('Phản hồi đã được ghi nhận. Cảm ơn bạn!'),
          ],
        ),
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
          'Trung tâm hỗ trợ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2E22)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Banner ─────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B8E5A), Color(0xFF0D6B41)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chúng tôi luôn\nsẵn sàng hỗ trợ!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Thứ 2 – Thứ 7 | 8:00 – 22:00',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 32),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Liên hệ nhanh ──────────────────────────────────────────────────
          _buildSectionHeader('Liên hệ nhanh'),
          Row(
            children: [
              Expanded(
                child: _buildContactCard(
                  icon: Icons.phone_rounded,
                  color: const Color(0xFF1B8E5A),
                  bg: const Color(0xFFE0F4EB),
                  title: 'Hotline',
                  subtitle: '1800 1234',
                  onTap: _callHotline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContactCard(
                  icon: Icons.email_outlined,
                  color: const Color(0xFF1565C0),
                  bg: const Color(0xFFE3F2FD),
                  title: 'Email',
                  subtitle: 'support@greencycle.vn',
                  onTap: _sendEmail,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── FAQ ────────────────────────────────────────────────────────────
          _buildSectionHeader('Câu hỏi thường gặp'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: _faqs.map((faq) {
                return Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F4EB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.help_outline_rounded, color: AppColors.primaryGreen, size: 18),
                    ),
                    title: Text(
                      faq.q,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A2E22)),
                    ),
                    iconColor: AppColors.primaryGreen,
                    collapsedIconColor: const Color(0xFFB0BEC5),
                    children: [
                      Text(
                        faq.a,
                        style: const TextStyle(fontSize: 13.5, color: Color(0xFF4A5D50), height: 1.6),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // ── Gửi phản hồi ───────────────────────────────────────────────────
          _buildSectionHeader('Gửi phản hồi'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bạn có góp ý gì không?',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A2E22)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Phản hồi của bạn giúp chúng tôi cải thiện ứng dụng.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF7A8B80)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _feedbackController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Nhập nội dung phản hồi...',
                    hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF3F7F4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _submitFeedback,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Gửi phản hồi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),

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

  Widget _buildContactCard({
    required IconData icon,
    required Color color,
    required Color bg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A2E22))),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
