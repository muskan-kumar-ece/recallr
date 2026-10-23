import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/di/recallr_dependencies.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/share_formatter.dart';
import '../../core/widgets/destructive_confirm_dialog.dart';
import '../../core/widgets/share_bottom_sheet.dart';
import '../../core/widgets/widgets.dart';
import '../../features/activity/models/activity_models.dart';
import '../../features/activity/widgets/activity_detail_context.dart';
import '../../features/activity/widgets/activity_empty_state.dart';
import '../../features/activity/widgets/activity_filters.dart';
import '../../features/activity/widgets/activity_header.dart';
import '../../features/activity/widgets/activity_loading_state.dart';
import '../../features/activity/widgets/activity_search.dart';
import '../../features/activity/widgets/activity_timeline.dart';
import '../../repositories/activity_repository.dart';
import '../capture/capture_modal.dart';

/// Recallr Phase 09 & Phase 13G: Activity / Relationship Timeline.
/// Cleanly wired to FirestoreActivityRepository without mock data fallbacks.
class ActivityScreen extends StatefulWidget {
  final bool isLoading;
  final bool isEmpty;
  final bool isError;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onCapture;
  final ActivityRepository? repository;
  final List<ActivityItem>? initialActivities;

  const ActivityScreen({
    super.key,
    this.isLoading = false,
    this.isEmpty = false,
    this.isError = false,
    this.errorMessage,
    this.onRetry,
    this.onCapture,
    this.repository,
    this.initialActivities,
  });

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  late TextEditingController _searchController;
  late List<ActivityItem> _allActivities;
  ActivityFilter _selectedFilter = ActivityFilter.all;
  String _searchQuery = '';
  String? _selectedActivityId;
  late bool _isLoading;
  late bool _isError;
  late bool _isEmpty;
  StreamSubscription<List<ActivityItem>>? _activitySubscription;

  ActivityRepository get _repository =>
      widget.repository ??
      (mounted ? context.activityRepo : RecallrDependencies.instance.activityRepository);

  @override
  void initState() {
    super.initState();
    _isLoading = widget.isLoading ||
        (widget.initialActivities == null && !widget.isEmpty && !widget.isError);
    _isError = widget.isError;
    _isEmpty = widget.isEmpty;
    _searchController = TextEditingController();
    _allActivities = widget.initialActivities ?? [];
    if (_allActivities.isNotEmpty) {
      _selectedActivityId = _allActivities.first.id;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.initialActivities == null && !widget.isEmpty && !widget.isLoading && !widget.isError) {
      _subscribeToActivities();
    }
  }

