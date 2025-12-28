// ═══════════════════════════════════════════════════════════════════════════
// lib/packages/screens/barcode_scanner_page.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_provider.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
  );
  bool _hasScanned = false;
  bool _torchOn = false;

  void _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    if (capture.barcodes.isEmpty) return;

    final code = capture.barcodes.first.rawValue;
    if (code != null && code.isNotEmpty) {
      _hasScanned = true;
      HapticFeedback.mediumImpact();
      Navigator.pop(context, code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    const scanWidth = 300.0;
    const scanHeight = 180.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Scanner
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay
          CustomPaint(
            painter: _ScannerOverlayPainter(
              scanWidth: scanWidth,
              scanHeight: scanHeight,
              borderColor: theme.primary,
            ),
            child: const SizedBox.expand(),
          ),

          // Header
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 40),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.border),
                ),
                child: Text(
                  'Barcode scannen',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          // Close Button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.surface.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: theme.textPrimary, size: 28),
                  ),
                ),
              ),
            ),
          ),

          // Torch Toggle
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.surface.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _toggleTorch,
                    icon: Icon(
                      _torchOn ? Icons.flash_on : Icons.flash_off,
                      color: _torchOn ? theme.warning : theme.textPrimary,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Hint Text
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 60),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Barcode in den Rahmen halten',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// OVERLAY PAINTER
// ═══════════════════════════════════════════════════════════════════════════

class _ScannerOverlayPainter extends CustomPainter {
  final double scanWidth;
  final double scanHeight;
  final Color borderColor;
  final double borderRadius;
  final double cornerLength;

  _ScannerOverlayPainter({
    required this.scanWidth,
    required this.scanHeight,
    required this.borderColor,
    this.borderRadius = 12,
    this.cornerLength = 30,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final left = center.dx - scanWidth / 2;
    final top = center.dy - scanHeight / 2;
    final right = left + scanWidth;
    final bottom = top + scanHeight;

    // Dunkler Overlay außerhalb des Scan-Bereichs
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromLTRBR(left, top, right, bottom, Radius.circular(borderRadius)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlayPath, overlayPaint);

    // Rahmen um Scan-Bereich
    final borderPaint = Paint()
      ..color = borderColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final borderRect = RRect.fromLTRBR(left, top, right, bottom, Radius.circular(borderRadius));
    canvas.drawRRect(borderRect, borderPaint);

    // Ecken (dicker und auffälliger)
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Top-Left
    canvas.drawLine(Offset(left, top + cornerLength), Offset(left, top + borderRadius), cornerPaint);
    canvas.drawLine(Offset(left + borderRadius, top), Offset(left + cornerLength, top), cornerPaint);

    // Top-Right
    canvas.drawLine(Offset(right, top + cornerLength), Offset(right, top + borderRadius), cornerPaint);
    canvas.drawLine(Offset(right - borderRadius, top), Offset(right - cornerLength, top), cornerPaint);

    // Bottom-Left
    canvas.drawLine(Offset(left, bottom - cornerLength), Offset(left, bottom - borderRadius), cornerPaint);
    canvas.drawLine(Offset(left + borderRadius, bottom), Offset(left + cornerLength, bottom), cornerPaint);

    // Bottom-Right
    canvas.drawLine(Offset(right, bottom - cornerLength), Offset(right, bottom - borderRadius), cornerPaint);
    canvas.drawLine(Offset(right - borderRadius, bottom), Offset(right - cornerLength, bottom), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}