import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';

/// Not-found (404) route fallback screen.
class NotFoundScreen extends StatelessWidget {
  final String? path;

  const NotFoundScreen({super.key, this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecallrColors.obsidianBase,
      appBar: AppBar(title: const Text('Not Found')),
      body: Center(
        child: Padding(
          padding: RecallrSpacing.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const RecallrEmptyState(
                icon: Icons.search_off_rounded,
                title: 'Page Not Found',
                description: 'The requested route does not exist or has been moved.',
              ),
              if (path != null) ...[
                RecallrSpacing.gapSm,
                Text(
                  path!,
                  style: RecallrTypography.monoMetadata.copyWith(color: RecallrColors.crimsonAlert),
                ),
              ],
              RecallrSpacing.gapLg,
              RecallrButton(
                label: 'Go Home',
                variant: RecallrButtonVariant.primary,
                onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}