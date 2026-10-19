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
import '../../features/people/widgets/person_card.dart';
import '../../features/people/widgets/recently_interacted.dart';
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 768;
          final double maxWidth = constraints.maxWidth > 1100 ? 1040 : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: isWide ? _buildWideLayout(filtered) : _buildMobileLayout(filtered),
            ),
          );
        },
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
        height: 44.0,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        decoration: BoxDecoration(
          color: RecallrColors.slateSurface,
          borderRadius: RecallrRadii.radiusMd,
          border: Border.all(color: RecallrColors.borderSubtle, width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_selectedSort.icon, size: 16.0, color: RecallrColors.aiCyanHighlight),
            const SizedBox(width: 6.0),
            Text(
              _selectedSort.label,
              style: RecallrTypography.labelSmall.copyWith(
                color: RecallrColors.textSecondary,
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4.0),
            const Icon(Icons.arrow_drop_down_rounded, size: 18.0, color: RecallrColors.textTertiary),
          ],
        ),
      ),
      itemBuilder: (context) => PeopleSortOption.values.map((opt) {
        final isSelected = opt == _selectedSort;
        return PopupMenuItem<PeopleSortOption>(
          value: opt,
          child: Row(
            children: [
              Icon(opt.icon, size: 16.0, color: isSelected ? RecallrColors.aiCyanHighlight : RecallrColors.textSecondary),
              const SizedBox(width: 8.0),
              Text(
                opt.label,
                style: RecallrTypography.bodyMedium.copyWith(
                  color: isSelected ? RecallrColors.aiCyanHighlight : RecallrColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMobileLayout(List<PersonItem> filtered) {
    final bool hasFilterOrSearch = _searchQuery.isNotEmpty || _selectedFilter != PeopleFilterOption.all;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PeopleHeader(
            count: filtered.length,
            onAddPerson: _handleAddPerson,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: PeopleSearch(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onClear: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  ),
                ),
                const SizedBox(width: 8.0),
                _buildSortMenuButton(),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: PeopleFilters(
              selectedFilter: _selectedFilter,
              onSelected: _onFilterChanged,
            ),
          ),
        ),
        if (hasFilterOrSearch)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text(
                'Showing ${filtered.length} of ${_allPeople.length} contacts',
                style: RecallrTypography.monoMetadata.copyWith(
                  color: RecallrColors.textTertiary,
                  fontSize: 11.0,
                ),
              ),
            ),
          ),
        if (_recentlyInteracted.isNotEmpty && _searchQuery.isEmpty && _selectedFilter == PeopleFilterOption.all)
          SliverToBoxAdapter(
            child: RecentlyInteractedSection(
              items: _recentlyInteracted,
            ),
          ),
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: PeopleEmptyState(
              isSearch: true,
              searchQuery: _searchQuery,
              onClearSearch: _clearFiltersAndSearch,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final person = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: PersonCard(
                      person: person,
                      intelligence: (_snapshot ?? widget.initialSnapshot)?.getPerson(person.id),
                      onDelete: () => _handleDeletePerson(person),
                    ),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 80.0),
        ),
      ],
    );
  }

  Widget _buildWideLayout(List<PersonItem> filtered) {
    final bool hasFilterOrSearch = _searchQuery.isNotEmpty || _selectedFilter != PeopleFilterOption.all;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PeopleHeader(
            count: filtered.length,
            onAddPerson: _handleAddPerson,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: PeopleSearch(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onClear: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  ),
                ),
                const SizedBox(width: 8.0),
                _buildSortMenuButton(),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: PeopleFilters(
              selectedFilter: _selectedFilter,
              onSelected: _onFilterChanged,
            ),
          ),
        ),
        if (hasFilterOrSearch)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text(
                'Showing ${filtered.length} of ${_allPeople.length} contacts',
                style: RecallrTypography.monoMetadata.copyWith(
                  color: RecallrColors.textTertiary,
                  fontSize: 11.0,
                ),
              ),
            ),
          ),
        if (_recentlyInteracted.isNotEmpty && _searchQuery.isEmpty && _selectedFilter == PeopleFilterOption.all)
          SliverToBoxAdapter(
            child: RecentlyInteractedSection(
              items: _recentlyInteracted,
            ),
          ),
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: PeopleEmptyState(
              isSearch: true,
              searchQuery: _searchQuery,
              onClearSearch: _clearFiltersAndSearch,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final person = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: PersonCard(
                      person: person,
                      intelligence: (_snapshot ?? widget.initialSnapshot)?.getPerson(person.id),
                      onDelete: () => _handleDeletePerson(person),
                    ),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 80.0),
        ),
      ],
    );
  }
}