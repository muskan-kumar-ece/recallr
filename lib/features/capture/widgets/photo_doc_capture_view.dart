import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../services/media_picker_service.dart';
import '../models/capture_models.dart';

/// Photo and Document upload view with Camera and Gallery selection triggers.
class PhotoDocCaptureView extends StatelessWidget {
  final CaptureType type;
  final TextEditingController titleController;
  final TextEditingController noteController;
  final TextEditingController contextController;
  final VoidCallback onProcess;
  final VoidCallback onCancel;
  final PickedMediaFile? pickedMediaFile;
  final VoidCallback? onPickCamera;
  final VoidCallback? onPickGallery;
  final VoidCallback? onPickDocument;

  const PhotoDocCaptureView({
    super.key,
    required this.type,
    required this.titleController,
    required this.noteController,
    required this.contextController,
    required this.onProcess,
    required this.onCancel,
    this.pickedMediaFile,
    this.onPickCamera,
    this.onPickGallery,
    this.onPickDocument,
  });

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 KB';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isPhoto = type == CaptureType.photo;
    final hasFile = pickedMediaFile != null;

    final fileName = hasFile
        ? pickedMediaFile!.name
        : (isPhoto ? 'No photo selected' : 'No document selected');
    final fileSizeText = hasFile ? ' (${_formatFileSize(pickedMediaFile!.size)})' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // File / Photo Preview Placeholder
        Container(
          height: 140.0,
          decoration: BoxDecoration(
            color: RecallrColors.charcoalCard,
            borderRadius: RecallrRadii.radiusMd,
            border: Border.all(color: type.color.withAlpha(90), width: 1.0),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPhoto ? Icons.photo_library_outlined : Icons.description_outlined,
                  size: 36.0,
                  color: type.color,
                ),
                RecallrSpacing.gapXs,
                Text(
                  isPhoto ? 'Whiteboard / Slide Photo Attached' : 'Document Attached (PDF / Deck)',
                  style: RecallrTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  hasFile ? '$fileName$fileSizeText' : fileName,
                  style: RecallrTypography.monoMetadata.copyWith(
                    color: RecallrColors.textTertiary,
                    fontSize: 11.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        RecallrSpacing.gapSm,

        // Camera / Gallery Action Bar (if photo type and callbacks provided)
        if (isPhoto && (onPickCamera != null || onPickGallery != null)) ...[
          Row(
            children: [
              if (onPickCamera != null)
                Expanded(
                  child: RecallrButton(
                    label: 'Camera',
                    variant: RecallrButtonVariant.secondary,
                    leadingIcon: Icons.camera_alt_outlined,
                    onPressed: onPickCamera!,
                  ),
                ),
              if (onPickCamera != null && onPickGallery != null) RecallrSpacing.gapSm,
              if (onPickGallery != null)
                Expanded(
                  child: RecallrButton(
                    label: 'Gallery',
                    variant: RecallrButtonVariant.secondary,
                    leadingIcon: Icons.photo_library_outlined,
                    onPressed: onPickGallery!,
                  ),
                ),
            ],
          ),
          RecallrSpacing.gapSm,
        ],

        // Document picker action (for document type)
        if (!isPhoto && onPickDocument != null) ...[
          RecallrButton(
            label: 'Select Document',
            variant: RecallrButtonVariant.secondary,
            leadingIcon: Icons.attach_file_rounded,
            onPressed: onPickDocument!,
          ),
          RecallrSpacing.gapSm,
        ],

        // Title Field
        RecallrTextField(
          controller: titleController,
          label: isPhoto ? 'Photo Title / Subject' : 'Document Title / Subject',
          hintText: isPhoto ? 'e.g. Architecture Whiteboard' : 'e.g. Technical Spec Sheet',
        ),
        RecallrSpacing.gapSm,

        // Note Body Field
        RecallrTextField(
          controller: noteController,
          label: 'Context & Takeaways',
          hintText: 'What does this document/photo represent?',
          maxLines: 2,
        ),
        RecallrSpacing.gapSm,

        // Context Association Field
        RecallrTextField(
          controller: contextController,
          label: 'Associated Person / Entity',
          hintText: 'e.g. Person Name · Company',
        ),
        RecallrSpacing.gapLg,

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: RecallrButton(
                label: 'Cancel',
                variant: RecallrButtonVariant.secondary,
                onPressed: onCancel,
              ),
            ),
            RecallrSpacing.gapSm,
            Expanded(
              child: RecallrButton(
                label: 'Process & Review',
                variant: RecallrButtonVariant.primary,
                leadingIcon: Icons.auto_stories_outlined,
                onPressed: onProcess,
              ),
            ),
          ],
        ),
      ],
    );
  }
}