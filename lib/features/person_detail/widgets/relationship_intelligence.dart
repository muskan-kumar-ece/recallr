import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../relationship_intelligence/models/models.dart';
import '../../relationship_intelligence/widgets/relationship_momentum_card.dart';
import '../models/person_profile_model.dart';

/// Phase 12, Phase 13H-01, 13H-02, 13H-03 & 13H-05:
/// Relationship Intelligence Snapshot strip, Momentum Card & "Recommended Next Step" in Person Dossier.
class RelationshipIntelligence extends StatelessWidget {
  final PersonProfile profile;
  final PersonRelationshipIntelligence? intelligence;
  final RelationshipAction? primaryAction;
  final RelationshipAttention? attention;
  final RelationshipMomentum? momentum;
  final List<NetworkConnection>? connections;
  final bool isBridge;
  final String? bridgeExplanation;
  final UnifiedPersonRelationshipIntelligence? unified;
  final VoidCallback? onCreateFollowUp;
  final VoidCallback? onActionTap;
  final VoidCallback? onViewHistory;

  const RelationshipIntelligence({
    super.key,
    required this.profile,
    this.intelligence,
    this.primaryAction,
    this.attention,
    this.momentum,
    this.connections,
    this.isBridge = false,
    this.bridgeExplanation,
    this.unified,
    this.onCreateFollowUp,
    this.onActionTap,
    this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    final intel = unified?.baseIntelligence ?? intelligence ?? _deriveDefaultIntelligence();
    final state = unified?.relationshipState ?? intelligence?.state ?? intel.state;
    final strength = unified?.relationshipStrength ?? intelligence?.strength ?? intel.strength;
    final action = primaryAction ?? unified?.relationshipAction;
    final effectiveAttention = attention ?? unified?.relationshipAttention;
    final effectiveMomentum = momentum ?? unified?.relationshipMomentum;
    final effectiveConnections = connections ?? unified?.networkConnections;
    final effectiveIsBridge = isBridge || (unified?.isBridge ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(
              Icons.hub_outlined,
              size: 16.0,
              color: RecallrColors.aiCyanHighlight,
            ),
            RecallrSpacing.gapXs,
            Expanded(
              child: Text(
                'Relationship Snapshot',
                style: RecallrTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8.0),
            // Relationship State Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
              decoration: BoxDecoration(
                color: state.colorToken.withValues(alpha: 0.15),
                borderRadius: RecallrRadii.radiusPill,
                border: Border.all(
                  color: state.colorToken.withValues(alpha: 0.4),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6.0,
                    height: 6.0,
                    decoration: BoxDecoration(
                      color: state.colorToken,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    state.badgeLabel,
                    style: RecallrTypography.labelSmall.copyWith(
                      color: state.colorToken,
                      fontSize: 10.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        RecallrSpacing.gapSm,
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStrengthScoreCard(strength),
                  RecallrSpacing.gapSm,
                  _buildSignalsCard(intel.signals),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: _buildStrengthScoreCard(strength),
                ),
                RecallrSpacing.gapSm,
                Expanded(
                  flex: 5,
                  child: _buildSignalsCard(intel.signals),
                ),
              ],
            );
          },
        ),
        if (intel.explanations.isNotEmpty) ...[
          RecallrSpacing.gapSm,
          _buildExplanationPills(intel.explanations),
        ],
        if (effectiveMomentum != null) ...[
          const SizedBox(height: 12.0),
          RelationshipMomentumCard(momentum: effectiveMomentum),
        ],
        if (effectiveAttention != null && effectiveAttention.priority != RelationshipAttentionPriority.low) ...[
          const SizedBox(height: 12.0),
          _buildAttentionNotice(effectiveAttention),
        ],
        if (action != null) ...[
          const SizedBox(height: 12.0),
          _buildActionSection(action),
        ],
        if (effectiveConnections != null) ...[
          const SizedBox(height: 12.0),
          _buildNetworkConnectionsSection(effectiveConnections, effectiveIsBridge),
        ],
      ],
    );
  }

