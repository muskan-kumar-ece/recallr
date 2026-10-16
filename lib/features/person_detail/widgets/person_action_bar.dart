import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../screens/capture/capture_modal.dart';
import '../models/person_profile_model.dart';

/// Floating or Docked Action Bar for Person Profile.
class PersonActionBar extends StatelessWidget {
  final PersonProfile profile;

  const PersonActionBar({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RecallrSpacing.md),
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: RecallrRadii.radiusLg,
        border: Border.all(color: RecallrColors.borderHighlight, width: 1.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: RecallrButton(
              label: 'Capture Encounter',
              variant: RecallrButtonVariant.aiGradient,
              leadingIcon: Icons.add_rounded,
              onPressed: () {
                RecallrBottomSheet.show(
                  context: context,
                  child: const CaptureModal(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}