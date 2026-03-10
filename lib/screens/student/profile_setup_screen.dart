import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../services/api_service.dart';
import '../../services/biometric_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _nameController = TextEditingController();
  final _rollNoController = TextEditingController();

  String? _selectedDepartment;
  String? _selectedPassingYear;

  bool _isLoading = false;

  final List<String> departments = ['CSE', 'DSAI', 'ECE'];
  final List<String> passingYears = [
    '2024',
    '2025',
    '2026',
    '2027',
    '2028',
    '2029'
  ];

  Future<void> _showConfirmationDialog() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartment == null || _selectedPassingYear == null) {
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
              _buildConfirmRow('Roll Number', _rollNoController.text.trim()),
              _buildConfirmRow('Department', _selectedDepartment!),
              _buildConfirmRow('Passing Year', _selectedPassingYear!),
              const SizedBox(height: 16),
              // Device Binding Information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.blue50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.blue200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.phonelink_lock,
                      color: AppColors.blue600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Device Binding',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.blue700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This device will be permanently bound to your account for security. You won\'t be able to use another device.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray700,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
            child: const Text('Confirm & Bind Device'),
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
            width: 110,
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
      await _apiService.createProfile(
        name: _nameController.text.trim(),
        rollNo: int.parse(_rollNoController.text.trim()),
        department: _selectedDepartment!,
        passingYear: int.parse(_selectedPassingYear!),
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
    final canCheck = await biometricService.checkBiometrics();

    if (canCheck) {
      final authenticated = await biometricService.authenticate();
      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication failed or cancelled.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, targetRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  Text(
                    'Complete Your Profile',
                    style: AppTextStyles.h2,
                  ),
                ],
              ),
            ),
            // Scrollable Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Student Information', style: AppTextStyles.h2),
                      const SizedBox(height: 8),
                      Text(
                        'All fields are required',
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
                          if (RegExp(r'\d').hasMatch(value!)) {
                            return 'Name cannot contain numbers';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Roll Number
                      TextFormField(
                        controller: _rollNoController,
                        keyboardType: TextInputType.number,
                        maxLength: 9,
                        decoration: InputDecoration(
                          labelText: 'Roll Number *',
                          hintText: 'e.g., 241020463',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppColors.white,
                          counterText: '',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(9),
                        ],
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Required';
                          if (value!.length != 9) {
                            return 'Roll number must be exactly 9 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Department
                      Text(
                        'Department *',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...departments.map((dept) => RadioListTile<String>(
                            title: Text(dept),
                            value: dept,
                            groupValue: _selectedDepartment,
                            onChanged: (value) {
                              setState(() => _selectedDepartment = value);
                            },
                            activeColor: AppColors.blue600,
                            tileColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          )),
                      const SizedBox(height: 24),

                      // Passing Year
                      Text(
                        'Passing Out Year *',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: passingYears.map((year) {
                          final isSelected = _selectedPassingYear == year;
                          return ChoiceChip(
                            label: Text(year),
                            selected: isSelected,
                            showCheckmark: false,
                            onSelected: (selected) {
                              setState(() => _selectedPassingYear = year);
                            },
                            selectedColor: AppColors.blue600,
                            labelStyle: TextStyle(
                              color:
                                  isSelected ? Colors.white : AppColors.gray700,
                              fontWeight: FontWeight.w500,
                            ),
                            backgroundColor: AppColors.white,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.blue600
                                  : AppColors.gray200,
                            ),
                          );
                        }).toList(),
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
    _rollNoController.dispose();
    super.dispose();
  }
}
