import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/faculty/faculty_colors.dart';
import '../../../constants/faculty/faculty_text_styles.dart';
import '../../../services/faculty/faculty_api_service.dart';

class FacultyProfileCompletionScreen extends StatefulWidget {
  const FacultyProfileCompletionScreen({super.key});

  @override
  State<FacultyProfileCompletionScreen> createState() => _FacultyProfileCompletionScreenState();
}

class _FacultyProfileCompletionScreenState extends State<FacultyProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _facultyIdController = TextEditingController();
  final _departmentController = TextEditingController();
  final _positionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _facultyIdController.dispose();
    _departmentController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FacultyApiService().updateProfile({
        'name': _nameController.text.trim(),
        'facultyId': _facultyIdController.text.trim(),
        'employeeId': _facultyIdController.text.trim(), // Send both for compatibility
        'department': _departmentController.text.trim(),
        'position': _positionController.text.trim(),
        'designation': _positionController.text.trim(), // Send both for compatibility
      });
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/faculty-home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FacultyColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Text(
                  "Complete Your Profile",
                  style: FacultyTextStyles.h1.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Please provide your details to continue.",
                  style: FacultyTextStyles.bodyLarge.copyWith(color: FacultyColors.gray500),
                ),
                const SizedBox(height: 40),
                _buildTextField(
                  controller: _nameController,
                  label: "Full Name",
                  icon: LucideIcons.user,
                  validator: (v) => v!.isEmpty ? "Enter your name" : null,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _facultyIdController,
                  label: "Faculty ID / Employee ID",
                  icon: LucideIcons.contact,
                  validator: (v) => v!.isEmpty ? "Enter your faculty ID" : null,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _departmentController,
                  label: "Department",
                  icon: LucideIcons.building,
                  validator: (v) => v!.isEmpty ? "Enter your department" : null,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _positionController,
                  label: "Position / Designation",
                  icon: LucideIcons.briefcase,
                  validator: (v) => v!.isEmpty ? "Enter your position" : null,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FacultyColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text("Save and Continue", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FacultyColors.gray500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: FacultyColors.gray400),
            filled: true,
            fillColor: FacultyColors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FacultyColors.gray200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FacultyColors.gray200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FacultyColors.primary, width: 2)),
          ),
        ),
      ],
    );
  }
}
