import 'package:flutter/material.dart';
import '../../core/di/recallr_dependencies.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';
import '../capture/capture_modal.dart';
import '../../features/relationship_intelligence/models/models.dart';
import '../../features/relationship_intelligence/widgets/network_clusters_section.dart';
import '../../features/relationship_intelligence/widgets/network_connections_summary.dart';
import '../../features/relationship_intelligence/widgets/network_distribution_bar.dart';
import '../../features/relationship_intelligence/widgets/network_health_header.dart';
import '../../features/relationship_intelligence/widgets/network_insights_section.dart';
import '../../features/relationship_intelligence/widgets/network_metrics_grid.dart';
import '../../features/relationship_intelligence/widgets/network_patterns_section.dart';
import '../../features/relationship_intelligence/widgets/network_trends_section.dart';
import '../../features/relationship_intelligence/widgets/relationship_attention_card.dart';

/// Supported filter pills for the Network Dashboard.
enum NetworkDashboardFilter {
  all,
  strongConnections,
  clusters,
  cooling,
  bridges,
  isolated,
  companies,
  projects,
}

extension NetworkDashboardFilterExt on NetworkDashboardFilter {
  String get label {
    switch (this) {
      case NetworkDashboardFilter.all:
        return 'All';
      case NetworkDashboardFilter.strongConnections:
        return 'Strong Connections';
      case NetworkDashboardFilter.clusters:
        return 'Clusters';
      case NetworkDashboardFilter.cooling:
        return 'Cooling';
      case NetworkDashboardFilter.bridges:
        return 'Bridges';
      case NetworkDashboardFilter.isolated:
        return 'Isolated';
      case NetworkDashboardFilter.companies:
        return 'Companies';
      case NetworkDashboardFilter.projects:
        return 'Projects';
    }
  }
}

/// Phase 13H-04, Phase 13H-05 & Phase 13H-06: Network Intelligence, Connections & Patterns Dashboard.
class NetworkDashboardScreen extends StatefulWidget {
  final NetworkIntelligence? initialData;
  final NetworkConnectionIntelligence? initialConnectionData;
  final RelationshipIntelligenceSnapshot? initialSnapshot;
  final UnifiedNetworkRelationshipIntelligence? initialUnifiedNetwork;

  const NetworkDashboardScreen({
    super.key,
    this.initialData,
    this.initialConnectionData,
    this.initialSnapshot,
    this.initialUnifiedNetwork,
  });

  @override
  State<NetworkDashboardScreen> createState() => _NetworkDashboardScreenState();
}

