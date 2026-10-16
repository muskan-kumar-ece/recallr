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

  List<PersonItem> get _filteredPeople {
    return _allPeople.where((person) {
      if (!_selectedFilter.matches(person)) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = person.name.toLowerCase().contains(query);
        final matchesCompany = person.company.toLowerCase().contains(query);
        final matchesRole = person.role.toLowerCase().contains(query);
        final matchesContext = person.contextSnippet?.toLowerCase().contains(query) ?? false;
        final matchesCapabilities = person.capabilities.any((c) => c.toLowerCase().contains(query));

        if (!matchesName &&
            !matchesCompany &&
            !matchesRole &&
            !matchesContext &&
            !matchesCapabilities) {
          return false;
        }
      }
      return true;
    }).toList();
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

  Widget _buildMobileLayout(List<PersonItem> filtered) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PeopleHeader(
            count: filtered.length,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: PeopleSearch(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onClear: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: PeopleFilters(
              selectedFilter: _selectedFilter,
              onSelected: _onFilterChanged,
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
                      intelligence: widget.initialSnapshot?.getPerson(person.id),
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
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PeopleHeader(
            count: filtered.length,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: PeopleSearch(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onClear: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: PeopleFilters(
              selectedFilter: _selectedFilter,
              onSelected: _onFilterChanged,
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