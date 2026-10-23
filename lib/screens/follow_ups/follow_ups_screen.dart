import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/di/recallr_dependencies.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/share_formatter.dart';
import '../../core/widgets/destructive_confirm_dialog.dart';
import '../../core/widgets/share_bottom_sheet.dart';
import '../../core/widgets/widgets.dart';
import '../../features/follow_ups/models/follow_up_models.dart';
import '../../features/follow_ups/widgets/follow_up_detail_context.dart';
import '../../features/follow_ups/widgets/follow_up_empty_state.dart';
import '../../features/follow_ups/widgets/follow_up_filters.dart';
import '../../features/follow_ups/widgets/follow_up_group.dart';
import '../../features/follow_ups/widgets/follow_up_header.dart';
import '../../features/follow_ups/widgets/follow_up_loading_state.dart';
import '../../features/follow_ups/widgets/follow_up_search.dart';
import '../../features/follow_ups/widgets/follow_up_summary.dart';
import '../../repositories/follow_up_repository.dart';
import '../capture/capture_modal.dart';

/// Phase 10 & Phase 13G: Follow-ups / Relationship Commitments Screen.
/// Cleanly wired to FirestoreFollowUpRepository without mock data fallbacks.
class FollowUpsScreen extends StatefulWidget {
  final bool isLoading;
  final bool isEmpty;
  final bool isError;
  final String? errorMessage;
  final String? initialFollowUpId;
  final VoidCallback? onRetry;
  final VoidCallback? onCapture;
  final FollowUpRepository? repository;
  final List<FollowUpItem>? initialFollowUps;

  const FollowUpsScreen({
    super.key,
    this.isLoading = false,
    this.isEmpty = false,
    this.isError = false,
    this.errorMessage,
    this.initialFollowUpId,
    this.onRetry,
    this.onCapture,
    this.repository,
    this.initialFollowUps,
  });

  @override
  State<FollowUpsScreen> createState() => _FollowUpsScreenState();
}

class _FollowUpsScreenState extends State<FollowUpsScreen> {
  late TextEditingController _searchController;
  late List<FollowUpItem> _allFollowUps;
  FollowUpFilter _selectedFilter = FollowUpFilter.all;
  String _searchQuery = '';
  FollowUpItem? _selectedFollowUp;
  late bool _isLoading;
  late bool _isError;
  late bool _isEmpty;
  StreamSubscription<List<FollowUpItem>>? _followUpSubscription;

  FollowUpRepository get _repository =>
      widget.repository ??
      (mounted ? context.followUpRepo : RecallrDependencies.instance.followUpRepository);

  FollowUpSummaryStats get _stats => FollowUpSummaryStats.fromItems(_allFollowUps);

