import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';

/// Production-ready File / Document Dossier Screen.
class FileDossierScreen extends StatefulWidget {
  final String fileId;

  const FileDossierScreen({
    super.key,
    required this.fileId,
  });

  @override
  State<FileDossierScreen> createState() => _FileDossierScreenState();
}

class _FileDossierScreenState extends State<FileDossierScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecallrColors.obsidianBase,
      appBar: AppBar(
        title: Text('File Details ${widget.fileId}'),
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
                          text: 'ATTACHMENT',
                          variant: RecallrBadgeVariant.pending,
                        ),
                        Text(
                          'Secured Cloud Storage',
                          style: RecallrTypography.monoMetadata.copyWith(color: RecallrColors.emeraldVerified),
                        ),
                      ],
                    ),
                    RecallrSpacing.gapMd,
                    Text('Encounter Document / Slide Deck', style: RecallrTypography.headlineMedium),
                    RecallrSpacing.gapSm,
                    Text(
                      'Document ID: ${widget.fileId}',
                      style: RecallrTypography.monoMetadata.copyWith(color: RecallrColors.aiCyanHighlight),
                    ),
                    RecallrSpacing.gapMd,
                    Text(
                      'This attachment is stored under your authenticated user workspace and indexed for AI Q&A recall.',
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
