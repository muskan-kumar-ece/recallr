import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/di/recallr_dependencies.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../features/activity/models/activity_models.dart';
import '../../features/follow_ups/models/follow_up_models.dart';
import '../../features/home/models/home_memory_item.dart';
import '../../features/home/widgets/home_empty_state.dart';
import '../../features/home/widgets/home_header.dart';
import '../../features/home/widgets/memory_pulse.dart';
import '../../features/home/widgets/memory_search_card.dart';
import '../../features/home/widgets/needs_attention.dart';
import '../../features/home/widgets/quick_capture_tile.dart';
import '../../features/home/widgets/recent_memories.dart';
import '../../features/home/widgets/recent_people.dart';
import '../../features/home/widgets/relationship_attention_section.dart';
import '../../features/people/models/person_item.dart';
import '../../features/relationship_intelligence/models/models.dart';
import '../../repositories/activity_repository.dart';
import '../../repositories/follow_up_repository.dart';
import '../../repositories/people_repository.dart';
import '../../services/relationship/unified_relationship_intelligence_service.dart';

/// Phase 05, Phase 13G-01-B, Phase 13H-02 & Phase 13H-03:
/// Memory Command Center & Proactive Relationship Attention Feed.
class HomeScreen extends StatefulWidget {
  final String userName;
  final MemoryPulseStats? initialStats;
  final List<AttentionItem>? initialAttentionItems;
  final List<RecentPersonItem>? initialRecentPeople;
  final List<RecentMemoryItem>? initialRecentMemories;
  final List<RelationshipAction>? initialRelationshipActions;
  final List<RelationshipAttention>? initialRelationshipAttentions;
  final RelationshipIntelligenceSnapshot? initialSnapshot;
  final PeopleRepository? peopleRepository;
  final ActivityRepository? activityRepository;
  final FollowUpRepository? followUpRepository;
  final bool isEmpty;
  final bool isLoading;
  final bool isError;
  final VoidCallback? onRetry;

  const HomeScreen({
    super.key,
    this.userName = 'Alex',
    this.initialStats,
    this.initialAttentionItems,
    this.initialRecentPeople,
    this.initialRecentMemories,
    this.initialRelationshipActions,
    this.initialRelationshipAttentions,
    this.initialSnapshot,
    this.peopleRepository,
    this.activityRepository,
    this.followUpRepository,
    this.unifiedRelationshipIntelligenceService,
    this.isEmpty = false,
    this.isLoading = false,
    this.isError = false,
    this.onRetry,
  });

  final UnifiedRelationshipIntelligenceService? unifiedRelationshipIntelligenceService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PeopleRepository? _peopleRepo;
  ActivityRepository? _activityRepo;
  FollowUpRepository? _followUpRepo;

  StreamSubscription<RelationshipIntelligenceSnapshot>? _snapshotSub;
  StreamSubscription<List<PersonItem>>? _peopleSub;
  StreamSubscription<List<ActivityItem>>? _activitySub;
  StreamSubscription<List<FollowUpItem>>? _followUpSub;

  List<PersonItem>? _currentPeople;
  List<ActivityItem>? _currentActivities;
  List<FollowUpItem>? _currentFollowUps;

  MemoryPulseStats? _stats;
  List<AttentionItem> _attentionItems = [];
  List<RecentPersonItem> _recentPeople = [];
  List<RecentMemoryItem> _recentMemories = [];
  List<RelationshipAttention> _relationshipAttentions = [];
  bool _isLoading = true;
  bool _isError = false;
  bool _isEmpty = false;

