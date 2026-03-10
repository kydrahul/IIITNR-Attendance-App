import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';

class ScannerOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onSimulateScan;

  const ScannerOverlay({
    super.key,
    required this.onClose,
    required this.onSimulateScan,
  });

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay> {
  String step = 'camera'; // camera, verifying, result_success, result_error

  void _handleScan() {
    setState(() => step = 'verifying');
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() => step = 'result_success');
        widget.onSimulateScan();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Camera View (Simulated)
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image
                  Image.network(
                    "https://images.unsplash.com/photo-1550751827-4bd374c3f58b?q=80&w=2070&auto=format&fit=crop",
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.7),
                    colorBlendMode: BlendMode.darken,
                  ),

                  // Close Button
                  Positioned(
                    top: 48,
                    right: 24,
                    child: GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.xCircle,
                            color: Colors.white, size: 32),
                      ),
                    ),
                  ),

                  // Content
                  if (step == 'camera') _buildCameraView(),
                  if (step == 'verifying') _buildVerifyingView(),
                  if (step == 'result_success') _buildSuccessView(),
                  if (step == 'result_error') _buildErrorView(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 256,
          height: 256,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
          ),
          child: Stack(
            children: [
              // Animated Border (Static for now)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.blue500, width: 2),
                ),
              ),
              Center(
                child: Text(
                  "Align QR Code",
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        ElevatedButton.icon(
          onPressed: _handleScan,
          icon: const Icon(LucideIcons.camera, size: 20),
          label: const Text("Tap to Scan (Simulate)"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: const StadiumBorder(),
            textStyle: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: widget.onClose,
          child: Text("Cancel",
              style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildVerifyingView() {
    return Center(
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                  strokeWidth: 4, color: AppColors.blue600),
            ),
            const SizedBox(height: 24),
            Text("Verifying Location...",
                style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              "Please stay in the classroom for attendance verification.",
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.gray500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.green100,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.checkCircle2,
                  color: AppColors.green600, size: 40),
            ),
            const SizedBox(height: 16),
            Text("Attendance Marked!",
                style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              "You are all set for this session.",
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.gray500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Done"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.red100,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.mapPin,
                  color: AppColors.red600, size: 40),
            ),
            const SizedBox(height: 16),
            Text("Location Failed",
                style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              "You appear to be outside the class area. Please try scanning again.",
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.gray500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(() => step = 'camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gray100,
                  foregroundColor: AppColors.gray900,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Close & Retry"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
