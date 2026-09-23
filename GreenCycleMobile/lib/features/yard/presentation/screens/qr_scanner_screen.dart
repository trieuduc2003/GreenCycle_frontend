import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'weight_input_screen.dart';
import '../../../collector/presentation/screens/collector_weight_input_screen.dart';

/// Màn hình Camera full-screen để Chủ Vựa / Người Thu Gom quét QR của Người Bán.
/// Sau khi quét thành công, điều hướng sang màn hình nhập khối lượng.
class QrScannerScreen extends StatefulWidget {
  final String token;
  final bool isCollector;

  const QrScannerScreen({super.key, required this.token, this.isCollector = false});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  late final MobileScannerController _controller;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final rawValue = barcode!.rawValue!;
    // Kỳ vọng QR chứa orderId dạng: "GREENCYCLE_ORDER_{orderId}"
    if (!rawValue.startsWith('GREENCYCLE_ORDER_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã QR không hợp lệ. Vui lòng quét mã của khách hàng GreenCycle.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _hasScanned = true);
    _controller.stop();

    final orderId = int.tryParse(rawValue.replaceFirst('GREENCYCLE_ORDER_', ''));
    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mã đơn hàng không hợp lệ!'), backgroundColor: Colors.red),
      );
      setState(() => _hasScanned = false);
      _controller.start();
      return;
    }

    if (widget.isCollector) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CollectorWeightInputScreen(
            token: widget.token,
            orderId: orderId,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WeightInputScreen(
            token: widget.token,
            orderId: orderId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera full-screen
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Overlay với khung quét
          _buildOverlay(),
          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Quét mã QR khách hàng',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _controller.toggleTorch(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Instruction text at bottom
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC78330), // Orange badge
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Sẵn sàng',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Đưa mã QR của khách vào khung hình',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                // Nút Nhập tay
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFC78330),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.keyboard_alt_outlined, size: 20),
                  label: const Text(
                    'Nhập mã thủ công',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _showManualEntryDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return CustomPaint(
      painter: _ScannerOverlayPainter(),
      child: const SizedBox.expand(),
    );
  }

  Future<void> _showManualEntryDialog() async {
    _controller.stop();
    final textController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nhập mã đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Ví dụ: 123',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFC78330), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC78330),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final id = int.tryParse(textController.text.trim());
              Navigator.pop(context); // Đóng dialog
              if (id != null && id > 0) {
                // Điều hướng sang WeightInputScreen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WeightInputScreen(
                      token: widget.token,
                      orderId: id,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mã đơn hàng không hợp lệ!'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    // Restart camera after dialog is closed if didn't navigate
    if (mounted && ModalRoute.of(context)?.isCurrent == true) {
      _controller.start();
    }
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;
    final scanSize = size.width * 0.65;
    final left = (size.width - scanSize) / 2;
    final top = (size.height - scanSize) / 2;
    final scanRect = Rect.fromLTWH(left, top, scanSize, scanSize);
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Vẽ nền tối bên ngoài khung quét
    final path = Path()
      ..addRect(fullRect)
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);

    // Vẽ viền cam cho khung quét
    final borderPaint = Paint()
      ..color = const Color(0xFFC78330).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(16)),
      borderPaint,
    );

    // Vẽ góc quét nổi bật
    const cornerLen = 30.0;
    const cornerWidth = 6.0;
    final cornerPaint = Paint()
      ..color = const Color(0xFFE59835) // Sáng hơn xíu
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerWidth
      ..strokeCap = StrokeCap.round;

    final corners = [
      // Top-left
      [Offset(left, top + cornerLen), Offset(left, top), Offset(left + cornerLen, top)],
      // Top-right
      [Offset(left + scanSize - cornerLen, top), Offset(left + scanSize, top), Offset(left + scanSize, top + cornerLen)],
      // Bottom-left
      [Offset(left, top + scanSize - cornerLen), Offset(left, top + scanSize), Offset(left + cornerLen, top + scanSize)],
      // Bottom-right
      [Offset(left + scanSize - cornerLen, top + scanSize), Offset(left + scanSize, top + scanSize), Offset(left + scanSize, top + scanSize - cornerLen)],
    ];

    for (final corner in corners) {
      final path2 = Path()
        ..moveTo(corner[0].dx, corner[0].dy)
        ..lineTo(corner[1].dx, corner[1].dy)
        ..lineTo(corner[2].dx, corner[2].dy);
      canvas.drawPath(path2, cornerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