  @override
  void initState() {
    super.initState();
    _isLoading = widget.isLoading;
    _isError = widget.isError;
    _isEmpty = widget.isEmpty;

    final hasFixtures = widget.initialStats != null ||
        widget.initialAttentionItems != null ||
        widget.initialRecentPeople != null ||
        widget.initialRecentMemories != null ||
        widget.initialRelationshipActions != null ||
        widget.initialRelationshipAttentions != null ||
        widget.initialSnapshot != null;

    if (hasFixtures) {
      if (widget.initialSnapshot != null) {
        final snap = widget.initialSnapshot!;
        _relationshipAttentions = snap.topAttention;
        _stats = widget.initialStats ??
            MemoryPulseStats(
              peopleCount: snap.totalPeople,
              companiesCount: snap.network.clusters.length,
              interactionsCount: snap.network.connectedPeople,
              followUpsCount: snap.network.attentionCount,
            );
        _attentionItems = widget.initialAttentionItems ?? [];
        _recentPeople = widget.initialRecentPeople ?? [];
        _recentMemories = widget.initialRecentMemories ?? [];
        _isLoading = false;
        _isEmpty = widget.isEmpty || snap.isEmpty;
      } else {
        _stats = widget.initialStats;
        _attentionItems = widget.initialAttentionItems ?? [];
        _recentPeople = widget.initialRecentPeople ?? [];
        _recentMemories = widget.initialRecentMemories ?? [];
        _relationshipAttentions = widget.initialRelationshipAttentions ??
            (widget.initialRelationshipActions != null
                ? _convertActionsToAttentions(widget.initialRelationshipActions!)
                : []);
        _isLoading = false;
        _isEmpty = widget.isEmpty;
      }
    }
  }

  List<RelationshipAttention> _convertActionsToAttentions(List<RelationshipAction> actions) {
    return actions.map((a) {
      final prio = a.priority == RelationshipActionPriority.urgent
          ? RelationshipAttentionPriority.critical
          : (a.priority == RelationshipActionPriority.high
              ? RelationshipAttentionPriority.high
              : (a.priority == RelationshipActionPriority.medium
                  ? RelationshipAttentionPriority.medium
                  : RelationshipAttentionPriority.low));

      return RelationshipAttention(
        personId: a.personId,
        personName: a.personName,
        attentionScore: a.priority.rank * 25.0,
        priority: prio,
        relationshipState: a.relationshipState,
        relationshipStrength: RelationshipStrength(
          score: a.relationshipScore,
          factors: const [],
          level: 'Active',
          summary: '',
        ),
        reasons: [
          RelationshipAttentionReason(
            code: a.type.name,
            title: a.title,
            description: a.description,
            weight: 1.0,
          ),
        ],
        primaryAction: a,
        recommendedTiming: a.recommendedAt,
        generatedAt: a.generatedAt,
        deduplicationKey: 'attention_${a.personId}_${prio.name}_${a.type.name}',
      );
    }).toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _peopleRepo = widget.peopleRepository ?? context.peopleRepo;
    _activityRepo = widget.activityRepository ?? context.activityRepo;
    _followUpRepo = widget.followUpRepository ?? context.followUpRepo;

    final hasFixtures = widget.initialStats != null ||
        widget.initialAttentionItems != null ||
        widget.initialRecentPeople != null ||
        widget.initialRecentMemories != null ||
        widget.initialRelationshipActions != null ||
        widget.initialRelationshipAttentions != null;

    if (!hasFixtures && !widget.isEmpty && !widget.isLoading && !widget.isError) {
      _subscribe();
    }
  }

  void _subscribe() {
    _peopleSub?.cancel();
    _activitySub?.cancel();
    _followUpSub?.cancel();
    _snapshotSub?.cancel();

    final unifiedService = widget.unifiedRelationshipIntelligenceService ??
        (mounted ? context.unifiedRelationshipIntelligence : RecallrDependencies.instance.unifiedRelationshipIntelligenceService);

    _snapshotSub = unifiedService.streamSnapshot().listen(
      (snapshot) {
        if (!mounted) return;
        setState(() {
          _relationshipAttentions = widget.initialRelationshipAttentions ?? snapshot.topAttention;
          _stats = widget.initialStats ??
              MemoryPulseStats(
                peopleCount: snapshot.totalPeople,
                companiesCount: snapshot.network.clusters.length,
                interactionsCount: snapshot.network.connectedPeople,
                followUpsCount: snapshot.network.attentionCount,
              );
          if (snapshot.isNotEmpty) {
            _isEmpty = false;
          }
          _isLoading = false;
        });
      },
      onError: (_) {},
    );

    _peopleSub = _peopleRepo?.streamPeople().listen(
      (list) {
        _currentPeople = list;
        if (mounted) _recompute();
      },
      onError: (_) {
        if (mounted) {
          setState(() {
            _isError = true;
            _isLoading = false;
          });
        }
      },
    );

    _activitySub = _activityRepo?.streamActivities().listen(
      (list) {
        _currentActivities = list;
        if (mounted) _recompute();
      },
      onError: (_) {
        if (mounted) {
          setState(() {
            _isError = true;
            _isLoading = false;
          });
        }
      },
    );

    _followUpSub = _followUpRepo?.streamFollowUps().listen(
      (list) {
        _currentFollowUps = list;
        if (mounted) _recompute();
      },
      onError: (_) {
        if (mounted) {
          setState(() {
            _isError = true;
            _isLoading = false;
          });
        }
      },
    );
  }

