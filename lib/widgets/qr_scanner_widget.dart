import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_colors.dart';

class QrScannerWidget extends StatefulWidget {
  final Function(String) onDetect;
  final VoidCallback? onCancel;

  const QrScannerWidget({
    super.key,
    required this.onDetect,
    this.onCancel,
  });

  @override
  State<QrScannerWidget> createState() => _QrScannerWidgetState();
}

class _QrScannerWidgetState extends State<QrScannerWidget> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isDetected = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: controller,
          onDetect: (capture) {
            if (_isDetected) return;
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                setState(() => _isDetected = true);
                widget.onDetect(barcode.rawValue!);
                break;
              }
            }
          },
        ),
        // Overlay for the scanner
        CustomPaint(
          painter: ScannerOverlayPainter(),
          child: Container(),
        ),
        // Scanner frame
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        // Close button
        if (widget.onCancel != null)
          Positioned(
            top: 40,
            right: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: widget.onCancel,
              ),
            ),
          ),
        // Torch button
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ScannerActionButton(
                  icon: Icons.flash_on,
                  onPressed: () => controller.toggleTorch(),
                ),
                const SizedBox(width: 20),
                _ScannerActionButton(
                  icon: Icons.flip_camera_ios,
                  onPressed: () => controller.switchCamera(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScannerActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ScannerActionButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 250,
      height: 250,
    );

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(20))),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
