import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/di/recallr_dependencies.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../features/people/models/person_item.dart';
import '../../features/people/widgets/people_empty_state.dart';
import '../../features/people/widgets/people_filters.dart';
import '../../features/people/widgets/people_header.dart';
import '../../features/people/widgets/people_search.dart';
import '../../features/relationship_intelligence/models/models.dart';
import '../../repositories/people_repository.dart';
import '../capture/capture_modal.dart';

/// Phase 06 & Phase 13G: People / Relationship Directory Screen.
/// Cleanly wired to FirestorePeopleRepository without mock data fallbacks.
class PeopleScreen extends StatefulWidget {
  final List<PersonItem>? initialPeople;
  final RelationshipIntelligenceSnapshot? initialSnapshot;
  final bool isLoading;
  final bool isError;
  final bool isEmpty;
  final VoidCallback? onRetry;
  final PeopleRepository? repository;

  const PeopleScreen({
    super.key,
    this.initialPeople,
    this.initialSnapshot,
    this.isLoading = false,
    this.isError = false,
    this.isEmpty = false,
    this.onRetry,
    this.repository,
  });

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  late bool _isLoading;
  late bool _isError;
  late bool _isEmpty;
  late List<PersonItem> _allPeople;
  late TextEditingController _searchController;
  String _searchQuery = '';
  PeopleFilterOption _selectedFilter = PeopleFilterOption.all;
  PeopleSortOption _selectedSort = PeopleSortOption.recent;
  StreamSubscription<List<PersonItem>>? _peopleSubscription;
  StreamSubscription<List<PersonItem>>? _recentSubscription;
  StreamSubscription<RelationshipIntelligenceSnapshot>? _snapshotSubscription;
  RelationshipIntelligenceSnapshot? _snapshot;
  List<PersonItem> _recentlyInteracted = [];

  PeopleRepository get _repository =>
      widget.repository ??
      (mounted ? context.peopleRepo : RecallrDependencies.instance.peopleRepository);

  @override
  void initState() {
    super.initState();
    _isLoading = widget.isLoading ||
        (widget.initialPeople == null && !widget.isEmpty && !widget.isError);
    _isError = widget.isError;
    _isEmpty = widget.isEmpty;
    _allPeople = widget.initialPeople ?? [];
    _snapshot = widget.initialSnapshot;
    _searchController = TextEditingController();
    if (_allPeople.isNotEmpty) {
      _recentlyInteracted = _allPeople.take(3).toList();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.initialPeople == null && !widget.isEmpty && !widget.isLoading && !widget.isError) {
      _subscribeToPeople();
      _subscribeToRecent();
    }
    if (widget.initialSnapshot == null && !widget.isEmpty && !widget.isLoading && !widget.isError) {
      _subscribeToSnapshot();
    }
  }

