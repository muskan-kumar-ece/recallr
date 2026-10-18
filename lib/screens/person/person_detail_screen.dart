import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/di/recallr_dependencies.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../features/person_detail/models/person_profile_model.dart';
import '../../features/person_detail/widgets/ai_relationship_summary.dart';
import '../../features/person_detail/widgets/ask_about_person_card.dart';
import '../../features/person_detail/widgets/connected_entities_section.dart';
import '../../features/person_detail/widgets/person_action_bar.dart';
import '../../features/person_detail/widgets/person_context_section.dart';
import '../../features/person_detail/widgets/person_follow_ups_section.dart';
import '../../features/person_detail/widgets/person_memories_section.dart';
import '../../features/person_detail/widgets/person_profile_header.dart';
import '../../features/person_detail/widgets/person_timeline_section.dart';
import '../../features/person_detail/widgets/relationship_intelligence.dart';
import '../../repositories/person_detail_repository.dart';
import '../capture/capture_modal.dart';

/// Phase 12 & Phase 13G: Person Detail / Relationship Dossier Screen.
/// Cleanly wired to FirestorePersonDetailRepository without mock profile fallbacks.
class PersonDetailScreen extends StatefulWidget {
  final String personId;
  final PersonProfile? initialProfile;
  final bool isLoading;
  final bool isError;
  final VoidCallback? onRetry;
  final PersonDetailRepository? repository;

  const PersonDetailScreen({
    super.key,
    required this.personId,
    this.initialProfile,
    this.isLoading = false,
    this.isError = false,
    this.onRetry,
    this.repository,
  });

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  PersonProfile? _profile;
  late bool _isLoading;
  late bool _isError;
  StreamSubscription<PersonProfile?>? _profileSubscription;

  PersonDetailRepository get _repository =>
      widget.repository ??
      (mounted ? context.personDetailRepo : RecallrDependencies.instance.personDetailRepository);

