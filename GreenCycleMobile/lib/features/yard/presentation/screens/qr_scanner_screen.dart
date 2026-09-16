import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'weight_input_screen.dart';

/// Màn hình Camera full-screen để Chủ Vựa quét QR của Người Bán.
/// Sau khi quét thành công, điều hướng sang WeightInputScreen.
class QrScannerScreen extends StatefulWidget {
  final String token;

  const QrScannerScreen({super.key, required this.token});

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

    // Vẽ viền xanh cho khung quét
    final borderPaint = Paint()
      ..color = const Color(0xFF1B8E5A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(16)),
      borderPaint,
    );

    // Vẽ góc quét nổi bật
    const cornerLen = 24.0;
    const cornerWidth = 5.0;
    final cornerPaint = Paint()
      ..color = const Color(0xFF43A047)
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