  void _subscribeToPeople() {
    _peopleSubscription?.cancel();
    if (widget.initialPeople != null || widget.isEmpty || widget.isError) return;

    _peopleSubscription = _repository.streamPeople().listen(
      (people) {
        if (mounted) {
          setState(() {
            _allPeople = people;
            _isLoading = false;
            _isError = false;
            _isEmpty = people.isEmpty;
            if (_recentlyInteracted.isEmpty && people.isNotEmpty) {
              _recentlyInteracted = people.take(3).toList();
            }
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

  void _subscribeToRecent() {
    _recentSubscription?.cancel();
    if (widget.initialPeople != null || widget.isEmpty || widget.isError) return;

    _recentSubscription = _repository.streamRecentlyInteracted().listen(
      (recent) {
        if (mounted && recent.isNotEmpty) {
          setState(() {
            _recentlyInteracted = recent;
          });
        }
      },
      onError: (_) {},
    );
  }

  void _subscribeToSnapshot() {
    _snapshotSubscription?.cancel();
    if (widget.initialSnapshot != null || widget.isEmpty || widget.isError) return;

    final service = mounted
        ? context.unifiedRelationshipIntelligence
        : RecallrDependencies.instance.unifiedRelationshipIntelligenceService;

    _snapshotSubscription = service.streamSnapshot().listen(
      (snapshot) {
        if (mounted) {
          setState(() {
            _snapshot = snapshot;
          });
        }
      },
      onError: (_) {},
    );
  }

  @override
  void didUpdateWidget(covariant PeopleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading ||
        oldWidget.isError != widget.isError ||
        oldWidget.isEmpty != widget.isEmpty ||
        oldWidget.initialPeople != widget.initialPeople ||
        oldWidget.initialSnapshot != widget.initialSnapshot) {
      setState(() {
        _isLoading = widget.isLoading ||
            (widget.initialPeople == null && !widget.isEmpty && !widget.isError && _allPeople.isEmpty);
        _isError = widget.isError;
        _isEmpty = widget.isEmpty;
        if (widget.initialSnapshot != null) {
          _snapshot = widget.initialSnapshot;
        }
        if (widget.initialPeople != null) {
          _allPeople = widget.initialPeople!;
          _recentlyInteracted = _allPeople.take(3).toList();
        }
      });
      if (widget.initialPeople == null && !widget.isEmpty && !widget.isError) {
        _subscribeToPeople();
        _subscribeToRecent();
      }
      if (widget.initialSnapshot == null && !widget.isEmpty && !widget.isError) {
        _subscribeToSnapshot();
      }
    }
  }

  @override
  void dispose() {
    _snapshotSubscription?.cancel();
    _peopleSubscription?.cancel();
    _recentSubscription?.cancel();
    _searchController.dispose();
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
      _subscribeToPeople();
      _subscribeToRecent();
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim();
    });
  }

  void _onFilterChanged(PeopleFilterOption filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _clearFiltersAndSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedFilter = PeopleFilterOption.all;
    });
  }

  void _handleAddPerson() {
    RecallrBottomSheet.show(
      context: context,
      child: const CaptureModal(),
    );
  }

  Future<void> _handleDeletePerson(PersonItem person) async {
    try {
      await _repository.deletePerson(person.id);
      if (mounted) {
        setState(() {
          _allPeople.removeWhere((p) => p.id == person.id);
          _recentlyInteracted.removeWhere((p) => p.id == person.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${person.name} from directory'),
            backgroundColor: RecallrColors.slateSurface,
          ),
        );
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

  List<PersonItem> get _filteredPeople {
    final list = _allPeople.where((person) {
      if (!_selectedFilter.matches(person)) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = person.name.toLowerCase().contains(query);
        final matchesCompany = person.company.toLowerCase().contains(query);
        final matchesRole = person.role.toLowerCase().contains(query);
        final matchesPhone = person.phone?.toLowerCase().contains(query) ?? false;
        final matchesEmail = person.email?.toLowerCase().contains(query) ?? false;
        final matchesContext = person.contextSnippet?.toLowerCase().contains(query) ?? false;
        final matchesCapabilities = person.capabilities.any((c) => c.toLowerCase().contains(query));

        if (!matchesName &&
            !matchesCompany &&
            !matchesRole &&
            !matchesPhone &&
            !matchesEmail &&
            !matchesContext &&
            !matchesCapabilities) {
          return false;
        }
      }
      return true;
    }).toList();

    switch (_selectedSort) {
      case PeopleSortOption.recent:
        list.sort((a, b) {
          final aDate = a.lastInteractionDate ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.lastInteractionDate ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
        break;
      case PeopleSortOption.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case PeopleSortOption.nameDesc:
        list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case PeopleSortOption.interactions:
        list.sort((a, b) => b.interactionCount.compareTo(a.interactionCount));
        break;
    }

    return list;
  }

  // ─── Category helpers ─────────────────────────────────────────────────────

  int _countByRelationshipType(RelationshipContextType type) =>
      _allPeople.where((p) => p.relationshipType == type).length;

  int _countByRole(String keyword) =>
      _allPeople.where((p) => p.role.toLowerCase().contains(keyword.toLowerCase())).length;

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: RecallrSpacing.pagePadding,
            child: RecallrErrorState(
              message: "We couldn't load your people directory. Please check your connection and try again.",
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

    if (_isEmpty || (_allPeople.isEmpty && widget.initialPeople == null)) {
      return Scaffold(
        body: PeopleEmptyState(
          isSearch: _searchQuery.isNotEmpty || _selectedFilter != PeopleFilterOption.all,
          searchQuery: _searchQuery,
          onClearSearch: _clearFiltersAndSearch,
        ),
      );
    }

    final filtered = _filteredPeople;

    return Scaffold(
      backgroundColor: RecallrColors.obsidianBase,
      appBar: AppBar(
        backgroundColor: RecallrColors.obsidianBase,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: RecallrColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'People',
          style: RecallrTypography.titleMedium,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: RecallrColors.textSecondary, size: 22),
            onPressed: () {},
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: RecallrColors.aiElectricViolet, size: 24),
            onPressed: _handleAddPerson,
            tooltip: 'Add person',
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: RecallrColors.borderSubtle),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Categories Grid ──────────────────────────────────────────────
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Organize your people and relationships.',
                    style: RecallrTypography.bodyMedium.copyWith(
                      color: RecallrColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.4,
                    children: [
                      _CategoryCard(
                        label: 'Friends',
                        icon: Icons.people_outline_rounded,
                        iconBgColor: const Color(0xFF2D1B8E).withValues(alpha: 0.4),
                        iconColor: const Color(0xFF7C6AF0),
                        count: _countByRelationshipType(RelationshipContextType.collaborator),
                        onTap: () {
                          final newQuery = _searchQuery == 'Friends' ? '' : 'Friends';
                          _searchController.text = newQuery;
                          _onSearchChanged(newQuery);
                        },
                      ),
                      _CategoryCard(
                        label: 'Work',
                        icon: Icons.work_outline_rounded,
                        iconBgColor: const Color(0xFF0D3D30).withValues(alpha: 0.5),
                        iconColor: RecallrColors.emeraldVerified,
                        count: _countByRelationshipType(RelationshipContextType.colleague),
                        onTap: () {
                          final newQuery = _searchQuery == 'Work' ? '' : 'Work';
                          _searchController.text = newQuery;
                          _onSearchChanged(newQuery);
                        },
                      ),
                      _CategoryCard(
                        label: 'College',
                        icon: Icons.school_outlined,
                        iconBgColor: const Color(0xFF0D2A3D).withValues(alpha: 0.5),
                        iconColor: const Color(0xFF38BDF8),
                        count: _countByRole('student') + _countByRole('classmate'),
                        onTap: () {
                          final newQuery = _searchQuery == 'College' ? '' : 'College';
                          _searchController.text = newQuery;
                          _onSearchChanged(newQuery);
                        },
                      ),
                      _CategoryCard(
                        label: 'Family',
                        icon: Icons.favorite_outline_rounded,
                        iconBgColor: const Color(0xFF3D0D1E).withValues(alpha: 0.5),
                        iconColor: const Color(0xFFE879A0),
                        count: _countByRole('family') + _countByRole('relative'),
                        onTap: () {
                          final newQuery = _searchQuery == 'Family' ? '' : 'Family';
                          _searchController.text = newQuery;
                          _onSearchChanged(newQuery);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.expand_more_rounded,
                      size: 18,
                      color: RecallrColors.aiElectricViolet,
                    ),
                    label: const Text(
                      'Show more categories',
                      style: TextStyle(
                        color: RecallrColors.aiElectricViolet,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(color: RecallrColors.borderSubtle, thickness: 1, height: 1),
            const SizedBox(height: 20),

            // ── People Grid ──────────────────────────────────────────────────
            if (_allPeople.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search bar
                    PeopleSearch(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onClear: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    ),
                    const SizedBox(height: 10),
                    PeopleFilters(
                      selectedFilter: _selectedFilter,
                      onSelected: _onFilterChanged,
                    ),
                    const SizedBox(height: 12),
                    // Count + Sort row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${filtered.length} people',
                          style: RecallrTypography.bodyMedium.copyWith(
                            color: RecallrColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                        _buildSortMenuButton(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      PeopleEmptyState(
                        isSearch: true,
                        searchQuery: _searchQuery,
                        onClearSearch: _clearFiltersAndSearch,
                      )
                    else
                      GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 0.82,
                        children: filtered.map((p) => _PersonGridCard(
                          person: p,
                          intelligence: (_snapshot ?? widget.initialSnapshot)?.getPerson(p.id),
                          onTap: () => Navigator.of(context).pushNamed('/person/${p.id}'),
                          onDelete: () => _handleDeletePerson(p),
                        )).toList(),
                      ),
                  ],
                ),
              ),

            // ── Add People Row ───────────────────────────────────────────────
            _buildAddPeopleRow(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSortMenuButton() {
    return PopupMenuButton<PeopleSortOption>(
      initialValue: _selectedSort,
      onSelected: (opt) => setState(() => _selectedSort = opt),
      color: RecallrColors.charcoalCard,
      tooltip: 'Sort contacts',
      shape: RoundedRectangleBorder(
        borderRadius: RecallrRadii.radiusMd,
        side: const BorderSide(color: RecallrColors.borderSubtle),
      ),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: RecallrColors.slateSurface,
          borderRadius: RecallrRadii.radiusMd,
          border: Border.all(color: RecallrColors.borderSubtle, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_vert_rounded, size: 14, color: RecallrColors.textTertiary),
            const SizedBox(width: 4),
            Text(
              _selectedSort.label,
              style: RecallrTypography.bodyMedium.copyWith(
                color: RecallrColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down_rounded, size: 16, color: RecallrColors.textTertiary),
          ],
        ),
      ),
      itemBuilder: (context) => PeopleSortOption.values.map((opt) {
        final isSelected = opt == _selectedSort;
        return PopupMenuItem<PeopleSortOption>(
          value: opt,
          child: Row(
            children: [
              Icon(opt.icon, size: 16, color: isSelected ? RecallrColors.aiElectricViolet : RecallrColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                opt.label,
                style: RecallrTypography.bodyMedium.copyWith(
                  color: isSelected ? RecallrColors.aiElectricViolet : RecallrColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddPeopleRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: _handleAddPerson,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: RecallrColors.charcoalCard,
            borderRadius: RecallrRadii.radiusLg,
            border: Border.all(color: RecallrColors.borderSubtle, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: RecallrColors.aiElectricViolet.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: RecallrColors.aiElectricViolet,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add people',
                      style: RecallrTypography.bodyMedium.copyWith(
                        color: RecallrColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manually, with AI, via QR, or by scanning a business card.',
                      style: RecallrTypography.bodyMedium.copyWith(
                        color: RecallrColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: RecallrColors.textTertiary, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: RecallrSpacing.pagePadding,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const RecallrSkeleton(height: 32.0, width: 220.0),
        RecallrSpacing.gapSm,
        const RecallrSkeleton(height: 16.0, width: 280.0),
        RecallrSpacing.gapLg,
        const RecallrSkeleton(height: 48.0),
        RecallrSpacing.gapLg,
        const RecallrSkeleton(height: 36.0),
        RecallrSpacing.gapLg,
        const RecallrSkeleton(height: 120.0),
        RecallrSpacing.gapLg,
        const RecallrSkeleton(height: 120.0),
        RecallrSpacing.gapLg,
        const RecallrSkeleton(height: 120.0),
      ],
    );
  }
}

// ─── Category Card ──────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final int count;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.label,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: RecallrColors.charcoalCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: RecallrColors.borderSubtle, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: RecallrTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: RecallrColors.textPrimary,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '$count people',
              style: RecallrTypography.bodyMedium.copyWith(
                color: RecallrColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Person Grid Card ────────────────────────────────────────────────────────

class _PersonGridCard extends StatelessWidget {
  final PersonItem person;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final UnifiedPersonRelationshipIntelligence? intelligence;

  const _PersonGridCard({
    required this.person,
    required this.onTap,
    this.onDelete,
    this.intelligence,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = person.role.isNotEmpty ? person.role : (person.relationshipType?.name ?? '');

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete != null
          ? () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: RecallrColors.slateSurface,
                  title: Text('Delete ${person.name}?', style: RecallrTypography.titleMedium),
                  content: const Text(
                    'Are you sure you want to remove this person from your memory directory?',
                    style: RecallrTypography.bodyMedium,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel', style: TextStyle(color: RecallrColors.textSecondary)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onDelete?.call();
                      },
                      child: const Text('Delete', style: TextStyle(color: RecallrColors.crimsonAlert)),
                    ),
                  ],
                ),
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: RecallrColors.charcoalCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: RecallrColors.borderSubtle, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RecallrAvatar(
              imageUrl: person.avatarUrl,
              initials: person.initials,
              size: RecallrAvatarSize.lg,
            ),
            const SizedBox(height: 8),
            Text(
              person.name,
              style: RecallrTypography.bodyMedium.copyWith(
                color: RecallrColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: RecallrTypography.bodyMedium.copyWith(
                  color: RecallrColors.textTertiary,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (person.company.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.business_outlined, size: 12, color: RecallrColors.textTertiary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      person.company,
                      style: RecallrTypography.bodyMedium.copyWith(
                        color: RecallrColors.textTertiary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (person.lastInteraction != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 12, color: RecallrColors.textTertiary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      person.lastInteraction!,
                      style: RecallrTypography.bodyMedium.copyWith(
                        color: RecallrColors.textTertiary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
