import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/colors.dart';
import '../../constants/faculty_list.dart';
import '../../constants/text_styles.dart';
import '../../services/api_service.dart';
import '../../services/biometric_service.dart';
import '../../utils/date_utils.dart' as du;
import '../../utils/responsive.dart';

class InternProfileSetupScreen extends StatefulWidget {
  const InternProfileSetupScreen({super.key});

  @override
  State<InternProfileSetupScreen> createState() =>
      _InternProfileSetupScreenState();
}

class _InternProfileSetupScreenState extends State<InternProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _nameController = TextEditingController();
  final _collegeController = TextEditingController();

  String? _selectedFaculty;
  DateTime? _internshipStart;
  DateTime? _internshipEnd;

  bool _isLoading = false;

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_internshipStart ?? now)
          : (_internshipEnd ?? now.add(const Duration(days: 30))),
      firstDate: DateTime(2025),
      lastDate: DateTime(2027, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.blue600,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _internshipStart = picked;
          // Auto-set end if not set or if end is before new start
          if (_internshipEnd == null || _internshipEnd!.isBefore(picked)) {
            _internshipEnd = picked.add(const Duration(days: 30));
          }
        } else {
          _internshipEnd = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) => du.formatDateDMY(date);

  Future<void> _showConfirmationDialog() async {
    if (!_formKey.currentState!.validate()) return;
    if (_internshipStart == null || _internshipEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Your Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '⚠️ You won\'t be able to change this later',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              _buildConfirmRow('Full Name', _nameController.text.trim()),
              _buildConfirmRow('College', _collegeController.text.trim()),
              if (_selectedFaculty != null)
                _buildConfirmRow(
                    'Faculty', _selectedFaculty!.split(' — ').first),
              _buildConfirmRow('Start Date', _formatDate(_internshipStart)),
              _buildConfirmRow('End Date', _formatDate(_internshipEnd)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Edit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm & Continue'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _submitProfile();
    }
  }

  Widget _buildConfirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.gray600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitProfile() async {
    setState(() => _isLoading = true);

    try {
      await _apiService.createInternProfile(
        name: _nameController.text.trim(),
        college: _collegeController.text.trim(),
        assignedFaculty: _selectedFaculty,
        internshipStart: _internshipStart!.toIso8601String(),
        internshipEnd: _internshipEnd!.toIso8601String(),
      );

      if (mounted) {
        await _handleBiometricAndRoute('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBiometricAndRoute(String targetRoute) async {
    final biometricService = BiometricService();
    final hasEnrolledBiometrics = await biometricService.checkBiometrics();
    if (hasEnrolledBiometrics) {
      await biometricService.authenticate();
    }
    if (mounted) {
      Navigator.pushReplacementNamed(context, targetRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.white,
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wb_sunny,
                            size: 16, color: Colors.amber.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Summer Intern',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Complete Your Profile', style: AppTextStyles.h2),
                ],
              ),
            ),
            // Scrollable Form
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Intern Information', style: AppTextStyles.h2),
                      const SizedBox(height: 8),
                      Text(
                        'Fields marked with * are required',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.gray500),
                      ),
                      const SizedBox(height: 24),

                      // Full Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name *',
                          hintText: 'Enter your full name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppColors.white,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z ]')),
                        ],
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // College / Institution
                      TextFormField(
                        controller: _collegeController,
                        decoration: InputDecoration(
                          labelText: 'College / Institution *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppColors.white,
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Assigned Faculty (optional)
                      Text(
                        'Assigned Faculty (optional)',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Leave blank if unsure — it can be updated later',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.gray500),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedFaculty,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Select faculty (optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppColors.white,
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('— None —',
                                style: TextStyle(color: AppColors.gray500)),
                          ),
                          ...kFacultyList.map((f) => DropdownMenuItem<String>(
                                value: f,
                                child: Text(
                                  f.split(' — ').first,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedFaculty = value);
                        },
                      ),
                      const SizedBox(height: 24),

                      // Internship Duration
                      Text(
                        'Internship Duration *',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Start Date
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickDate(isStart: true),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.gray200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Start Date',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.gray500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today,
                                            size: 16, color: AppColors.blue600),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatDate(_internshipStart),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: _internshipStart != null
                                                ? AppColors.gray700
                                                : AppColors.gray400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.arrow_forward,
                                size: 16, color: AppColors.gray400),
                          ),
                          // End Date
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickDate(isStart: false),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.gray200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'End Date',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.gray500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today,
                                            size: 16, color: AppColors.blue600),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatDate(_internshipEnd),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: _internshipEnd != null
                                                ? AppColors.gray700
                                                : AppColors.gray400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              _isLoading ? null : _showConfirmationDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blue600,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Continue',
                                  style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _collegeController.dispose();
    super.dispose();
  }
}
