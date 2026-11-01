import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/di/recallr_dependencies.dart';
import '../../core/routing/recallr_routes.dart';
import '../../app/app_shell.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeHeader(
            userName: widget.userName,
          ),
          RecallrSpacing.gapLg,

          // ── 1. Welcome Hero Card (Dark Indigo Carousel) ──────────────────────
          _WelcomeHeroCard(userName: widget.userName),
          const SizedBox(height: 24.0),

          // ── 2. Latest Things 2x2 Grid ─────────────────────────────────────────
          _LatestThingsSection(
            recentPeopleCount: stats.peopleCount,
            memoriesCount: recentMemories.length,
            interactionsCount: stats.interactionsCount,
            connectionsCount: stats.companiesCount,
          ),
          const SizedBox(height: 24.0),

          // ── 3. Stay Connected (Notifications & Follow-ups) ────────────────────
          _StayConnectedSection(
            followUpsCount: stats.followUpsCount,
            attentionCount: attentionItems.length,
          ),
          const SizedBox(height: 24.0),

          // ── 4. Search & Quick Capture ────────────────────────────────────────
          const MemorySearchCard(),
          RecallrSpacing.gapMd,
          const QuickCaptureTile(),
          RecallrSpacing.gapLg,

          // ── 5. Intelligent Attention & Momentum If Present ───────────────────
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

          // ── 6. Key Contacts & Recent Memories ────────────────────────────────
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

          // ── 7. Memory Pulse & Quick Access to Network Intelligence ───────────
          MemoryPulse(stats: stats),
          RecallrSpacing.gapLg,
          _buildNetworkHealthCard(context),
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
          RecallrSpacing.gapMd,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const QuickCaptureTile(),
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
                    MemoryPulse(stats: stats),
                    RecallrSpacing.gapLg,
                    _buildNetworkHealthCard(context),
                    RecallrSpacing.gapLg,
                    if (recentPeople.isNotEmpty) ...[
                      RecentPeopleSection(
                        items: recentPeople,
                      ),
                    ],
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

// ─── Welcome Hero Card ────────────────────────────────────────────────────────

class _WelcomeHeroCard extends StatelessWidget {
  final String userName;

  const _WelcomeHeroCard({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: const Color(0xFF312E81),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B4B).withValues(alpha: 0.4),
            blurRadius: 16.0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR PERSONAL MEMORY',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: const Color(0xFFA5B4FC).withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back!',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Your relationships, always remembered.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: const Color(0xFFC7D2FE).withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF312E81).withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: Color(0xFFA5B4FC),
                  size: 26.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          // Inner Focus Highlight Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: const Color(0xFF2E2A68),
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(
                color: const Color(0xFF4338CA).withValues(alpha: 0.35),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Remember what matters.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'People, conversations and important moments — all in one place.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.0,
                    height: 1.35,
                    color: const Color(0xFFC7D2FE).withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 12.0),
                Row(
                  children: [
                    // Carousel dots (5 indicators)
                    Container(
                      width: 7.0,
                      height: 7.0,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4.0),
                    Container(
                      width: 5.0,
                      height: 5.0,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4.0),
                    Container(
                      width: 5.0,
                      height: 5.0,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4.0),
                    Container(
                      width: 5.0,
                      height: 5.0,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4.0),
                    Container(
                      width: 5.0,
                      height: 5.0,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white70,
                      size: 16.0,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Latest Things Section ───────────────────────────────────────────────────

class _LatestThingsSection extends StatelessWidget {
  final int recentPeopleCount;
  final int memoriesCount;
  final int interactionsCount;
  final int connectionsCount;

  const _LatestThingsSection({
    required this.recentPeopleCount,
    required this.memoriesCount,
    required this.interactionsCount,
    required this.connectionsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Latest things',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  color: RecallrColors.textPrimary,
                ),
              ),
            ),
            InkWell(
              onTap: () => Navigator.of(context).pushNamed(RecallrRoutes.activity),
              borderRadius: BorderRadius.circular(6.0),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'This week',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: RecallrColors.aiElectricViolet,
                      ),
                    ),
                    SizedBox(width: 2.0),
                    Icon(
                      Icons.north_east_rounded,
                      size: 13.0,
                      color: RecallrColors.aiElectricViolet,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10.0,
          crossAxisSpacing: 10.0,
          childAspectRatio: 1.45,
          children: [
            // 1. People
            _CategoryPreviewCard(
              title: 'People',
              subtitle: 'Recent connections',
              icon: Icons.people_outline_rounded,
              iconColor: const Color(0xFF8B5CF6),
              bgColor: const Color(0xFF1E1E3F),
              borderColor: const Color(0xFF332F63),
              onTap: () => RecallrAppShellScope.openTab(context, 1),
            ),
            // 2. Memories
            _CategoryPreviewCard(
              title: 'Memories',
              subtitle: 'Things worth remembering',
              icon: Icons.auto_awesome_rounded,
              iconColor: RecallrColors.emeraldVerified,
              bgColor: const Color(0xFF0F2520),
              borderColor: const Color(0xFF1B4E41),
              onTap: () => RecallrAppShellScope.openTab(context, 2),
            ),
            // 3. Activity
            _CategoryPreviewCard(
              title: 'Activity',
              subtitle: 'Recent interactions',
              icon: Icons.calendar_today_outlined,
              iconColor: RecallrColors.warmAmberGold,
              bgColor: const Color(0xFF2A1F0A),
              borderColor: const Color(0xFF523E16),
              onTap: () => Navigator.of(context).pushNamed(RecallrRoutes.activity),
            ),
            // 4. Connections
            _CategoryPreviewCard(
              title: 'Connections',
              subtitle: 'Your growing network',
              icon: Icons.hub_outlined,
              iconColor: const Color(0xFFE879A0),
              bgColor: const Color(0xFF2A0F1A),
              borderColor: const Color(0xFF521E34),
              onTap: () => Navigator.of(context).pushNamed('/network'),
            ),
          ],
        ),
      ],
    );
  }
}

class _CategoryPreviewCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _CategoryPreviewCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: iconColor, size: 22.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: RecallrColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.0,
                    color: RecallrColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stay Connected Section ──────────────────────────────────────────────────

class _StayConnectedSection extends StatelessWidget {
  final int followUpsCount;
  final int attentionCount;

  const _StayConnectedSection({
    required this.followUpsCount,
    required this.attentionCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stay connected',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: RecallrColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12.0),
        Row(
          children: [
            // Notifications Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: RecallrColors.charcoalCard,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2050),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: RecallrColors.aiElectricViolet,
                        size: 20.0,
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.0,
                        fontWeight: FontWeight.w700,
                        color: RecallrColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    const Text(
                      'Important updates and reminders.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: RecallrColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12.0),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pushNamed(RecallrRoutes.activity),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF4338CA), width: 1.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                        ),
                        child: const Text(
                          'View alerts',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: RecallrColors.aiElectricViolet,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10.0),
            // Follow-ups Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: RecallrColors.charcoalCard,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D3327),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Icon(
                        Icons.event_available_outlined,
                        color: RecallrColors.emeraldVerified,
                        size: 20.0,
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    const Text(
                      'Follow-ups',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.0,
                        fontWeight: FontWeight.w700,
                        color: RecallrColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    const Text(
                      'Keep promises and reconnect.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: RecallrColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12.0),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pushNamed(RecallrRoutes.followUps),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF0F5132), width: 1.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                        ),
                        child: const Text(
                          'View follow-ups',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: RecallrColors.emeraldVerified,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
