import 'package:flutter/material.dart';
import '../../app/app_shell.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';

/// Production-ready Company / Organization Dossier Screen.
class CompanyDossierScreen extends StatefulWidget {
  final String companyId;

  const CompanyDossierScreen({
    super.key,
    required this.companyId,
  });

  @override
  State<CompanyDossierScreen> createState() => _CompanyDossierScreenState();
}

class _CompanyDossierScreenState extends State<CompanyDossierScreen> {
  @override
  Widget build(BuildContext context) {
    final companyName = widget.companyId.replaceAll('comp_', '').replaceAll('_', ' ').toUpperCase();

    return Scaffold(
      backgroundColor: RecallrColors.obsidianBase,
      appBar: AppBar(
        title: Text('Company Details ${widget.companyId}'),
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
                          text: 'ORGANIZATION',
                          variant: RecallrBadgeVariant.verified,
                        ),
                        Text(
                          'Active Network Cluster',
                          style: RecallrTypography.monoMetadata.copyWith(color: RecallrColors.aiCyanHighlight),
                        ),
                      ],
                    ),
                    RecallrSpacing.gapMd,
                    Text(companyName, style: RecallrTypography.headlineMedium),
                    RecallrSpacing.gapSm,
                    Text(
                      'Aggregated organizational intelligence from your relationship graph and encounters.',
                      style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary),
                    ),
                  ],
                ),
              ),
              RecallrSpacing.gapLg,
              Text('Key Contacts at $companyName', style: RecallrTypography.titleMedium),
              RecallrSpacing.gapSm,
              RecallrCard(
                onTap: () => RecallrAppShellScope.openTab(context, 1),
                child: Row(
                  children: [
                    const Icon(Icons.people_alt_outlined, size: 20, color: RecallrColors.aiElectricViolet),
                    RecallrSpacing.gapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Network Affiliates', style: RecallrTypography.titleMedium),
                          Text('View all relationship records linked to $companyName', style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: RecallrColors.textTertiary),
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
