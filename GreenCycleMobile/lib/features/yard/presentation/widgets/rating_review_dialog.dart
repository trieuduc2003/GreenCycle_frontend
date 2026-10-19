 import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';

class RatingReviewDialog extends StatefulWidget {
  final String token;
  final int yardId;
  final String partnerName;
  final VoidCallback? onReviewed;

  const RatingReviewDialog({
    super.key,
    required this.token,
    required this.yardId,
    required this.partnerName,
    this.onReviewed,
  });

  @override
  State<RatingReviewDialog> createState() => _RatingReviewDialogState();
}

class _RatingReviewDialogState extends State<RatingReviewDialog> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _starLabels = [
    'Rất tệ 😞',
    'Chưa hài lòng 😐',
    'Bình thường 🙂',
    'Hài lòng & Tốt 😊',
    'Tuyệt vời, rất uy tín! 🌟',
  ];

  Future<void> _submitReview() async {
    setState(() => _isSubmitting = true);
    try {
      final uri = Uri.parse('${ApiEndpoints.baseUrl}/yards/${widget.yardId}/review');
      final resp = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'rating': _rating,
          'comment': _commentController.text.trim(),
        }),
      );

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['success'] == true) {
        if (mounted) {
          Navigator.pop(context); // close review dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cảm ơn bạn đã gửi đánh giá! ⭐'),
              backgroundColor: AppColors.primaryGreen,
            ),
          );
          widget.onReviewed?.call();
        }
      } else {
        throw Exception(data['message'] ?? 'Không thể gửi đánh giá');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: const Icon(Icons.star_rounded, color: Color(0xFFFFA000), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đánh giá chất lượng',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1A2E22)),
                      ),
                      Text(
                        widget.partnerName,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF7A8B80)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Star selection
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                final isSelected = starIndex <= _rating;
                return GestureDetector(
                  onTap: () => setState(() => _rating = starIndex),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: isSelected ? const Color(0xFFFFB300) : const Color(0xFFCCCCCC),
                      size: 38,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),

            // Rating label
            Text(
              _starLabels[_rating - 1],
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFFE65100)),
            ),
            const SizedBox(height: 18),

            // Comment textfield
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Nhận xét của bạn (cân đúng, phục vụ tận tình, thái độ tốt...)',
                hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF9FBF9),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    child: const Text('Bỏ qua', style: TextStyle(color: Color(0xFF7A8B80))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Gửi đánh giá', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
