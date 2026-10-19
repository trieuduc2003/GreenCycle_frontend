import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';

class CelebrationSuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final double? co2ReducedKg;
  final double? treesSaved;
  final num? greenPointsEarned;
  final double? amountEarned;
  final String? voucherCode;
  final String? partnerName;
  final VoidCallback? onRatePartner;
  final VoidCallback? onClose;

  const CelebrationSuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.co2ReducedKg,
    this.treesSaved,
    this.greenPointsEarned,
    this.amountEarned,
    this.voucherCode,
    this.partnerName,
    this.onRatePartner,
    this.onClose,
  });

  void _shareSocialImpact(BuildContext context) {
    final co2 = (co2ReducedKg ?? 2.5).toStringAsFixed(1);
    final trees = (treesSaved ?? 0.1).toStringAsFixed(2);
    final points = (greenPointsEarned ?? 50).round();

    final shareText = '🌱 Tôi vừa hoàn tất giao dịch tái chế và bảo vệ môi trường cùng GreenCycle!\n'
        '✨ Thành tích xanh: Giảm ~$co2 kg CO₂ (~$trees cây xanh được bảo vệ) và nhận +$points GreenPoints!\n'
        'Hãy cùng tôi phân loại rác, bảo vệ hành tinh xanh ngay hôm nay nhé! 🌍💚\n'
        '👉 Tải ứng dụng GreenCycle: https://greencycle.vn';

    Share.share(
      shareText,
      subject: 'Thành tích sống xanh cùng GreenCycle 🌿',
    );
  }

  @override
  Widget build(BuildContext context) {
    final co2 = (co2ReducedKg ?? 2.5).toStringAsFixed(1);
    final trees = (treesSaved ?? 0.1).toStringAsFixed(2);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon huy hiệu chúc mừng với Gradient
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B8E5A), Color(0xFF4CAF50), Color(0xFF81C784)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🎉', style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2E22),
              ),
            ),
            const SizedBox(height: 8),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF555555),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),

            // Điểm thưởng / Số tiền nhận được (nếu có)
            if (greenPointsEarned != null || amountEarned != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8F4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (amountEarned != null) ...[
                      const Icon(Icons.monetization_on_rounded, color: Color(0xFFE59835), size: 22),
                      const SizedBox(width: 6),
                      Text(
                        '+${amountEarned!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFE59835)),
                      ),
                    ],
                    if (amountEarned != null && greenPointsEarned != null)
                      const SizedBox(width: 16),
                    if (greenPointsEarned != null) ...[
                      const Icon(Icons.stars_rounded, color: Color(0xFF1B8E5A), size: 22),
                      const SizedBox(width: 6),
                      Text(
                        '+${greenPointsEarned!.toInt()} GP',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B8E5A)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Mã voucher (nếu là đổi quà)
            if (voucherCode != null && voucherCode!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FBE7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDCE775)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'MÃ QUÀ TẶNG CỦA BẠN:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF827717)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      voucherCode!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Color(0xFF33691E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Hộp tác động môi trường sống xanh (ESG Impact)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.eco_rounded, color: Color(0xFF2E7D32), size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tác động sống xanh của bạn:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Giảm ~$co2 kg CO₂ • Cứu ~$trees cây xanh 🌲',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1B3D2F)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Nút Chia sẻ Mạng Xã Hội (Social Share)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _shareSocialImpact(context),
                icon: const Icon(Icons.share_rounded, size: 20, color: Colors.white),
                label: const Text(
                  'Khoe thành tích sống xanh',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B8E5A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Nút Đánh giá đối tác / Vựa (nếu có callback)
            if (onRatePartner != null) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRatePartner,
                  icon: const Icon(Icons.star_rounded, color: Color(0xFFE59835), size: 20),
                  label: Text(
                    partnerName != null ? 'Đánh giá $partnerName' : 'Đánh giá dịch vụ ⭐',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A2E22)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFFD54F), width: 1.5),
                    backgroundColor: const Color(0xFFFFFDE7),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Nút Đóng
            TextButton(
              onPressed: onClose ?? () => Navigator.pop(context),
              child: const Text(
                'Hoàn tất',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Color(0xFF7A8B80)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