  @override
  void initState() {
    super.initState();
    _isLoading = widget.isLoading ||
        (widget.initialProfile == null && !widget.isError);
    _isError = widget.isError;
    _profile = widget.initialProfile;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.initialProfile == null && !widget.isLoading && !widget.isError) {
      _subscribeToProfile();
    }
  }

  void _subscribeToProfile() {
    _profileSubscription?.cancel();
    if (widget.initialProfile != null || widget.isError) return;

    _profileSubscription = _repository.streamProfile(widget.personId).listen(
      (prof) {
        if (mounted) {
          setState(() {
            _profile = prof;
            _isLoading = false;
            _isError = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isError = true;
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  void didUpdateWidget(covariant PersonDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading ||
        oldWidget.isError != widget.isError ||
        oldWidget.personId != widget.personId ||
        oldWidget.initialProfile != widget.initialProfile) {
      setState(() {
        _isLoading = widget.isLoading ||
            (widget.initialProfile == null && !widget.isError && _profile == null);
        _isError = widget.isError;
        if (widget.initialProfile != null) {
          _profile = widget.initialProfile;
        }
      });
      if (widget.initialProfile == null && !widget.isError) {
        _subscribeToProfile();
      }
    }
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }

  void _handleRetry() {
    if (widget.onRetry != null) {
      widget.onRetry!();
    } else {
      setState(() {
        _isError = false;
        _isLoading = true;
      });
      _subscribeToProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: RecallrSpacing.pagePadding,
            child: RecallrErrorState(
              message: "We couldn't load this person's memory dossier. Please try again.",
              onRetry: _handleRetry,
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        body: SafeArea(
          child: _buildLoadingSkeleton(),
        ),
      );
    }

    if (_profile == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: RecallrSpacing.pagePadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_off_outlined,
                  size: 48.0,
                  color: RecallrColors.textSecondary,
                ),
                RecallrSpacing.gapMd,
                Text(
                  'Person Not Found',
                  style: RecallrTypography.headlineMedium,
                ),
                RecallrSpacing.gapSm,
                Text(
                  'No relationship memory matches ID "${widget.personId}".',
                  style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary),
                ),
                RecallrSpacing.gapLg,
                RecallrButton(
                  label: 'Back to People',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profile = _profile!;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 768;
          final double maxWidth = constraints.maxWidth > 1100 ? 1040 : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: isWide ? _buildWideLayout(profile) : _buildMobileLayout(profile),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPartialNotice(PersonProfile profile) {
    return RecallrCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 16.0,
                color: RecallrColors.warmAmberGold,
              ),
              RecallrSpacing.gapXs,
              Expanded(
                child: Text(
                  'Partial Memory Dossier',
                  style: RecallrTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          RecallrSpacing.gapSm,
          Text(
            profile.aiSummary,
            style: RecallrTypography.bodyMedium.copyWith(
              color: RecallrColors.textSecondary,
            ),
          ),
          RecallrSpacing.gapMd,
          RecallrButton(
            label: 'Capture First Encounter',
            leadingIcon: Icons.add_rounded,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const CaptureModal(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeletePerson(PersonProfile profile) async {
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
            Text('Delete Contact', style: RecallrTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Are you sure you want to remove ${profile.name} from your people directory? This action cannot be undone.',
          style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary),
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
        final peopleRepo = mounted ? context.peopleRepo : RecallrDependencies.instance.peopleRepository;
        await peopleRepo.deletePerson(profile.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed ${profile.name} from directory'),
              backgroundColor: RecallrColors.slateSurface,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete contact: $e'),
              backgroundColor: RecallrColors.crimsonAlert,
            ),
          );
        }
      }
    }
  }

  Widget _buildMobileLayout(PersonProfile profile) {
    final bool isPartial = profile.timeline.isEmpty && profile.memories.isEmpty && profile.aiSummary.isNotEmpty;
    final unified = (mounted ? context.unifiedRelationshipIntelligence : RecallrDependencies.instance.unifiedRelationshipIntelligenceService)
        .computePersonIntelligenceSync(profile: profile);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PersonProfileHeader(
            profile: profile,
            onBack: () => Navigator.of(context).pop(),
            onDelete: () => _handleDeletePerson(profile),
          ),
        ),
        SliverPadding(
          padding: RecallrSpacing.pagePadding,
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              PersonActionBar(profile: profile),
              RecallrSpacing.gapLg,
              RelationshipIntelligence(
                profile: profile,
                unified: unified,
                intelligence: unified.baseIntelligence,
                primaryAction: unified.primaryAction,
                attention: unified.relationshipAttention,
                momentum: unified.relationshipMomentum,
                connections: unified.networkConnections,
                isBridge: unified.isBridge,
              ),
              RecallrSpacing.gapLg,
              if (isPartial) ...[
                _buildPartialNotice(profile),
                RecallrSpacing.gapLg,
              ] else if (profile.aiSummary.isNotEmpty) ...[
                AiRelationshipSummary(
                  summary: profile.aiSummary,
                  keyTakeaways: profile.keyTakeaways,
                ),
                RecallrSpacing.gapLg,
              ],
              AskAboutPersonCard(profile: profile),
              RecallrSpacing.gapLg,
              PersonContextSection(profile: profile),
              RecallrSpacing.gapLg,
              if (!isPartial) ...[
                PersonTimelineSection(items: profile.timeline),
                RecallrSpacing.gapLg,
                PersonMemoriesSection(items: profile.memories),
                RecallrSpacing.gapLg,
              ],
              PersonFollowUpsSection(items: profile.followUps),
              RecallrSpacing.gapLg,
              ConnectedEntitiesSection(items: profile.connectedEntities),
            ]),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 80.0),
        ),
      ],
    );
  }

  Widget _buildWideLayout(PersonProfile profile) {
    final bool isPartial = profile.timeline.isEmpty && profile.memories.isEmpty && profile.aiSummary.isNotEmpty;
    final unified = (mounted ? context.unifiedRelationshipIntelligence : RecallrDependencies.instance.unifiedRelationshipIntelligenceService)
        .computePersonIntelligenceSync(profile: profile);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PersonProfileHeader(
            profile: profile,
            onBack: () => Navigator.of(context).pop(),
            onDelete: () => _handleDeletePerson(profile),
          ),
        ),
        SliverPadding(
          padding: RecallrSpacing.pagePadding,
          sliver: SliverToBoxAdapter(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PersonActionBar(profile: profile),
                      RecallrSpacing.gapLg,
                      RelationshipIntelligence(
                        profile: profile,
                        unified: unified,
                        intelligence: unified.baseIntelligence,
                        primaryAction: unified.primaryAction,
                        attention: unified.relationshipAttention,
                        momentum: unified.relationshipMomentum,
                        connections: unified.networkConnections,
                        isBridge: unified.isBridge,
                      ),
                      RecallrSpacing.gapLg,
                      if (isPartial) ...[
                        _buildPartialNotice(profile),
                        RecallrSpacing.gapLg,
                      ] else if (profile.aiSummary.isNotEmpty) ...[
                        AiRelationshipSummary(
                          summary: profile.aiSummary,
                          keyTakeaways: profile.keyTakeaways,
                        ),
                        RecallrSpacing.gapLg,
                      ],
                      AskAboutPersonCard(profile: profile),
                      RecallrSpacing.gapLg,
                      PersonContextSection(profile: profile),
                      RecallrSpacing.gapLg,
                      ConnectedEntitiesSection(items: profile.connectedEntities),
                    ],
                  ),
                ),
                RecallrSpacing.gapLg,
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isPartial) ...[
                        PersonTimelineSection(items: profile.timeline),
                        RecallrSpacing.gapLg,
                        PersonMemoriesSection(items: profile.memories),
                        RecallrSpacing.gapLg,
                      ],
                      PersonFollowUpsSection(items: profile.followUps),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 80.0),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: RecallrSpacing.pagePadding,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const RecallrSkeleton(height: 120.0),
        RecallrSpacing.gapLg,
        const RecallrSkeleton(height: 52.0),
        RecallrSpacing.gapLg,
        const RecallrSkeleton(height: 140.0),
        RecallrSpacing.gapLg,
        const RecallrSkeleton(height: 180.0),
        RecallrSpacing.gapLg,
        const RecallrSkeleton(height: 200.0),
      ],
    );
  }
}