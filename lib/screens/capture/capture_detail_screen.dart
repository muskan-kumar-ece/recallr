import 'package:flutter/material.dart';
import '../../core/di/recallr_dependencies.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../features/capture/models/capture_models.dart';

class CaptureDetailScreen extends StatefulWidget {
  final String captureId;

  const CaptureDetailScreen({super.key, required this.captureId});

  @override
  State<CaptureDetailScreen> createState() => _CaptureDetailScreenState();
}

class _CaptureDetailScreenState extends State<CaptureDetailScreen> {
  CaptureItem? _capture;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCapture();
  }

  Future<void> _loadCapture() async {
    try {
      final repo = RecallrDependencies.instance.captureRepository;
      final capture = await repo.getCapture(widget.captureId);
      if (mounted) {
        setState(() {
          _capture = capture;
          _isLoading = false;
          if (capture == null) {
            _error = 'Capture not found.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load capture.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDeleteCapture() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: RecallrColors.charcoalCard,
        shape: RoundedRectangleBorder(
          borderRadius: RecallrRadii.radiusLg,
          side: const BorderSide(color: RecallrColors.borderSubtle),
        ),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: RecallrColors.crimsonAlert, size: 22),
            const SizedBox(width: 8),
            Text('Delete Capture', style: RecallrTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently delete this capture record? This action cannot be undone.',
          style: TextStyle(color: RecallrColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: RecallrColors.textTertiary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RecallrColors.crimsonAlert.withAlpha(40),
              foregroundColor: RecallrColors.crimsonAlert,
              elevation: 0,
              side: const BorderSide(color: RecallrColors.crimsonAlert, width: 1),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repo = RecallrDependencies.instance.captureRepository;
        await repo.deleteCapture(widget.captureId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Capture deleted successfully'),
              backgroundColor: RecallrColors.slateSurface,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete capture: $e'),
              backgroundColor: RecallrColors.crimsonAlert,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: RecallrColors.obsidianBase,
        body: Center(child: CircularProgressIndicator(color: RecallrColors.aiCyanHighlight)),
      );
    }

    if (_error != null || _capture == null) {
      return Scaffold(
        backgroundColor: RecallrColors.obsidianBase,
        appBar: AppBar(
          backgroundColor: RecallrColors.obsidianBase,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            _error ?? 'Capture not found',
            style: RecallrTypography.bodyLarge.copyWith(color: RecallrColors.textSecondary),
          ),
        ),
      );
    }

    final item = _capture!;
    return Scaffold(
      backgroundColor: RecallrColors.obsidianBase,
      appBar: AppBar(
        backgroundColor: RecallrColors.obsidianBase,
        title: Text('Capture Detail', style: RecallrTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: RecallrColors.crimsonAlert),
            tooltip: 'Delete Capture',
            onPressed: _handleDeleteCapture,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: RecallrSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RecallrBadge(
                  text: item.type.label.toUpperCase(),
                  variant: RecallrBadgeVariant.neutral,
                ),
                RecallrSpacing.gapSm,
                Text(
                  item.timestamp,
                  style: RecallrTypography.monoMetadata.copyWith(color: RecallrColors.textTertiary),
                ),
              ],
            ),
            RecallrSpacing.gapMd,
            Text(item.title, style: RecallrTypography.headlineMedium.copyWith(fontWeight: FontWeight.w700)),
            RecallrSpacing.gapLg,
            if (item.description.isNotEmpty) ...[
              RecallrCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Summary', style: RecallrTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                    RecallrSpacing.gapSm,
                    Text(item.description, style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary)),
                  ],
                ),
              ),
              RecallrSpacing.gapMd,
            ],
            if (item.personName != null || item.companyName != null) ...[
              RecallrCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Identified Entity', style: RecallrTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                    RecallrSpacing.gapSm,
                    if (item.personName != null)
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 16.0, color: RecallrColors.aiCyanHighlight),
                          const SizedBox(width: 8.0),
                          Text(item.personName!, style: RecallrTypography.bodyMedium),
                        ],
                      ),
                    if (item.companyName != null) ...[
                      const SizedBox(height: 6.0),
                      Row(
                        children: [
                          const Icon(Icons.business_outlined, size: 16.0, color: RecallrColors.textTertiary),
                          const SizedBox(width: 8.0),
                          Text(item.companyName!, style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
