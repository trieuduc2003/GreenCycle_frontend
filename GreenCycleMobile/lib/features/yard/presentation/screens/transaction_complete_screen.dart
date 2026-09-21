import 'package:flutter/material.dart';

class TransactionCompleteScreen extends StatelessWidget {
  final String token;
  final int orderId;

  const TransactionCompleteScreen({
    super.key,
    required this.token,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Success Animation or Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B8E5A).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 80,
                    color: Color(0xFF1B8E5A),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Đã gửi xác nhận!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2E22),
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'Thông tin khối lượng cho Đơn #$orderId\nđã được gửi đến khách hàng.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF7A8B80),
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7F4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDDE4E0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_top_rounded, color: Color(0xFFC78330)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Vui lòng nhắc khách hàng mở ứng dụng GreenCycle để bấm XÁC NHẬN CHÉO.',
                        style: TextStyle(color: Color(0xFFC78330), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B8E5A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  minimumSize: const Size(double.infinity, 56),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context); // Trở về Dashboard
                },
                child: const Text(
                  'VỀ TRANG CHỦ',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
