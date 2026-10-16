import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Fast encounter note capture form.
class QuickNoteCaptureView extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController noteController;
  final TextEditingController personController;
  final TextEditingController companyController;
  final TextEditingController eventController;
  final TextEditingController locationController;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const QuickNoteCaptureView({
    super.key,
    required this.titleController,
    required this.noteController,
    required this.personController,
    required this.companyController,
    required this.eventController,
    required this.locationController,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title Field
        RecallrTextField(
          controller: titleController,
          label: 'Title / Subject',
          hintText: 'e.g. Project kick-off meeting',
        ),
        RecallrSpacing.gapSm,

        // Note Body Field
        RecallrTextField(
          controller: noteController,
          label: 'Notes & Key Context',
          hintText: 'What happened? What was agreed or discussed?',
          maxLines: 3,
        ),
        RecallrSpacing.gapSm,

        // Context Association Grid
        Row(
          children: [
            Expanded(
              child: RecallrTextField(
                controller: personController,
                label: 'Person',
                hintText: 'e.g. Contact name',
              ),
            ),
            RecallrSpacing.gapSm,
            Expanded(
              child: RecallrTextField(
                controller: companyController,
                label: 'Company / Org',
                hintText: 'e.g. Acme Corp',
              ),
            ),
          ],
        ),
        RecallrSpacing.gapSm,
        Row(
          children: [
            Expanded(
              child: RecallrTextField(
                controller: eventController,
                label: 'Event / Meeting',
                hintText: 'e.g. Tech Conference',
              ),
            ),
            RecallrSpacing.gapSm,
            Expanded(
              child: RecallrTextField(
                controller: locationController,
                label: 'Location',
                hintText: 'e.g. Convention Center',
              ),
            ),
          ],
        ),
        RecallrSpacing.gapLg,

        // Action Row
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
                label: 'Save Memory',
                variant: RecallrButtonVariant.primary,
                leadingIcon: Icons.save_outlined,
                onPressed: onSave,
              ),
            ),
          ],
        ),
      ],
    );
  }
}