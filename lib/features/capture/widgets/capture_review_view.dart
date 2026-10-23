import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../people/models/person_item.dart';
import '../models/capture_models.dart';

/// Structured review & confirmation view before committing capture to permanent network memory.
class CaptureReviewView extends StatefulWidget {
  final CaptureType type;
  final CaptureReviewData reviewData;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final ValueChanged<CaptureReviewData>? onUpdateData;

  const CaptureReviewView({
    super.key,
    required this.type,
    required this.reviewData,
    required this.onEdit,
    required this.onSave,
    this.onUpdateData,
  });

  @override
  State<CaptureReviewView> createState() => _CaptureReviewViewState();
}

class _CaptureReviewViewState extends State<CaptureReviewView> {
  late bool _isEditing;
  late TextEditingController _nameController;
  late TextEditingController _roleController;
  late TextEditingController _companyController;
  late TextEditingController _addressController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final nameConf = widget.reviewData.nameConfidence ?? (widget.reviewData.personName != null ? 0.9 : 0.0);
    final isBusinessCard = widget.type == CaptureType.businessCard;
    _isEditing = widget.reviewData.needsNameConfirmation ||
        (isBusinessCard && (nameConf < 0.7 || widget.reviewData.personName == null || widget.reviewData.personName!.trim().isEmpty));

    _nameController = TextEditingController(text: widget.reviewData.personName ?? '');
    _roleController = TextEditingController(text: widget.reviewData.personRole ?? '');
    _companyController = TextEditingController(text: widget.reviewData.companyName ?? '');
    _addressController = TextEditingController(text: widget.reviewData.address ?? widget.reviewData.location ?? '');
    _emailController = TextEditingController(text: widget.reviewData.contactDetails['email'] ?? '');
    _phoneController = TextEditingController(text: widget.reviewData.contactDetails['phone'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final correctedName = _nameController.text.trim();
    final effectiveName = correctedName.isNotEmpty ? correctedName : null;
    final updatedContacts = Map<String, String>.from(widget.reviewData.contactDetails);
    if (_emailController.text.trim().isNotEmpty) {
      updatedContacts['email'] = _emailController.text.trim();
    }
    if (_phoneController.text.trim().isNotEmpty) {
      updatedContacts['phone'] = _phoneController.text.trim();
    }

    final updated = widget.reviewData.copyWith(
      title: effectiveName ?? widget.reviewData.title,
      personName: effectiveName,
      personRole: _roleController.text.trim().isNotEmpty ? _roleController.text.trim() : null,
      companyName: _companyController.text.trim().isNotEmpty ? _companyController.text.trim() : null,
      location: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      contactDetails: updatedContacts,
      nameConfidence: 1.0,
      needsNameConfirmation: false,
    );

    widget.onUpdateData?.call(updated);
    widget.onSave();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return _buildEditForm();
    }
    return _buildPreviewCard();
  }

