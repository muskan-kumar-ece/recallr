import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';

/// Production-ready Event / Gathering Dossier Screen.
class EventDossierScreen extends StatefulWidget {
  final String eventId;

  const EventDossierScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<EventDossierScreen> createState() => _EventDossierScreenState();
}

class _EventDossierScreenState extends State<EventDossierScreen> {
  @override
  Widget build(BuildContext context) {
    final eventName = widget.eventId.replaceAll('evt_', '').replaceAll('_', ' ').toUpperCase();

    return Scaffold(
      backgroundColor: RecallrColors.obsidianBase,
      appBar: AppBar(
        title: Text('Event Details ${widget.eventId}'),
        leading: RecallrIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: RecallrSpacing.pagePadding,
            children: [
              RecallrCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const RecallrBadge(
                          text: 'EVENT ENCOUNTER',
                          variant: RecallrBadgeVariant.pending,
                        ),
                        Text(
                          'Relationship Touchpoint',
                          style: RecallrTypography.monoMetadata.copyWith(color: RecallrColors.warmAmberGold),
                        ),
                      ],
                    ),
                    RecallrSpacing.gapMd,
                    Text(eventName, style: RecallrTypography.headlineMedium),
                    RecallrSpacing.gapSm,
                    Text(
                      'Contextual gathering where multiple relationship encounters and visiting card captures occurred.',
                      style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