  void _recompute() {
    if (!mounted) return;
    final people = _currentPeople ?? [];
    final activities = _currentActivities ?? [];
    final followUps = _currentFollowUps ?? [];

    final peopleCount = people.length;
    final interactionsCount = activities.length;
    final followUpsCount = followUps.length;
    final companiesCount = people
        .map((p) => p.company)
        .where((c) => c.isNotEmpty)
        .toSet()
        .length;

    final stats = _stats ??
        MemoryPulseStats(
          peopleCount: peopleCount,
          companiesCount: companiesCount,
          interactionsCount: interactionsCount,
          followUpsCount: followUpsCount,
        );

    final recentPeople = people
        .take(5)
        .map((p) => RecentPersonItem(
              id: p.id,
              name: p.name,
              role: p.role,
              company: p.company,
              lastInteracted: p.lastInteraction,
              initials: p.initials,
              targetRoute: '/person/${p.id}',
            ))
        .toList();

    final recentMemories = activities
        .take(5)
        .map((a) => RecentMemoryItem(
              id: a.id,
              type: MemoryType.interaction,
              title: a.title,
              contextSnippet: a.summary,
              initials: (a.personName != null && a.personName!.isNotEmpty) ? a.personName![0] : '?',
              targetRoute: '/activity',
            ))
        .toList();

    final attentionItems = followUps
        .take(3)
        .map((f) => AttentionItem(
              id: f.id,
              type: f.commitmentType == CommitmentType.iPromised
                  ? AttentionType.pendingCommitment
                  : AttentionType.followUp,
              title: f.title,
              description: f.context,
              targetRoute: f.targetRoute,
              badgeText: f.commitmentType.badgeText,
              dueText: f.dueDate,
              icon: f.commitmentType.icon,
            ))
        .toList();

    final hasData = peopleCount > 0 || interactionsCount > 0 || followUpsCount > 0;

    setState(() {
      _stats = widget.initialStats ?? stats;
      _recentPeople = widget.initialRecentPeople ?? recentPeople;
      _recentMemories = widget.initialRecentMemories ?? recentMemories;
      _attentionItems = widget.initialAttentionItems ?? attentionItems;
      _relationshipAttentions = widget.initialRelationshipAttentions ??
          (widget.initialRelationshipActions != null
              ? _convertActionsToAttentions(widget.initialRelationshipActions!)
              : _relationshipAttentions);
      _isLoading = false;
      _isError = false;
      _isEmpty = widget.isEmpty || (!hasData && widget.initialStats == null && widget.initialAttentionItems == null && widget.initialRecentPeople == null);
    });
  }

