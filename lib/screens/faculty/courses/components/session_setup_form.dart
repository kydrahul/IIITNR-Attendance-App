import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../constants/faculty/faculty_colors.dart';
import '../../../../constants/faculty/faculty_text_styles.dart';
import '../../../../providers/live_session_provider.dart';

class SessionSetupForm extends StatelessWidget {
  const SessionSetupForm({super.key});

  final List<String> _rooms = const [
    'LT-1', 'LT-2', 'LT-3', 'CR-1', 'CR-2', 'Lab 1', 'Lab 2'
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LiveSessionProvider>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: FacultyColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FacultyColors.gray100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QR Code Attendance',
            style: FacultyTextStyles.h3.copyWith(color: FacultyColors.black),
          ),
          const SizedBox(height: 24),

          // Duration & Radius
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('QR Validity (minutes)', style: FacultyTextStyles.label),
                    const SizedBox(height: 8),
                    _buildInputField(
                      initialValue: provider.qrDuration.toString(),
                      onChanged: (val) {
                        final v = int.tryParse(val) ?? 1;
                        provider.qrDuration = v > 0 ? v : 1;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Location Radius (meters)', style: FacultyTextStyles.label),
                    const SizedBox(height: 8),
                    _buildInputField(
                      initialValue: provider.locationRadius.toString(),
                      onChanged: (val) {
                        final v = int.tryParse(val) ?? 5;
                        provider.locationRadius = v > 4 ? v : 5;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Selected Classroom
          Text('Select Classroom *', style: FacultyTextStyles.label),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(
                  color: provider.selectedRoom == null
                      ? Colors.red.shade200
                      : FacultyColors.gray200),
              borderRadius: BorderRadius.circular(12),
              color: FacultyColors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: provider.selectedRoom,
                isExpanded: true,
                hint: const Text('Select Room (Required)',
                    style: TextStyle(color: FacultyColors.gray400)),
                icon: const Icon(LucideIcons.chevronDown, size: 20),
                items: _rooms.map((room) {
                  return DropdownMenuItem(
                    value: room,
                    child: Text(room, style: FacultyTextStyles.bodyMedium),
                  );
                }).toList(),
                onChanged: (val) {
                  provider.selectedRoom = val;
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Auto Refresh settings
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FacultyColors.gray50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Auto-refresh QR', style: FacultyTextStyles.bodyMedium),
                    Switch(
                      value: provider.autoRefresh,
                      onChanged: (val) {
                        provider.autoRefresh = val;
                      },
                      activeColor: FacultyColors.primary,
                    ),
                  ],
                ),
                if (provider.autoRefresh) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Interval (sec):',
                          style: TextStyle(
                              color: FacultyColors.gray500, fontSize: 14)),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 100,
                        child: _buildInputField(
                          initialValue: provider.autoRefreshInterval.toString(),
                          onChanged: (val) {
                            final v = int.tryParse(val) ?? 5;
                            provider.autoRefreshInterval = v > 4 ? v : 5;
                          },
                        ),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Generate Button
          ElevatedButton.icon(
            onPressed: provider.selectedRoom == null
                ? null
                : () async {
                    try {
                      await context.read<LiveSessionProvider>().generateQR();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to start session: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
            icon: const Icon(LucideIcons.qrCode, color: FacultyColors.white),
            label: const Text('Generate QR Code',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: FacultyColors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: FacultyColors.primary,
              disabledBackgroundColor: FacultyColors.gray300,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
      {required String initialValue, required Function(String) onChanged}) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      style: FacultyTextStyles.bodyMedium,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: FacultyColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FacultyColors.gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FacultyColors.gray200),
        ),
      ),
    );
  }
}
