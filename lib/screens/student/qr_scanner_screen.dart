import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../providers/scanner_provider.dart';

class QRScannerScreen extends StatelessWidget {
  const QRScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScannerProvider(),
      child: const _QRScannerScreenContent(),
    );
  }
}

class _QRScannerScreenContent extends StatelessWidget {
  const _QRScannerScreenContent();

  @override
  Widget build(BuildContext context) {
    final scanWindowSize = MediaQuery.of(context).size.width * 0.75;
    final scanWindow = Rect.fromCenter(
      center: Offset(
        MediaQuery.of(context).size.width / 2,
        MediaQuery.of(context).size.height / 2,
      ),
      width: scanWindowSize,
      height: scanWindowSize,
    );

    final provider = context.watch<ScannerProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Mobile Scanner (Full Screen)
          MobileScanner(
            controller: provider.cameraController,
            onDetect: (capture) async {
              if (provider.isProcessing) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  try {
                    final message = await provider.handleQRCode(barcode.rawValue!, context);
                    if (message == "processing" || message == "debounced") return;

                    if (context.mounted) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Success'),
                            ],
                          ),
                          content: Text(message),
                          actions: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx); // Close dialog
                                Navigator.pop(context); // Close scanner
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Row(
                            children: [
                              Icon(Icons.error, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Failed'),
                            ],
                          ),
                          content: Text(e.toString()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                  break;
                }
              }
            },
          ),

          // 2. Dark Overlay with Cutout
          CustomPaint(
            painter: ScannerOverlayPainter(
              scanWindow: scanWindow,
              borderRadius: 24.0,
            ),
            child: Container(),
          ),

          // 3. Premium Border for Scan Area
          Center(
            child: Container(
              width: scanWindowSize,
              height: scanWindowSize,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.0),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  // Animated-like corners
                  Positioned(
                    top: 0, left: 0,
                    child: Container(width: 40, height: 40, decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFF6366F1), width: 4), left: BorderSide(color: Color(0xFF6366F1), width: 4)),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(24)),
                    )),
                  ),
                  Positioned(
                    top: 0, right: 0,
                    child: Container(width: 40, height: 40, decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFF6366F1), width: 4), right: BorderSide(color: Color(0xFF6366F1), width: 4)),
                      borderRadius: BorderRadius.only(topRight: Radius.circular(24)),
                    )),
                  ),
                  Positioned(
                    bottom: 0, left: 0,
                    child: Container(width: 40, height: 40, decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFF6366F1), width: 4), left: BorderSide(color: Color(0xFF6366F1), width: 4)),
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24)),
                    )),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(width: 40, height: 40, decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFF6366F1), width: 4), right: BorderSide(color: Color(0xFF6366F1), width: 4)),
                      borderRadius: BorderRadius.only(bottomRight: Radius.circular(24)),
                    )),
                  ),
                ],
              ),
            ),
          ),

          // 4. Top Controls (Flash and Close)
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: provider.toggleTorch,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Icon(
                      provider.isTorchOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                Text(
                  "Scan Attendance",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 5. Bottom Instructions
          Positioned(
            bottom: 80,
            left: 40,
            right: 40,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        "Align the QR code within the frame",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Hold steady for a few seconds",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 6. Processing Indicator Overlay
          if (provider.isProcessing)
            Container(
               color: Colors.black.withOpacity(0.8),
               child: const Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 5),
                     SizedBox(height: 24),
                     Text(
                       'Marking Attendance...',
                       style: TextStyle(
                         color: Colors.white,
                         fontSize: 20,
                         fontWeight: FontWeight.bold,
                         letterSpacing: 1.2,
                       ),
                     ),
                     SizedBox(height: 8),
                     Text(
                       'Please don\'t close the app',
                       style: TextStyle(
                         color: Colors.white70,
                         fontSize: 14,
                       ),
                     ),
                   ],
                 ),
               ),
            ),
        ],
      ),
    );
  }
}

// Custom Painter for the dark overlay with a hole
class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final double borderRadius;

  ScannerOverlayPainter({
    required this.scanWindow,
    this.borderRadius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          scanWindow,
          Radius.circular(borderRadius),
        ),
      );

    final overlayPath =
        Path.combine(PathOperation.difference, backgroundPath, cutoutPath);

    final paint = Paint()
      ..color = Colors.black.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
