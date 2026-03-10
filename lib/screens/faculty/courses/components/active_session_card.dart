import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../constants/faculty/faculty_colors.dart';
import '../../../../providers/live_session_provider.dart';

class ActiveSessionCard extends StatelessWidget {
  const ActiveSessionCard({super.key});

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LiveSessionProvider>();
    final double progress =
        provider.sessionTimeRemaining / (provider.qrDuration * 60);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: FacultyColors.gray50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                    )
                  ],
                ),
                child: QrImageView(
                  data: provider.qrValue,
                  version: QrVersions.auto,
                  size: 240.0,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _formatTime(provider.sessionTimeRemaining),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: FacultyColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: FacultyColors.gray200,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(FacultyColors.primary),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 12),
              const Text('Session Time Remaining',
                  style: TextStyle(color: FacultyColors.gray500, fontSize: 14)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: FacultyColors.gray300),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('QR v${provider.qrVersion}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    provider.autoRefresh
                        ? 'Refreshing in ${provider.qrRefreshCountdown}s'
                        : 'Manual refresh',
                    style: const TextStyle(
                        color: FacultyColors.gray500, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Range: ${provider.locationRadius}m',
                  style: const TextStyle(
                      color: FacultyColors.gray500, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: provider.autoRefresh
                    ? null
                    : () async {
                        await context.read<LiveSessionProvider>().regenerateQR();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('QR Code regenerated'),
                              backgroundColor: FacultyColors.green600,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: FacultyColors.white,
                  disabledBackgroundColor: FacultyColors.gray100,
                  foregroundColor: FacultyColors.black,
                  disabledForegroundColor: FacultyColors.gray400,
                  elevation: 0,
                  side: BorderSide(
                    color: provider.autoRefresh
                        ? FacultyColors.gray200
                        : FacultyColors.gray300,
                  ),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                    provider.autoRefresh ? 'Auto-Refreshing' : 'Refresh QR',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await context.read<LiveSessionProvider>().endSession();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Session ended successfully'),
                        backgroundColor: FacultyColors.black,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: FacultyColors.red600,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('End Session',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: FacultyColors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