  @override
  void dispose() {
    _snapshotSub?.cancel();
    _peopleSub?.cancel();
    _activitySub?.cancel();
    _followUpSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: RecallrSpacing.pagePadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: RecallrColors.aiCyanHighlight),
              RecallrSpacing.gapMd,
              Text(
                'Syncing relationship command center...',
                style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (_isError) {
      return Center(
        child: Padding(
          padding: RecallrSpacing.pagePadding,
          child: RecallrErrorState(
            message: "We couldn't load your memories. Please check your connection and try again.",
            onRetry: () {
              widget.onRetry?.call();
              _subscribe();
            },
          ),
        ),
      );
    }

    if (_isEmpty) {
      return const HomeEmptyState();
    }

    final stats = _stats ??
        const MemoryPulseStats(
          peopleCount: 0,
          companiesCount: 0,
          interactionsCount: 0,
          followUpsCount: 0,
        );

    final attentionItems = _attentionItems;
    final recentPeople = _recentPeople;
    final recentMemories = _recentMemories;
    final relationshipAttentions = _relationshipAttentions;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1024;

        if (isWide) {
          return _buildDesktopLayout(
            stats: stats,
            attentionItems: attentionItems,
            recentPeople: recentPeople,
            recentMemories: recentMemories,
            relationshipAttentions: relationshipAttentions,
          );
        }

        return _buildMobileTabletLayout(
          stats: stats,
          attentionItems: attentionItems,
          recentPeople: recentPeople,
          recentMemories: recentMemories,
          relationshipAttentions: relationshipAttentions,
        );
      },
    );
  }

  Widget _buildMobileTabletLayout({
    required MemoryPulseStats stats,
    required List<AttentionItem> attentionItems,
    required List<RecentPersonItem> recentPeople,
    required List<RecentMemoryItem> recentMemories,
    required List<RelationshipAttention> relationshipAttentions,
  }) {
    return SingleChildScrollView(
      padding: RecallrSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeHeader(
            userName: widget.userName,
          ),
          RecallrSpacing.gapLg,
          const MemorySearchCard(),
          RecallrSpacing.gapLg,
          MemoryPulse(stats: stats),
          RecallrSpacing.gapLg,
          _buildNetworkHealthCard(context),
          RecallrSpacing.gapLg,
          if (relationshipAttentions.isNotEmpty) ...[
            RelationshipAttentionSection(
              attentionItems: relationshipAttentions,
            ),
            RecallrSpacing.gapLg,
          ],
          if (attentionItems.isNotEmpty) ...[
            NeedsAttentionSection(
              items: attentionItems,
            ),
            RecallrSpacing.gapLg,
          ],
          if (recentPeople.isNotEmpty) ...[
            RecentPeopleSection(
              items: recentPeople,
            ),
            RecallrSpacing.gapLg,
          ],
          if (recentMemories.isNotEmpty) ...[
            RecentMemoriesSection(
              items: recentMemories,
            ),
            RecallrSpacing.gapLg,
          ],
          const QuickCaptureTile(),
          const SizedBox(height: 80.0),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout({
    required MemoryPulseStats stats,
    required List<AttentionItem> attentionItems,
    required List<RecentPersonItem> recentPeople,
    required List<RecentMemoryItem> recentMemories,
    required List<RelationshipAttention> relationshipAttentions,
  }) {
    return SingleChildScrollView(
      padding: RecallrSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeHeader(
            userName: widget.userName,
          ),
          RecallrSpacing.gapLg,
          const MemorySearchCard(),
          RecallrSpacing.gapLg,
          MemoryPulse(stats: stats),
          RecallrSpacing.gapLg,
          _buildNetworkHealthCard(context),
          RecallrSpacing.gapLg,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (relationshipAttentions.isNotEmpty) ...[
                      RelationshipAttentionSection(
                        attentionItems: relationshipAttentions,
                      ),
                      RecallrSpacing.gapLg,
                    ],
                    if (attentionItems.isNotEmpty) ...[
                      NeedsAttentionSection(
                        items: attentionItems,
                      ),
                      RecallrSpacing.gapLg,
                    ],
                    if (recentMemories.isNotEmpty) ...[
                      RecentMemoriesSection(
                        items: recentMemories,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 24.0),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    if (recentPeople.isNotEmpty) ...[
                      RecentPeopleSection(
                        items: recentPeople,
                      ),
                      RecallrSpacing.gapLg,
                    ],
                    const QuickCaptureTile(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 80.0),
        ],
      ),
    );
  }

  Widget _buildNetworkHealthCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/network'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: RecallrSpacing.md, vertical: RecallrSpacing.sm + 2.0),
        decoration: BoxDecoration(
          color: RecallrColors.slateSurface,
          borderRadius: RecallrRadii.radiusMd,
          border: Border.all(
            color: RecallrColors.aiCyanHighlight.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.hub_outlined,
              size: 18.0,
              color: RecallrColors.aiCyanHighlight,
            ),
            RecallrSpacing.gapSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Network Intelligence',
                    style: RecallrTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: RecallrColors.textPrimary,
                    ),
                  ),
                  Text(
                    'View network health, trends, and relationship distribution',
                    style: RecallrTypography.bodyMedium.copyWith(
                      color: RecallrColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13.0,
              color: RecallrColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
