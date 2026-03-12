import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../constants/faculty/faculty_colors.dart';
import '../../../../constants/faculty/faculty_text_styles.dart';
import '../../../../providers/live_session_provider.dart';
import '../../../../models/faculty/faculty_models.dart';

class SessionSetupForm extends StatelessWidget {
  const SessionSetupForm({super.key});

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
                        final v = int.tryParse(val) ?? 50;
                        provider.locationRadius = v.clamp(10, 150);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Selected Classroom
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Select Classroom *', style: FacultyTextStyles.label),
              if (provider.isLocationRequired)
                Row(
                  children: [
                    if (provider.isLoadingRooms)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    IconButton(
                      icon: const Icon(LucideIcons.refreshCw, size: 18),
                      onPressed: provider.fetchRooms,
                      tooltip: "Refresh rooms",
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.mapPin, size: 20, color: FacultyColors.primary),
                      onPressed: () async {
                        try {
                          final candidates = await provider.detectNearestRoom();
                          if (candidates.length > 1 && context.mounted) {
                            _showProximitySheet(context, candidates, provider);
                          } else if (candidates.isEmpty && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No classroom found within 30m. Please select manually.'),
                                backgroundColor: FacultyColors.black,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString().replaceAll('Exception: ', '')),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      tooltip: "Detect nearest classroom",
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(
                  color: provider.isLocationRequired && provider.selectedRoom == null
                      ? Colors.red.shade200
                      : FacultyColors.gray200),
              borderRadius: BorderRadius.circular(12),
              color: provider.isLocationRequired ? FacultyColors.white : FacultyColors.gray50,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: provider.selectedRoom,
                isExpanded: true,
                hint: Text(
                  provider.isLocationRequired ? 'Select Room (Required)' : 'Location Verification Disabled',
                  style: const TextStyle(color: FacultyColors.gray400),
                ),
                icon: const Icon(LucideIcons.chevronDown, size: 20),
                items: provider.rooms.map((room) {
                  return DropdownMenuItem(
                    value: room.name,
                    child: Text(room.name, style: FacultyTextStyles.bodyMedium),
                  );
                }).toList(),
                onChanged: (val) {
                  provider.selectedRoom = val;
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Location Requirements Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: provider.isLocationRequired 
                  ? FacultyColors.primary.withOpacity(0.05) 
                  : FacultyColors.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: provider.isLocationRequired 
                    ? FacultyColors.primary.withOpacity(0.1) 
                    : FacultyColors.gray200,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      provider.isLocationRequired ? LucideIcons.mapPin : LucideIcons.mapPinOff, 
                      size: 20, 
                      color: provider.isLocationRequired ? FacultyColors.primary : FacultyColors.gray400
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Require Location verification', 
                      style: FacultyTextStyles.bodyMedium.copyWith(
                        color: provider.isLocationRequired ? FacultyColors.black : FacultyColors.gray500
                      )
                    ),
                  ],
                ),
                Switch(
                  value: provider.isLocationRequired,
                  onChanged: (val) => provider.isLocationRequired = val,
                  activeColor: FacultyColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Class Type Selection
          Text('Class Type', style: FacultyTextStyles.label),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTypeOption(
                title: 'Theory',
                isActive: provider.classType == 'Theory',
                onTap: () => provider.classType = 'Theory',
              ),
              const SizedBox(width: 12),
              _buildTypeOption(
                title: 'Lab',
                isActive: provider.classType == 'Lab',
                onTap: () => provider.classType = 'Lab',
              ),
            ],
          ),
          const SizedBox(height: 24),

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
            onPressed: (provider.isLocationRequired && provider.selectedRoom == null)
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

  void _showProximitySheet(BuildContext context, List<RoomModel> rooms, LiveSessionProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Multiple Rooms Detected', style: FacultyTextStyles.h3),
              const SizedBox(height: 8),
              Text(
                'We found ${rooms.length} rooms nearby. Please select the correct one:',
                style: FacultyTextStyles.bodyMedium.copyWith(color: FacultyColors.gray500),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: rooms.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    return InkWell(
                      onTap: () {
                        provider.selectedRoom = room.name;
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: FacultyColors.gray200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.doorOpen, size: 20, color: FacultyColors.primary),
                            const SizedBox(width: 16),
                            Text(
                              room.name,
                              style: FacultyTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            const Icon(LucideIcons.chevronRight, size: 18, color: FacultyColors.gray400),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
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

  Widget _buildTypeOption({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? FacultyColors.primary.withOpacity(0.08) : FacultyColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? FacultyColors.primary : FacultyColors.gray200,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: FacultyTextStyles.bodyMedium.copyWith(
                color: isActive ? FacultyColors.primary : FacultyColors.gray600,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
