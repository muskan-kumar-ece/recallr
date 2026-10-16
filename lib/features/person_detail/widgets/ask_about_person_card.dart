import 'package:flutter/material.dart';
import '../../../core/routing/recallr_routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/chips/recallr_chip.dart';
import '../models/person_profile_model.dart';

/// Contextual "Ask about {Person}" AI Card connecting to Grounded Memory Engine.
class AskAboutPersonCard extends StatelessWidget {
  final PersonProfile profile;

  const AskAboutPersonCard({super.key, required this.profile});

  void _navigateToAsk(BuildContext context, String query) {
    Navigator.of(context).pushNamed(
      RecallrRoutes.ask,
      arguments: query,
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstName = profile.name.split(' ').first;

    return Container(
      padding: RecallrSpacing.cardPadding,
      decoration: BoxDecoration(
        color: RecallrColors.slateSurface,
        borderRadius: RecallrRadii.radiusLg,
        border: Border.all(
          color: RecallrColors.borderHighlight,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6.0),
                decoration: const BoxDecoration(
                  color: RecallrColors.aiElectricViolet,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: RecallrColors.textPrimary,
                  size: 14.0,
                ),
              ),
              RecallrSpacing.gapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ask about $firstName',
                      style: RecallrTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                      ),
                    ),
                    Text(
                      'Query conversations, promises, and past encounters',
                      style: RecallrTypography.bodyMedium.copyWith(
                        color: RecallrColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          RecallrSpacing.gapMd,

          // Interactive prompt bar
          InkWell(
            onTap: () => _navigateToAsk(context, 'Everything about $firstName'),
            borderRadius: RecallrRadii.radiusPill,
            child: Container(
              height: 42.0,
              padding: const EdgeInsets.symmetric(horizontal: RecallrSpacing.md),
              decoration: BoxDecoration(
                color: RecallrColors.charcoalCard,
                borderRadius: RecallrRadii.radiusPill,
                border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: RecallrColors.textTertiary,
                    size: 16.0,
                  ),
                  RecallrSpacing.gapSm,
                  Expanded(
                    child: Text(
                      'What did I discuss with $firstName?',
                      style: RecallrTypography.bodyMedium.copyWith(
                        color: RecallrColors.textTertiary,
                        fontSize: 12.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: RecallrColors.slateSurface,
                      borderRadius: RecallrRadii.radiusSm,
                      border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
                    ),
                    child: Text(
                      'ASK',
                      style: RecallrTypography.monoMetadata.copyWith(
                        color: RecallrColors.aiCyanHighlight,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contextual prompt suggestion chips
          if (profile.promptSuggestions.isNotEmpty) ...[
            RecallrSpacing.gapSm,
            Wrap(
              spacing: RecallrSpacing.xs,
              runSpacing: RecallrSpacing.xs,
              children: profile.promptSuggestions.map((prompt) {
                return RecallrChip(
                  label: prompt,
                  leadingIcon: Icons.bolt_rounded,
                  onTap: () => _navigateToAsk(context, prompt),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}