  @override
  void initState() {
    super.initState();
    _isLoading = widget.isLoading ||
        (widget.initialFollowUps == null && !widget.isEmpty && !widget.isError);
    _isError = widget.isError;
    _isEmpty = widget.isEmpty;
    _searchController = TextEditingController();
    _allFollowUps = widget.initialFollowUps ?? [];
    if (_allFollowUps.isNotEmpty) {
      if (widget.initialFollowUpId != null) {
        _selectedFollowUp = _allFollowUps.firstWhere(
          (f) => f.id == widget.initialFollowUpId,
          orElse: () => _allFollowUps.first,
        );
      } else {
        _selectedFollowUp = _allFollowUps.first;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.initialFollowUps == null && !widget.isEmpty && !widget.isLoading && !widget.isError) {
      _subscribeToFollowUps();
    }
  }

  void _subscribeToFollowUps() {
    _followUpSubscription?.cancel();
    if (widget.initialFollowUps != null || widget.isEmpty || widget.isError) return;

    _followUpSubscription = _repository.streamFollowUps().listen(
      (list) {
        if (mounted) {
          setState(() {
            _allFollowUps = list;
            _isLoading = false;
            _isError = false;
            _isEmpty = list.isEmpty;
            if (_allFollowUps.isNotEmpty) {
              if (widget.initialFollowUpId != null && _selectedFollowUp == null) {
                _selectedFollowUp = _allFollowUps.firstWhere(
                  (f) => f.id == widget.initialFollowUpId,
                  orElse: () => _allFollowUps.first,
                );
              } else if (_selectedFollowUp == null || !_allFollowUps.any((f) => f.id == _selectedFollowUp!.id)) {
                _selectedFollowUp = _allFollowUps.first;
              }
            } else {
              _selectedFollowUp = null;
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
  void didUpdateWidget(covariant FollowUpsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading ||
        oldWidget.isError != widget.isError ||
        oldWidget.isEmpty != widget.isEmpty ||
        oldWidget.initialFollowUps != widget.initialFollowUps) {
      setState(() {
        _isLoading = widget.isLoading ||
            (widget.initialFollowUps == null && !widget.isEmpty && !widget.isError && _allFollowUps.isEmpty);
        _isError = widget.isError;
        _isEmpty = widget.isEmpty;
        if (widget.initialFollowUps != null) {
          _allFollowUps = widget.initialFollowUps!;
          if (_allFollowUps.isNotEmpty) {
            _selectedFollowUp = _allFollowUps.first;
          }
        }
      });
      if (widget.initialFollowUps == null && !widget.isEmpty && !widget.isError) {
        _subscribeToFollowUps();
      }
    }
  }

  @override
  void dispose() {
    _followUpSubscription?.cancel();
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
      _subscribeToFollowUps();
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim();
    });
  }

  void _onFilterChanged(FollowUpFilter filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _onFollowUpSelected(FollowUpItem item) {
    setState(() {
      _selectedFollowUp = item;
    });
  }

  void _navigateToPerson(String personId) {
    Navigator.pushNamed(context, '/person/$personId');
  }

  void _navigateToSource(FollowUpItem item) {
    if (item.sourceInteractionId != null) {
      Navigator.pushNamed(context, '/interaction/${item.sourceInteractionId}');
    } else if (item.targetRoute != '/follow-ups' &&
        item.targetRoute != '/follow-up' &&
        !item.targetRoute.startsWith('/follow-up/')) {
      Navigator.pushNamed(context, item.targetRoute);
    }
  }

  Future<void> _onToggleStatus(String id, bool completed) async {
    try {
      await _repository.toggleComplete(id, completed);
      if (!mounted) return;
      setState(() {
        final index = _allFollowUps.indexWhere((f) => f.id == id);
        if (index != -1) {
          final current = _allFollowUps[index];
          final updated = current.copyWith(
            isCompleted: completed,
            status: completed ? FollowUpStatus.completed : FollowUpStatus.upcoming,
          );
          _allFollowUps[index] = updated;
          if (_selectedFollowUp?.id == id) {
            _selectedFollowUp = updated;
          }
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to update follow-up status. Please check your connection.'),
            backgroundColor: RecallrColors.crimsonAlert,
          ),
        );
      }
    }
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

  List<FollowUpItem> get _filteredFollowUps {
    return _allFollowUps.where((item) {
      if (!_selectedFilter.matches(item)) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = item.title.toLowerCase().contains(query);
        final matchesContext = item.context.toLowerCase().contains(query);
        final matchesPerson = item.personName?.toLowerCase().contains(query) ?? false;
        final matchesCompany = item.companyName?.toLowerCase().contains(query) ?? false;

        if (!matchesTitle && !matchesContext && !matchesPerson && !matchesCompany) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _handleShareFollowUp(FollowUpItem item) {
    final text = ShareFormatter.formatFollowUp(item);
    ShareBottomSheet.show(
      context,
      title: 'Share Commitment',
      subtitle: item.title,
      textSummary: text,
      shareSubject: 'Commitment: ${item.title}',
    );
  }

  Future<void> _handleDeleteFollowUp(FollowUpItem item) async {
    final confirmed = await DestructiveConfirmDialog.show(
      context,
      title: 'Delete Follow-up Commitment',
      message: 'Are you sure you want to delete "${item.title}"? This commitment will be removed from your active list.',
      confirmLabel: 'Delete Commitment',
    );

    if (confirmed && mounted) {
      try {
        await _repository.deleteFollowUp(item.id);
        if (mounted) {
          setState(() {
            _allFollowUps.removeWhere((f) => f.id == item.id);
            if (_selectedFollowUp?.id == item.id) {
              _selectedFollowUp = _allFollowUps.isNotEmpty ? _allFollowUps.first : null;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed "${item.title}"'),
              backgroundColor: RecallrColors.slateSurface,
              action: SnackBarAction(
                label: 'Undo',
                textColor: RecallrColors.aiCyanHighlight,
                onPressed: () async {
                  await _repository.addFollowUp(item);
                  if (mounted) {
                    setState(() {
                      _allFollowUps.add(item);
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
              content: Text('Failed to delete commitment: $e'),
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
                  "We couldn't load your follow-ups. Please check your connection and try again.",
              onRetry: _handleRetry,
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        body: FollowUpLoadingState(),
      );
    }

    if (_isEmpty || (_allFollowUps.isEmpty && widget.initialFollowUps == null)) {
      return Scaffold(
        body: FollowUpEmptyState(
          isSearchEmpty: _searchQuery.isNotEmpty || _selectedFilter != FollowUpFilter.all,
          onClearSearch: () {
            _searchController.clear();
            setState(() {
              _searchQuery = '';
              _selectedFilter = FollowUpFilter.all;
            });
          },
          onCapture: _handleCaptureAction,
        ),
      );
    }

    final filtered = _filteredFollowUps;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 768;
          final double maxWidth = constraints.maxWidth > 1100 ? 1040 : double.infinity;

          if (isWide && filtered.isNotEmpty) {
            final activeItem = filtered.contains(_selectedFollowUp)
                ? _selectedFollowUp!
                : filtered.first;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildFollowUpsScrollable(filtered),
                    ),
                    const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: RecallrColors.borderSubtle,
                    ),
                    Expanded(
                      flex: 4,
                      child: FollowUpDetailContext(
                        item: activeItem,
                        onToggleComplete: () => _onToggleStatus(activeItem.id, !activeItem.isCompleted),
                        onTapPerson: activeItem.personId != null
                            ? () => Navigator.pushNamed(context, '/person/${activeItem.personId}')
                            : null,
                        onTapSource: activeItem.sourceInteractionId != null
                            ? () => Navigator.pushNamed(context, '/interaction/${activeItem.sourceInteractionId}')
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
              child: _buildFollowUpsScrollable(filtered),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFollowUpsScrollable(List<FollowUpItem> filtered) {
    final todayItems = filtered.where((f) => f.status == FollowUpStatus.dueToday && !f.isCompleted).toList();
    final overdueItems = filtered.where((f) => (f.status == FollowUpStatus.overdue || f.commitmentType == CommitmentType.overdue) && !f.isCompleted).toList();
    final upcomingItems = filtered.where((f) => f.status == FollowUpStatus.upcoming && !f.isCompleted).toList();
    final waitingItems = filtered.where((f) => f.status == FollowUpStatus.waiting && !f.isCompleted).toList();
    final completedItems = filtered.where((f) => f.isCompleted).toList();

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: FollowUpHeader(),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: FollowUpSummary(
              stats: _stats,
              selectedFilter: _selectedFilter,
              onFilterSelected: _onFilterChanged,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: FollowUpSearch(
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
            child: FollowUpFilters(
              selectedFilter: _selectedFilter,
              onFilterSelected: _onFilterChanged,
            ),
          ),
        ),
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: FollowUpEmptyState(
              isSearchEmpty: true,
              onClearSearch: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedFilter = FollowUpFilter.all;
                });
              },
              onCapture: _handleCaptureAction,
            ),
          )
        else ...[
          if (todayItems.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: FollowUpGroup(
                  title: 'DUE TODAY',
                  items: todayItems,
                  selectedFollowUpId: _selectedFollowUp?.id,
                  onTapFollowUp: _onFollowUpSelected,
                  onTapPerson: _navigateToPerson,
                  onTapSource: _navigateToSource,
                  onShareFollowUp: _handleShareFollowUp,
                  onDeleteFollowUp: _handleDeleteFollowUp,
                  onToggleComplete: (item) => _onToggleStatus(item.id, true),
                ),
              ),
            ),
          if (overdueItems.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: FollowUpGroup(
                  title: 'OVERDUE COMMITMENTS',
                  items: overdueItems,
                  selectedFollowUpId: _selectedFollowUp?.id,
                  onTapFollowUp: _onFollowUpSelected,
                  onTapPerson: _navigateToPerson,
                  onTapSource: _navigateToSource,
                  onShareFollowUp: _handleShareFollowUp,
                  onDeleteFollowUp: _handleDeleteFollowUp,
                  onToggleComplete: (item) => _onToggleStatus(item.id, true),
                ),
              ),
            ),
          if (upcomingItems.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: FollowUpGroup(
                  title: 'UPCOMING COMMITMENTS',
                  items: upcomingItems,
                  selectedFollowUpId: _selectedFollowUp?.id,
                  onTapFollowUp: _onFollowUpSelected,
                  onTapPerson: _navigateToPerson,
                  onTapSource: _navigateToSource,
                  onShareFollowUp: _handleShareFollowUp,
                  onDeleteFollowUp: _handleDeleteFollowUp,
                  onToggleComplete: (item) => _onToggleStatus(item.id, true),
                ),
              ),
            ),
          if (waitingItems.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: FollowUpGroup(
                  title: 'WAITING ON THEM',
                  items: waitingItems,
                  selectedFollowUpId: _selectedFollowUp?.id,
                  onTapFollowUp: _onFollowUpSelected,
                  onTapPerson: _navigateToPerson,
                  onTapSource: _navigateToSource,
                  onShareFollowUp: _handleShareFollowUp,
                  onDeleteFollowUp: _handleDeleteFollowUp,
                  onToggleComplete: (item) => _onToggleStatus(item.id, true),
                ),
              ),
            ),
          if (completedItems.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: FollowUpGroup(
                  title: 'COMPLETED',
                  items: completedItems,
                  selectedFollowUpId: _selectedFollowUp?.id,
                  onTapFollowUp: _onFollowUpSelected,
                  onTapPerson: _navigateToPerson,
                  onTapSource: _navigateToSource,
                  onShareFollowUp: _handleShareFollowUp,
                  onDeleteFollowUp: _handleDeleteFollowUp,
                  onToggleComplete: (item) => _onToggleStatus(item.id, false),
                ),
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 80.0),
          ),
        ],
      ],
    );
  }
}