  Widget _buildEditForm() {
    final conf = widget.reviewData.nameConfidence ?? 0.0;
    final isLowConfidence = conf < 0.7 || _nameController.text.trim().isEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: isLowConfidence
                  ? RecallrColors.warmAmberGold.withAlpha(25)
                  : RecallrColors.aiCyanHighlight.withAlpha(20),
              borderRadius: RecallrRadii.radiusMd,
              border: Border.all(
                color: isLowConfidence
                    ? RecallrColors.warmAmberGold
                    : RecallrColors.aiCyanHighlight,
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isLowConfidence ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                  size: 16.0,
                  color: isLowConfidence ? RecallrColors.warmAmberGold : RecallrColors.aiCyanHighlight,
                ),
                const SizedBox(width: 6.0),
                Expanded(
                  child: Text(
                    isLowConfidence
                        ? 'Please verify contact name (confidence: ${(conf * 100).toInt()}%)'
                        : 'Review & Edit Contact Details',
                    style: RecallrTypography.labelSmall.copyWith(
                      color: isLowConfidence ? RecallrColors.warmAmberGold : RecallrColors.aiCyanHighlight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          RecallrSpacing.gapMd,

          // Name Field (PROMINENTLY HIGHLIGHTED)
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: RecallrColors.charcoalCard,
              borderRadius: RecallrRadii.radiusMd,
              border: Border.all(
                color: isLowConfidence ? RecallrColors.warmAmberGold : RecallrColors.aiElectricViolet,
                width: isLowConfidence ? 2.0 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PERSON NAME *',
                      style: RecallrTypography.labelSmall.copyWith(
                        color: isLowConfidence ? RecallrColors.warmAmberGold : RecallrColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (_nameController.text.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: RecallrColors.aiElectricViolet.withAlpha(30),
                          borderRadius: RecallrRadii.radiusSm,
                        ),
                        child: Text(
                          'Initials: ${PersonItem.computeInitials(_nameController.text)}',
                          style: RecallrTypography.monoMetadata.copyWith(
                            color: RecallrColors.aiCyanHighlight,
                            fontSize: 10.0,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6.0),
                TextField(
                  key: const Key('card_ocr_name_field'),
                  controller: _nameController,
                  style: RecallrTypography.titleMedium.copyWith(color: RecallrColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Alex Johnson',
                    prefixIcon: Icon(Icons.person_outline, color: RecallrColors.aiElectricViolet),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          RecallrSpacing.gapSm,

          // Role / Designation Field
          _buildInputField(
            controller: _roleController,
            label: 'DESIGNATION / ROLE',
            hintText: 'e.g. VP of Engineering',
            icon: Icons.badge_outlined,
          ),
          RecallrSpacing.gapSm,

          // Company Field
          _buildInputField(
            controller: _companyController,
            label: 'COMPANY / ORGANIZATION',
            hintText: 'e.g. Acme Technologies',
            icon: Icons.business_outlined,
          ),
          RecallrSpacing.gapSm,

          // Address Field (Strict Location Pin Icon)
          _buildInputField(
            controller: _addressController,
            label: 'ADDRESS / LOCATION',
            hintText: 'e.g. Plot No. 12, Industrial Area, Pune',
            icon: Icons.location_on_outlined,
          ),
          RecallrSpacing.gapSm,

          // Email & Phone Row
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _emailController,
                  label: 'EMAIL',
                  hintText: 'name@company.com',
                  icon: Icons.email_outlined,
                ),
              ),
              RecallrSpacing.gapSm,
              Expanded(
                child: _buildInputField(
                  controller: _phoneController,
                  label: 'PHONE',
                  hintText: '+91 98765 43210',
                  icon: Icons.phone_outlined,
                ),
              ),
            ],
          ),

          // Brands Badges (if present)
          if (widget.reviewData.brands.isNotEmpty) ...[
            RecallrSpacing.gapMd,
            Text(
              'BRANDS / PRODUCTS',
              style: RecallrTypography.labelSmall.copyWith(
                color: RecallrColors.textTertiary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6.0),
            Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: widget.reviewData.brands.map((brand) {
                return Chip(
                  avatar: const Icon(Icons.sell_outlined, size: 12.0, color: RecallrColors.aiCyanHighlight),
                  label: Text(brand, style: RecallrTypography.labelSmall.copyWith(color: RecallrColors.textPrimary)),
                  backgroundColor: RecallrColors.slateSurface,
                  side: const BorderSide(color: RecallrColors.borderSubtle),
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],

          RecallrSpacing.gapLg,

          // Save / Confirm Action
          RecallrButton(
            label: 'Confirm & Save to Memory',
            variant: RecallrButtonVariant.primary,
            leadingIcon: Icons.check_circle_outline_rounded,
            onPressed: _handleSave,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: RecallrRadii.radiusMd,
        border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: RecallrTypography.labelSmall.copyWith(
              color: RecallrColors.textTertiary,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          TextField(
            controller: controller,
            style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textPrimary),
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: Icon(icon, size: 16.0, color: RecallrColors.textTertiary),
              prefixIconConstraints: const BoxConstraints(minWidth: 26.0, minHeight: 20.0),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Structured Memory Preview Card
        Container(
          padding: RecallrSpacing.cardPadding,
          decoration: BoxDecoration(
            color: RecallrColors.charcoalCard,
            borderRadius: RecallrRadii.radiusLg,
            border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Method Badge + Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: RecallrSpacing.xs,
                    children: [
                      Icon(widget.type.icon, size: 14.0, color: widget.type.color),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: widget.type.color.withAlpha(25),
                          borderRadius: RecallrRadii.radiusSm,
                          border: Border.all(color: widget.type.color.withAlpha(80), width: 1.0),
                        ),
                        child: Text(
                          widget.type.label.toUpperCase(),
                          style: RecallrTypography.labelSmall.copyWith(
                            color: widget.type.color,
                            fontWeight: FontWeight.w700,
                            fontSize: 9.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.reviewData.date != null)
                    Text(
                      widget.reviewData.date!,
                      style: RecallrTypography.monoMetadata.copyWith(
                        color: RecallrColors.textTertiary,
                        fontSize: 10.5,
                      ),
                    ),
                ],
              ),
              RecallrSpacing.gapSm,

              // Memory Title
              Text(
                widget.reviewData.title,
                style: RecallrTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16.0,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              RecallrSpacing.gapXs,

              // Entity Context Tag
              if (widget.reviewData.personName != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.person_pin_circle_outlined,
                      size: 14.0,
                      color: RecallrColors.aiCyanHighlight,
                    ),
                    const SizedBox(width: 4.0),
                    Expanded(
                      child: Text(
                        '${widget.reviewData.personName!}${widget.reviewData.companyName != null ? ' · ${widget.reviewData.companyName!}' : ''}${widget.reviewData.eventName != null ? ' (${widget.reviewData.eventName!})' : ''}',
                        style: RecallrTypography.bodyMedium.copyWith(
                          color: RecallrColors.aiCyanHighlight,
                          fontWeight: FontWeight.w500,
                          fontSize: 12.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                RecallrSpacing.gapSm,
              ],

              // Address (Strictly with Location Map Pin)
              if (widget.reviewData.address != null && widget.reviewData.address!.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14.0,
                      color: RecallrColors.textTertiary,
                    ),
                    const SizedBox(width: 4.0),
                    Expanded(
                      child: Text(
                        widget.reviewData.address!,
                        style: RecallrTypography.bodyMedium.copyWith(
                          color: RecallrColors.textSecondary,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                  ],
                ),
                RecallrSpacing.gapSm,
              ],

              // Brands Chips (with Brand Tag Icon, NOT Location Map Pin)
              if (widget.reviewData.brands.isNotEmpty) ...[
                Wrap(
                  spacing: 4.0,
                  runSpacing: 4.0,
                  children: widget.reviewData.brands.map((b) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: RecallrColors.aiCyanHighlight.withAlpha(20),
                        borderRadius: RecallrRadii.radiusSm,
                        border: Border.all(color: RecallrColors.aiCyanHighlight.withAlpha(60), width: 1.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sell_outlined, size: 10.0, color: RecallrColors.aiCyanHighlight),
                          const SizedBox(width: 3.0),
                          Text(
                            b,
                            style: RecallrTypography.monoMetadata.copyWith(
                              color: RecallrColors.aiCyanHighlight,
                              fontSize: 10.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                RecallrSpacing.gapSm,
              ],

              // Summary
              Text(
                widget.reviewData.summary,
                style: RecallrTypography.bodyMedium.copyWith(
                  color: RecallrColors.textSecondary,
                  fontSize: 13.0,
                  height: 1.4,
                ),
              ),
              RecallrSpacing.gapMd,

              // Bullet Points / Key Takeaways
              if (widget.reviewData.bulletPoints.isNotEmpty) ...[
                Text(
                  'KEY TAKEAWAYS',
                  style: RecallrTypography.labelSmall.copyWith(
                    color: RecallrColors.textTertiary,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 6.0),
                ...widget.reviewData.bulletPoints.map(
                  (bullet) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.aiElectricViolet)),
                        Expanded(
                          child: Text(
                            bullet,
                            style: RecallrTypography.bodyMedium.copyWith(
                              color: RecallrColors.textPrimary,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                RecallrSpacing.gapSm,
              ],

              // Contact Details Matrix (For business cards)
              if (widget.reviewData.contactDetails.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: RecallrColors.slateSurface,
                    borderRadius: RecallrRadii.radiusSm,
                  ),
                  child: Column(
                    children: widget.reviewData.contactDetails.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: [
                            Text(
                              '${entry.key}: ',
                              style: RecallrTypography.monoMetadata.copyWith(
                                color: RecallrColors.textTertiary,
                                fontSize: 11.0,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: RecallrTypography.monoMetadata.copyWith(
                                  color: RecallrColors.textPrimary,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
        RecallrSpacing.gapLg,

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: RecallrButton(
                label: 'Edit',
                variant: RecallrButtonVariant.secondary,
                leadingIcon: Icons.edit_outlined,
                onPressed: () => setState(() => _isEditing = true),
              ),
            ),
            RecallrSpacing.gapSm,
            Expanded(
              child: RecallrButton(
                label: 'Save to Memory',
                variant: RecallrButtonVariant.primary,
                leadingIcon: Icons.check_circle_outline_rounded,
                onPressed: _handleSave,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