  void _subscribeToActivities() {
    _activitySubscription?.cancel();
    if (widget.initialActivities != null || widget.isEmpty || widget.isError) return;

    _activitySubscription = _repository.streamActivities().listen(
      (list) {
        if (mounted) {
          setState(() {
            _allActivities = list;
            _isLoading = false;
            _isError = false;
            _isEmpty = list.isEmpty;
            if (_allActivities.isNotEmpty &&
                (_selectedActivityId == null || !_allActivities.any((a) => a.id == _selectedActivityId))) {
              _selectedActivityId = _allActivities.first.id;
            } else if (_allActivities.isEmpty) {
              _selectedActivityId = null;
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

  @override
  void didUpdateWidget(covariant ActivityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading ||
        oldWidget.isError != widget.isError ||
        oldWidget.isEmpty != widget.isEmpty ||
        oldWidget.initialActivities != widget.initialActivities) {
      setState(() {
        _isLoading = widget.isLoading ||
            (widget.initialActivities == null && !widget.isEmpty && !widget.isError && _allActivities.isEmpty);
        _isError = widget.isError;
        _isEmpty = widget.isEmpty;
        if (widget.initialActivities != null) {
          _allActivities = widget.initialActivities!;
          if (_allActivities.isNotEmpty) {
            _selectedActivityId = _allActivities.first.id;
          }
        }
      });
      if (widget.initialActivities == null && !widget.isEmpty && !widget.isError) {
        _subscribeToActivities();
      }
    }
  }

  @override
  void dispose() {
    _activitySubscription?.cancel();
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
      _subscribeToActivities();
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim();
    });
  }

  void _onFilterSelected(ActivityFilter filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _onActivitySelected(ActivityItem activity) {
    setState(() {
      _selectedActivityId = activity.id;
    });
  }

  void _handleCaptureAction() {
    if (widget.onCapture != null) {
      widget.onCapture!();
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const CaptureModal(),
      );
    }
  }

  List<ActivityItem> get _filteredActivities {
    return _allActivities.where((activity) {
      if (!_selectedFilter.matches(activity.type)) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = activity.title.toLowerCase().contains(query);
        final matchesSummary = activity.summary.toLowerCase().contains(query);
        final matchesPerson = activity.personName?.toLowerCase().contains(query) ?? false;
        final matchesCompany = activity.companyName?.toLowerCase().contains(query) ?? false;
        final matchesLocation = activity.location?.toLowerCase().contains(query) ?? false;

        if (!matchesTitle &&
            !matchesSummary &&
            !matchesPerson &&
            !matchesCompany &&
            !matchesLocation) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  ActivityItem? get _selectedActivity {
    if (_selectedActivityId == null || _allActivities.isEmpty) return null;
    try {
      return _allActivities.firstWhere((a) => a.id == _selectedActivityId);
    } catch (_) {
      return _allActivities.first;
    }
  }

  void _handleShareActivity(ActivityItem activity) {
    final note = ShareFormatter.formatActivityNote(activity);
    ShareBottomSheet.show(
      context,
      title: 'Share Encounter Note',
      subtitle: activity.title,
      textSummary: note,
      shareSubject: 'Encounter Note: ${activity.title}',
    );
  }

  Future<void> _handleDeleteActivity(ActivityItem activity) async {
    final confirmed = await DestructiveConfirmDialog.show(
      context,
      title: 'Delete Activity Record',
      message: 'Are you sure you want to remove "${activity.title}" from your chronological timeline?',
      confirmLabel: 'Delete Activity',
    );

    if (confirmed && mounted) {
      final repo = widget.repository ?? (mounted ? context.activityRepo : RecallrDependencies.instance.activityRepository);
      try {
        await repo.deleteActivity(activity.id);
        if (mounted) {
          setState(() {
            _allActivities.removeWhere((a) => a.id == activity.id);
            if (_selectedActivityId == activity.id) {
              _selectedActivityId = _allActivities.isNotEmpty ? _allActivities.first.id : null;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed "${activity.title}"'),
              backgroundColor: RecallrColors.slateSurface,
              action: SnackBarAction(
                label: 'Undo',
                textColor: RecallrColors.aiCyanHighlight,
                onPressed: () async {
                  await repo.addActivity(activity);
                  if (mounted) {
                    setState(() {
                      _allActivities.add(activity);
                      _allActivities.sort((a, b) {
                        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                        return bDate.compareTo(aDate);
                      });
                    });
                  }
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete activity: $e'),
              backgroundColor: RecallrColors.crimsonAlert,
            ),
          );
        }
      }
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
              message: widget.errorMessage ??
                  "We couldn't load your activity timeline. Please check your connection and try again.",
              onRetry: _handleRetry,
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        body: ActivityLoadingState(),
      );
    }

    if (_isEmpty || (_allActivities.isEmpty && widget.initialActivities == null)) {
      return Scaffold(
        body: ActivityEmptyState(
          isSearchEmpty: _searchQuery.isNotEmpty || _selectedFilter != ActivityFilter.all,
          onClearSearch: () {
            _searchController.clear();
            setState(() {
              _searchQuery = '';
              _selectedFilter = ActivityFilter.all;
            });
          },
          onCapture: _handleCaptureAction,
        ),
      );
    }

    final filtered = _filteredActivities;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1024;
          final double maxWidth = constraints.maxWidth > 1100 ? 1040 : double.infinity;

          if (isDesktop && _selectedActivity != null) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildTimelineScrollable(filtered),
                    ),
                    const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: RecallrColors.borderSubtle,
                    ),
                    Expanded(
                      flex: 4,
                      child: ActivityDetailContext(
                        activity: _selectedActivity!,
                        onTapPerson: _selectedActivity!.personId != null
                            ? () => Navigator.pushNamed(context, '/person/${_selectedActivity!.personId}')
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: _buildTimelineScrollable(filtered),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineScrollable(List<ActivityItem> filtered) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: ActivityHeader(),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ActivitySearch(
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
            child: ActivityFilters(
              selectedFilter: _selectedFilter,
              onFilterSelected: _onFilterSelected,
            ),
          ),
        ),
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: ActivityEmptyState(
              isSearchEmpty: true,
              onClearSearch: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedFilter = ActivityFilter.all;
                });
              },
              onCapture: _handleCaptureAction,
            ),
          )
        else
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80.0),
              child: ActivityTimeline(
                activities: filtered,
                selectedActivityId: _selectedActivityId,
                onTapActivity: _onActivitySelected,
                onShareActivity: _handleShareActivity,
                onDeleteActivity: _handleDeleteActivity,
              ),
            ),
          ),
      ],
    );
  }
}