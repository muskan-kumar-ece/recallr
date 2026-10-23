import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../services/ocr/ocr_entity_extractor.dart';
import '../models/person_profile_model.dart';

/// Modal bottom sheet for editing person identity details in-place.
class EditPersonModal extends StatefulWidget {
  final PersonProfile profile;
  final Future<void> Function(PersonProfile updatedProfile) onSave;

  const EditPersonModal({
    super.key,
    required this.profile,
    required this.onSave,
  });

  /// Displays the edit person modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required PersonProfile profile,
    required Future<void> Function(PersonProfile updatedProfile) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditPersonModal(
        profile: profile,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EditPersonModal> createState() => _EditPersonModalState();
}

class _EditPersonModalState extends State<EditPersonModal> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _roleController;
  late final TextEditingController _companyController;
  late final TextEditingController _locationController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _brandsController;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameController = TextEditingController(text: p.name);
    _roleController = TextEditingController(text: p.role);
    _companyController = TextEditingController(text: p.company);
    _locationController = TextEditingController(text: p.location);
    _emailController = TextEditingController(text: p.email ?? '');
    _phoneController = TextEditingController(text: p.phone ?? '');
    _brandsController = TextEditingController(text: p.brands.join(', '));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _brandsController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final trimmedName = _nameController.text.trim();
    if (OcrEntityExtractor.isLikelyInvalidName(trimmedName)) {
      setState(() {
        _errorMessage = 'Name appears to be an address, company, or invalid string.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final brandList = _brandsController.text
          .split(',')
          .map((b) => b.trim())
          .where((b) => b.isNotEmpty)
          .toList();

      final updated = widget.profile.copyWith(
        name: trimmedName,
        role: _roleController.text.trim(),
        company: _companyController.text.trim(),
        location: _locationController.text.trim(),
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        brands: brandList,
        updatedAt: DateTime.now(),
      );

      await widget.onSave(updated);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: RecallrColors.slateSurface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: RecallrRadii.radiusSm,
              side: const BorderSide(color: RecallrColors.borderSubtle, width: 1.0),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: RecallrColors.emeraldVerified,
                  size: 18.0,
                ),
                const SizedBox(width: RecallrSpacing.sm),
                Text(
                  'Profile updated successfully',
                  style: RecallrTypography.bodyMedium.copyWith(
                    color: RecallrColors.textPrimary,
                    fontSize: 13.0,
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to save changes. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: RecallrColors.slateSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
        border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
      ),
      padding: EdgeInsets.fromLTRB(
        RecallrSpacing.lg,
        RecallrSpacing.md,
        RecallrSpacing.lg,
        RecallrSpacing.lg + bottomInset,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36.0,
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: RecallrColors.borderHighlight,
                      borderRadius: RecallrRadii.radiusPill,
                    ),
                  ),
                ),
                const SizedBox(height: RecallrSpacing.md),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Contact Details',
                      style: RecallrTypography.headlineMedium.copyWith(
                        color: RecallrColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20.0),
                      color: RecallrColors.textSecondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: RecallrSpacing.md),

                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(RecallrSpacing.sm),
                    decoration: BoxDecoration(
                      color: RecallrColors.crimsonAlert.withAlpha(25),
                      borderRadius: RecallrRadii.radiusSm,
                      border: Border.all(
                        color: RecallrColors.crimsonAlert.withAlpha(50),
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: RecallrTypography.bodyMedium.copyWith(fontSize: 12.0).copyWith(
                        color: RecallrColors.crimsonAlert,
                      ),
                    ),
                  ),
                  const SizedBox(height: RecallrSpacing.sm),
                ],

                // Full Name field
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name *',
                  icon: Icons.person_outline_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Full name cannot be empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: RecallrSpacing.sm),

                // Role & Company Row
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _roleController,
                        label: 'Role / Title',
                        icon: Icons.badge_outlined,
                      ),
                    ),
                    const SizedBox(width: RecallrSpacing.sm),
                    Expanded(
                      child: _buildTextField(
                        controller: _companyController,
                        label: 'Company',
                        icon: Icons.business_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: RecallrSpacing.sm),

                // Location field
                _buildTextField(
                  controller: _locationController,
                  label: 'Location / City',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: RecallrSpacing.sm),

                // Email & Phone Row
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(width: RecallrSpacing.sm),
                    Expanded(
                      child: _buildTextField(
                        controller: _phoneController,
                        label: 'Phone',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: RecallrSpacing.sm),

                // Brands / Tags field
                _buildTextField(
                  controller: _brandsController,
                  label: 'Brands / Products (comma-separated)',
                  icon: Icons.label_outline_rounded,
                  hint: 'e.g. WAGO, HAVELLS',
                ),
                const SizedBox(height: RecallrSpacing.lg),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 44.0,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RecallrColors.aiElectricViolet,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: RecallrRadii.radiusSm,
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18.0,
                            height: 18.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Save Changes',
                            style: RecallrTypography.titleMedium.copyWith(fontSize: 14.0, fontWeight: FontWeight.w600).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: RecallrTypography.bodyMedium.copyWith(fontSize: 12.0).copyWith(color: RecallrColors.textSecondary),
        hintStyle: RecallrTypography.bodyMedium.copyWith(fontSize: 12.0).copyWith(color: RecallrColors.textTertiary),
        prefixIcon: Icon(icon, size: 18.0, color: RecallrColors.textTertiary),
        filled: true,
        fillColor: RecallrColors.charcoalCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        border: OutlineInputBorder(
          borderRadius: RecallrRadii.radiusSm,
          borderSide: const BorderSide(color: RecallrColors.borderSubtle, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: RecallrRadii.radiusSm,
          borderSide: const BorderSide(color: RecallrColors.borderSubtle, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: RecallrRadii.radiusSm,
          borderSide: const BorderSide(color: RecallrColors.aiElectricViolet, width: 1.0),
        ),
      ),
    );
  }
}