  Widget _buildStrengthScoreCard(RelationshipStrength strength) {
    return Container(
      padding: const EdgeInsets.all(RecallrSpacing.md),
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: RecallrRadii.radiusMd,
        border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STRENGTH',
                style: RecallrTypography.labelSmall.copyWith(
                  color: RecallrColors.textTertiary,
                  fontSize: 10.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${strength.score.toInt()}/100',
                style: RecallrTypography.labelSmall.copyWith(
                  color: strength.score >= 70
                      ? RecallrColors.emeraldVerified
                      : (strength.score >= 35 ? RecallrColors.aiCyanHighlight : RecallrColors.warmAmberGold),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          ClipRRect(
            borderRadius: RecallrRadii.radiusPill,
            child: LinearProgressIndicator(
              value: strength.score / 100.0,
              backgroundColor: RecallrColors.slateSurface,
              valueColor: AlwaysStoppedAnimation<Color>(
                strength.score >= 70
                    ? RecallrColors.emeraldVerified
                    : (strength.score >= 35 ? RecallrColors.aiCyanHighlight : RecallrColors.warmAmberGold),
              ),
              minHeight: 6.0,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            profile.relationshipStrength.isNotEmpty
                ? profile.relationshipStrength
                : (strength.summary.isNotEmpty
                    ? strength.summary
                    : 'Derived from interaction cadence and memory depth.'),
            style: RecallrTypography.bodyMedium.copyWith(
              color: RecallrColors.textSecondary,
              fontSize: 11.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSignalsCard(RelationshipSignals signals) {
    final daysText = signals.daysSinceLastInteraction != null
        ? '${signals.daysSinceLastInteraction}d ago'
        : 'Never';

    return Container(
      padding: const EdgeInsets.all(RecallrSpacing.md),
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: RecallrRadii.radiusMd,
        border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SIGNALS',
            style: RecallrTypography.labelSmall.copyWith(
              color: RecallrColors.textTertiary,
              fontSize: 10.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _SignalItem(
                  label: 'First Met',
                  value: profile.firstMet.isNotEmpty ? profile.firstMet : 'Recent',
                  icon: Icons.calendar_today_outlined,
                ),
              ),
              const SizedBox(width: 4.0),
              Expanded(
                child: _SignalItem(
                  label: 'Last Interaction',
                  value: profile.lastInteraction.isNotEmpty ? profile.lastInteraction : daysText,
                  icon: Icons.history_rounded,
                  isAlert: signals.daysSinceLastInteraction != null && signals.daysSinceLastInteraction! > 45,
                ),
              ),
              const SizedBox(width: 4.0),
              Expanded(
                child: _SignalItem(
                  label: 'Interactions',
                  value: '${profile.totalInteractions > 0 ? profile.totalInteractions : signals.interactionCount}',
                  icon: Icons.forum_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationPills(List<String> explanations) {
    return Wrap(
      spacing: 6.0,
      runSpacing: 4.0,
      children: explanations.map((exp) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.5),
          decoration: BoxDecoration(
            color: RecallrColors.slateSurface,
            borderRadius: RecallrRadii.radiusSm,
            border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
          ),
          child: Text(
            exp,
            style: RecallrTypography.labelSmall.copyWith(
              color: RecallrColors.textSecondary,
              fontSize: 10.5,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAttentionNotice(RelationshipAttention att) {
    return Container(
      padding: const EdgeInsets.all(RecallrSpacing.md),
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: RecallrRadii.radiusMd,
        border: Border.all(
          color: att.priority.colorToken.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_outlined, size: 14.0, color: att.priority.colorToken),
              const SizedBox(width: 6.0),
              Expanded(
                child: Text(
                  'WHY THIS NEEDS ATTENTION',
                  style: RecallrTypography.labelSmall.copyWith(
                    color: RecallrColors.textTertiary,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: att.priority.colorToken.withValues(alpha: 0.15),
                  borderRadius: RecallrRadii.radiusSm,
                ),
                child: Text(
                  att.priority.badgeLabel,
                  style: RecallrTypography.labelSmall.copyWith(
                    color: att.priority.colorToken,
                    fontSize: 9.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (att.reasons.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            Text(
              att.reasons.first.description,
              style: RecallrTypography.bodyMedium.copyWith(
                color: RecallrColors.textSecondary,
                fontSize: 12.0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionSection(RelationshipAction action) {
    return Container(
      padding: const EdgeInsets.all(RecallrSpacing.md),
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: RecallrRadii.radiusMd,
        border: Border.all(
          color: action.priority.colorToken.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(action.type.icon, size: 14.0, color: action.priority.colorToken),
              const SizedBox(width: 6.0),
              Expanded(
                child: Text(
                  'RECOMMENDED NEXT STEP',
                  style: RecallrTypography.labelSmall.copyWith(
                    color: RecallrColors.textTertiary,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: action.priority.colorToken.withValues(alpha: 0.15),
                  borderRadius: RecallrRadii.radiusSm,
                ),
                child: Text(
                  action.priority.badgeLabel,
                  style: RecallrTypography.labelSmall.copyWith(
                    color: action.priority.colorToken,
                    fontSize: 9.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            action.title,
            style: RecallrTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            action.description,
            style: RecallrTypography.bodyMedium.copyWith(
              color: RecallrColors.textSecondary,
              fontSize: 12.0,
            ),
          ),
          if (action.recommendedAt.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 12.0, color: RecallrColors.textTertiary),
                const SizedBox(width: 4.0),
                Flexible(
                  child: Text(
                    'Recommended: ${action.recommendedAt}',
                    style: RecallrTypography.labelSmall.copyWith(
                      color: RecallrColors.textTertiary,
                      fontSize: 10.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12.0),
          RecallrButton(
            label: 'Create Follow-up',
            variant: RecallrButtonVariant.primary,
            leadingIcon: Icons.add_task_rounded,
            onPressed: () {
              if (onCreateFollowUp != null) {
                onCreateFollowUp!();
              } else if (onActionTap != null) {
                onActionTap!();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkConnectionsSection([List<NetworkConnection>? connsOverride, bool? isBridgeOverride]) {
    final conns = connsOverride ?? connections ?? const [];
    final bridgeActive = isBridgeOverride ?? isBridge;

    return Container(
      margin: const EdgeInsets.only(top: RecallrSpacing.sm),
      padding: const EdgeInsets.all(RecallrSpacing.md),
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: RecallrRadii.radiusMd,
        border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hub_outlined, size: 14.0, color: RecallrColors.aiCyanHighlight),
              const SizedBox(width: 6.0),
              Text(
                'CONNECTED THROUGH',
                style: RecallrTypography.labelSmall.copyWith(
                  color: RecallrColors.textTertiary,
                  fontSize: 10.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              if (bridgeActive) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: RecallrColors.aiElectricViolet.withValues(alpha: 0.2),
                    borderRadius: RecallrRadii.radiusPill,
                    border: Border.all(color: RecallrColors.aiElectricViolet.withValues(alpha: 0.6), width: 0.8),
                  ),
                  child: Text(
                    'NETWORK BRIDGE',
                    style: RecallrTypography.labelSmall.copyWith(
                      color: RecallrColors.aiElectricViolet,
                      fontSize: 9.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8.0),
          if (conns.isEmpty) ...[
            Text(
              'No recorded network connections yet.',
              style: RecallrTypography.bodyMedium.copyWith(
                color: RecallrColors.textSecondary,
                fontSize: 12.0,
              ),
            ),
          ] else ...[
            ...conns.map((c) {
              final otherName = c.personAId == profile.id ? c.personBName : c.personAName;
              final typeLabel = c.connectionType.label;
              final contextDetail = c.sharedCompany != null
                  ? ' (' + c.sharedCompany! + ')'
                  : (c.sharedContext != null ? ' (' + c.sharedContext! + ')' : '');
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: RecallrColors.slateSurface,
                        borderRadius: RecallrRadii.radiusSm,
                        border: Border.all(color: RecallrColors.borderSubtle, width: 0.8),
                      ),
                      child: Text(
                        typeLabel,
                        style: RecallrTypography.labelSmall.copyWith(
                          color: RecallrColors.aiCyanHighlight,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        'with ' + otherName + contextDetail,
                        style: RecallrTypography.bodyMedium.copyWith(
                          color: RecallrColors.textPrimary,
                          fontSize: 12.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${c.connectionScore.toInt()}/100',
                      style: RecallrTypography.labelSmall.copyWith(
                        color: RecallrColors.textTertiary,
                        fontSize: 10.0,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (isBridge && bridgeExplanation != null && bridgeExplanation!.isNotEmpty) ...[
            const SizedBox(height: 6.0),
            Text(
              bridgeExplanation!,
              style: RecallrTypography.labelSmall.copyWith(
                color: RecallrColors.textSecondary,
                fontSize: 11.0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  PersonRelationshipIntelligence _deriveDefaultIntelligence() {
    final strLower = profile.relationshipStrength.toLowerCase();

    if (profile.totalInteractions == 0) {
      return PersonRelationshipIntelligence(
        personId: profile.id,
        signals: RelationshipSignals.empty(),
        strength: RelationshipStrength.zero(),
        state: RelationshipState.newRelationship,
        explanations: const ['Recently added contact with limited history.'],
        topFactors: const [],
        generatedAt: DateTime.now(),
      );
    }

    RelationshipState state = RelationshipState.active;
    double score = 50.0;
    String level = 'Active';

    if (strLower.contains('strong') || strLower.contains('high') || profile.totalInteractions >= 6) {
      state = RelationshipState.strong;
      score = 85.0;
      level = 'Strong';
    } else if (strLower.contains('cooling')) {
      state = RelationshipState.cooling;
      score = 45.0;
      level = 'Cooling';
    } else if (strLower.contains('neglected')) {
      state = RelationshipState.neglected;
      score = 30.0;
      level = 'Neglected';
    } else if (strLower.contains('dormant')) {
      state = RelationshipState.dormant;
      score = 15.0;
      level = 'Dormant';
    }

    final signals = RelationshipSignals(
      interactionCount: profile.totalInteractions,
      daysSinceLastInteraction: 5,
      recentInteractionCount: profile.totalInteractions >= 2 ? 2 : 1,
      memoryCount: profile.memories.length,
      activeFollowUpCount: profile.followUps.where((f) => !f.isCompleted).length,
      completedFollowUpCount: profile.followUps.where((f) => f.isCompleted).length,
    );

    final strength = RelationshipStrength(
      score: score,
      level: level,
      summary: '${profile.totalInteractions} recorded interactions with ${profile.name}',
      factors: [
        StrengthFactor(
          name: 'Interaction History',
          score: (score / 100.0).clamp(0.0, 1.0),
          weight: 1.0,
          explanation: '${profile.totalInteractions} recorded interactions',
        ),
      ],
    );

    return PersonRelationshipIntelligence(
      personId: profile.id,
      signals: signals,
      strength: strength,
      state: state,
      explanations: [
        '${profile.totalInteractions} recorded interactions',
      ],
      topFactors: strength.factors,
      generatedAt: DateTime.now(),
    );
  }
}

class _SignalItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isAlert;

  const _SignalItem({
    required this.label,
    required this.value,
    required this.icon,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11.0, color: isAlert ? RecallrColors.warmAmberGold : RecallrColors.textTertiary),
            const SizedBox(width: 3.0),
            Flexible(
              child: Text(
                label,
                style: RecallrTypography.labelSmall.copyWith(
                  color: RecallrColors.textTertiary,
                  fontSize: 9.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2.0),
        Text(
          value,
          style: RecallrTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: isAlert ? RecallrColors.warmAmberGold : RecallrColors.textPrimary,
            fontSize: 12.0,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