class _NetworkDashboardScreenState extends State<NetworkDashboardScreen> {
  NetworkIntelligence? _intelligence;
  NetworkConnectionIntelligence? _connectionIntelligence;
  NetworkDashboardFilter _activeFilter = NetworkDashboardFilter.all;
  bool _isLoading = true;
  String? _errorMessage;
  DateTime? _lastLoadTime;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSnapshot != null) {
      final net = widget.initialSnapshot!.network;
      _intelligence = NetworkIntelligence(
        health: net.health,
        trends: net.trends,
        insights: net.insights,
        generatedAt: widget.initialSnapshot!.generatedAt,
      );
      _connectionIntelligence = net.toConnectionIntelligence();
      _isLoading = false;
      _hasLoaded = true;
    } else if (widget.initialUnifiedNetwork != null) {
      final net = widget.initialUnifiedNetwork!;
      _intelligence = NetworkIntelligence(
        health: net.health,
        trends: net.trends,
        insights: net.insights,
        generatedAt: net.generatedAt,
      );
      _connectionIntelligence = net.toConnectionIntelligence();
      _isLoading = false;
      _hasLoaded = true;
    } else if (widget.initialData != null) {
      _intelligence = widget.initialData;
      _connectionIntelligence = widget.initialConnectionData;
      _isLoading = false;
      _hasLoaded = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_lastLoadTime != null &&
        DateTime.now().difference(_lastLoadTime!) < const Duration(seconds: 2)) {
      return;
    }
    _lastLoadTime = DateTime.now();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await context.unifiedRelationshipIntelligence.getSnapshot();
      final net = snapshot.network;
      if (mounted) {
        setState(() {
          _intelligence = NetworkIntelligence(
            health: net.health,
            trends: net.trends,
            insights: net.insights,
            generatedAt: snapshot.generatedAt,
          );
          _connectionIntelligence = net.toConnectionIntelligence();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load network intelligence: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecallrColors.obsidianBase,
      appBar: AppBar(
        backgroundColor: RecallrColors.obsidianBase,
        elevation: 0.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: RecallrColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Network Intelligence',
          style: RecallrTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: RecallrColors.textSecondary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: RecallrColors.aiCyanHighlight),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: RecallrSpacing.pagePadding,
          child: RecallrErrorState(
            message: _errorMessage!,
            onRetry: _loadData,
          ),
        ),
      );
    }

    final intel = _intelligence ?? NetworkIntelligence.empty();
    final connIntel = _connectionIntelligence ?? NetworkConnectionIntelligence.empty();

    if (intel.health.totalPeople == 0 && connIntel.totalNodes == 0) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: RecallrColors.aiCyanHighlight,
      backgroundColor: RecallrColors.slateSurface,
      onRefresh: _loadData,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: RecallrSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFilterPills(),
                RecallrSpacing.gapMd,
                if (isWide) _buildWideLayout(intel, connIntel) else _buildMobileLayout(intel, connIntel),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: NetworkDashboardFilter.values.map((filter) {
          final isSelected = _activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: ChoiceChip(
              label: Text(
                filter.label,
                style: RecallrTypography.labelSmall.copyWith(
                  color: isSelected ? RecallrColors.obsidianBase : RecallrColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11.0,
                ),
              ),
              selected: isSelected,
              selectedColor: RecallrColors.aiCyanHighlight,
              backgroundColor: RecallrColors.charcoalCard,
              shape: RoundedRectangleBorder(
                borderRadius: RecallrRadii.radiusPill,
                side: BorderSide(
                  color: isSelected ? RecallrColors.aiCyanHighlight : RecallrColors.borderSubtle,
                  width: 0.8,
                ),
              ),
              onSelected: (_) {
                setState(() => _activeFilter = filter);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileLayout(NetworkIntelligence intel, NetworkConnectionIntelligence connIntel) {
    final filteredClusters = _filterClusters(connIntel.clusters);
    final filteredPatterns = _filterPatterns(connIntel.patterns);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_activeFilter == NetworkDashboardFilter.all) ...[
          NetworkHealthHeader(health: intel.health),
          RecallrSpacing.gapMd,
          NetworkMetricsGrid(health: intel.health),
          RecallrSpacing.gapMd,
          NetworkDistributionBar(health: intel.health),
          RecallrSpacing.gapMd,
          _buildEvolutionMomentumSummary(intel),
          RecallrSpacing.gapLg,
          NetworkConnectionsSummary(intelligence: connIntel),
          RecallrSpacing.gapLg,
          if (connIntel.clusters.isNotEmpty) ...[
            NetworkClustersSection(clusters: filteredClusters),
            RecallrSpacing.gapLg,
          ],
          if (connIntel.patterns.isNotEmpty) ...[
            NetworkPatternsSection(patterns: filteredPatterns),
            RecallrSpacing.gapLg,
          ],
          if (intel.topAttention.isNotEmpty) ...[
            _buildAttentionSection(intel.topAttention),
            RecallrSpacing.gapLg,
          ],
          NetworkInsightsSection(insights: intel.insights),
          RecallrSpacing.gapLg,
          NetworkTrendsSection(trends: intel.trends),
        ] else ...[
          NetworkConnectionsSummary(intelligence: connIntel),
          RecallrSpacing.gapLg,
          NetworkClustersSection(clusters: filteredClusters),
          RecallrSpacing.gapLg,
          NetworkPatternsSection(patterns: filteredPatterns),
        ],
        const SizedBox(height: 40.0),
      ],
    );
  }

  Widget _buildWideLayout(NetworkIntelligence intel, NetworkConnectionIntelligence connIntel) {
    final filteredClusters = _filterClusters(connIntel.clusters);
    final filteredPatterns = _filterPatterns(connIntel.patterns);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column (5 Flex)
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NetworkHealthHeader(health: intel.health),
              RecallrSpacing.gapMd,
              NetworkMetricsGrid(health: intel.health),
              RecallrSpacing.gapMd,
              NetworkDistributionBar(health: intel.health),
              RecallrSpacing.gapMd,
              NetworkConnectionsSummary(intelligence: connIntel),
              RecallrSpacing.gapLg,
              NetworkClustersSection(clusters: filteredClusters),
            ],
          ),
        ),
        const SizedBox(width: 16.0),
        // Right Column (5 Flex)
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NetworkPatternsSection(patterns: filteredPatterns),
              RecallrSpacing.gapMd,
              _buildEvolutionMomentumSummary(intel),
              RecallrSpacing.gapMd,
              if (intel.topAttention.isNotEmpty) ...[
                _buildAttentionSection(intel.topAttention),
                RecallrSpacing.gapMd,
              ],
              NetworkInsightsSection(insights: intel.insights),
              RecallrSpacing.gapMd,
              NetworkTrendsSection(trends: intel.trends),
            ],
          ),
        ),
      ],
    );
  }

  List<RelationshipCluster> _filterClusters(List<RelationshipCluster> clusters) {
    switch (_activeFilter) {
      case NetworkDashboardFilter.all:
      case NetworkDashboardFilter.clusters:
        return clusters;
      case NetworkDashboardFilter.companies:
        return clusters.where((c) => c.type == RelationshipClusterType.company).toList();
      case NetworkDashboardFilter.projects:
        return clusters.where((c) => c.type == RelationshipClusterType.project).toList();
      default:
        return clusters;
    }
  }

  List<NetworkPattern> _filterPatterns(List<NetworkPattern> patterns) {
    switch (_activeFilter) {
      case NetworkDashboardFilter.all:
        return patterns;
      case NetworkDashboardFilter.strongConnections:
        return patterns.where((p) => p.type == NetworkPatternType.strongCluster).toList();
      case NetworkDashboardFilter.clusters:
        return patterns.where((p) => p.type == NetworkPatternType.strongCluster || p.type == NetworkPatternType.emergingCluster).toList();
      case NetworkDashboardFilter.cooling:
        return patterns.where((p) => p.type == NetworkPatternType.coolingCluster).toList();
      case NetworkDashboardFilter.bridges:
        return patterns.where((p) => p.type == NetworkPatternType.relationshipBridge).toList();
      case NetworkDashboardFilter.isolated:
        return patterns.where((p) => p.type == NetworkPatternType.isolatedContact).toList();
      case NetworkDashboardFilter.companies:
        return patterns.where((p) => p.type == NetworkPatternType.companyConcentration).toList();
      case NetworkDashboardFilter.projects:
        return patterns.where((p) => p.type == NetworkPatternType.sharedContext).toList();
    }
  }

  Widget _buildEvolutionMomentumSummary(NetworkIntelligence intel) {
    final strengthenedCount = intel.recentlyStrengthened.length;
    final coolingCount = intel.coolingRelationships.length;

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
            children: [
              const Icon(
                Icons.trending_up_rounded,
                size: 15.0,
                color: RecallrColors.aiCyanHighlight,
              ),
              const SizedBox(width: 6.0),
              Expanded(
                child: Text(
                  'RELATIONSHIP MOMENTUM & EVOLUTION',
                  style: RecallrTypography.labelSmall.copyWith(
                    color: RecallrColors.textTertiary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(RecallrSpacing.sm),
                  decoration: BoxDecoration(
                    color: RecallrColors.slateSurface,
                    borderRadius: RecallrRadii.radiusSm,
                    border: Border.all(color: RecallrColors.borderSubtle, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_upward_rounded, size: 14.0, color: RecallrColors.emeraldVerified),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$strengthenedCount',
                              style: RecallrTypography.bodyLarge.copyWith(
                                color: RecallrColors.emeraldVerified,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.0,
                              ),
                            ),
                            Text(
                              'Strengthening',
                              style: RecallrTypography.labelSmall.copyWith(
                                color: RecallrColors.textSecondary,
                                fontSize: 9.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(RecallrSpacing.sm),
                  decoration: BoxDecoration(
                    color: RecallrColors.slateSurface,
                    borderRadius: RecallrRadii.radiusSm,
                    border: Border.all(color: RecallrColors.borderSubtle, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_downward_rounded, size: 14.0, color: RecallrColors.warmAmberGold),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$coolingCount',
                              style: RecallrTypography.bodyLarge.copyWith(
                                color: RecallrColors.warmAmberGold,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.0,
                              ),
                            ),
                            Text(
                              'Cooling / Decaying',
                              style: RecallrTypography.labelSmall.copyWith(
                                color: RecallrColors.textSecondary,
                                fontSize: 9.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionSection(List<RelationshipAttention> attentionList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.priority_high_rounded,
              size: 15.0,
              color: RecallrColors.warmAmberGold,
            ),
            const SizedBox(width: 6.0),
            Text(
              'PROACTIVE ATTENTION NEEDED',
              style: RecallrTypography.labelSmall.copyWith(
                color: RecallrColors.textTertiary,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        ...attentionList.map((att) => RelationshipAttentionCard(
              attention: att,
              onTap: () => Navigator.of(context).pushNamed('/person/${att.personId}'),
            )),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: RecallrSpacing.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.hub_outlined,
              size: 48.0,
              color: RecallrColors.textTertiary,
            ),
            RecallrSpacing.gapMd,
            Text(
              'Your Network Is Just Getting Started',
              style: RecallrTypography.titleMedium.copyWith(
                color: RecallrColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            RecallrSpacing.gapXs,
            Text(
              'Add people and log interactions to see your network health metrics and distribution.',
              style: RecallrTypography.bodyMedium.copyWith(
                color: RecallrColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            RecallrSpacing.gapLg,
            RecallrButton(
              label: 'Capture First Encounter',
              leadingIcon: Icons.add_rounded,
              onPressed: () => RecallrBottomSheet.show(
                context: context,
                child: const CaptureModal(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
