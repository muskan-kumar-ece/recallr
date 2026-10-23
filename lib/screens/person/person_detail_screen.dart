import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/di/recallr_dependencies.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/share_formatter.dart';
import '../../core/widgets/destructive_confirm_dialog.dart';
import '../../core/widgets/share_bottom_sheet.dart';
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
import '../../features/relationship_intelligence/models/models.dart';
import '../../repositories/person_detail_repository.dart';
import '../capture/capture_modal.dart';
import '../../services/ocr/ocr_entity_extractor.dart';

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
  UnifiedPersonRelationshipIntelligence? _intelligence;

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
      if (_intelligence == null) {
        _loadIntelligence(widget.personId);
      }
    } else if (widget.initialProfile != null && _intelligence == null) {
      _loadIntelligence(widget.initialProfile!.id);
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
          if (prof != null) {
            _loadIntelligence(prof.id);
          }
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

  Future<void> _loadIntelligence(String personId) async {
    if (!mounted || widget.repository != null) return;
    final service = mounted
        ? context.unifiedRelationshipIntelligence
        : RecallrDependencies.instance.unifiedRelationshipIntelligenceService;
    try {
      final intel = await service.getPersonIntelligence(personId);
      if (mounted) {
        setState(() {
          _intelligence = intel;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
        });
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
    final confirmed = await DestructiveConfirmDialog.show(
      context,
      title: 'Delete Contact',
      message: 'Are you sure you want to remove ' + profile.name + ' from your people directory? All associated dossier memories will be permanently deleted.',
      confirmLabel: 'Delete Contact',
    );

    if (confirmed == true && mounted) {
      try {
        final peopleRepo = mounted ? context.peopleRepo : RecallrDependencies.instance.peopleRepository;
        await peopleRepo.deletePerson(profile.id);

        final personDetailRepo = widget.repository ?? (mounted ? context.personDetailRepo : RecallrDependencies.instance.personDetailRepository);
        await personDetailRepo.deleteProfile(profile.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed ' + profile.name + ' from directory'),
              backgroundColor: RecallrColors.slateSurface,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete contact: '),
              backgroundColor: RecallrColors.crimsonAlert,
            ),
          );
        }
      }
    }
  }

  void _handleSharePerson(PersonProfile profile) {
    final summary = ShareFormatter.formatPersonSummary(profile);
    final vCard = ShareFormatter.toVCard(profile);
    ShareBottomSheet.show(
      context,
      title: 'Share Contact',
      subtitle: '${profile.name} · ${profile.company}',
      textSummary: summary,
      vCardContent: vCard,
      shareSubject: 'Contact Card: ${profile.name}',
    );
  }

  Widget _buildInvalidNamePrompt(PersonProfile profile) {
    return Container(
      key: const Key('name_warning_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: RecallrColors.warmAmberGold.withValues(alpha: 0.12),
        borderRadius: RecallrRadii.radiusMd,
        border: Border.all(color: RecallrColors.warmAmberGold.withValues(alpha: 0.5), width: 1.0),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 20.0, color: RecallrColors.warmAmberGold),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Name may be wrong - Fix',
                  style: RecallrTypography.labelSmall.copyWith(
                    color: RecallrColors.warmAmberGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'Saved name "${profile.name}" appears to be an address or company.',
                  style: RecallrTypography.bodyMedium.copyWith(
                    color: RecallrColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          RecallrSpacing.gapSm,
          ElevatedButton(
            key: const Key('fix_name_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: RecallrColors.warmAmberGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: RecallrRadii.radiusSm),
              elevation: 0,
            ),
            onPressed: () => _showEditPersonDialog(profile),
            child: const Text('Fix', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.0)),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditPersonDialog(PersonProfile profile) async {
    final nameCtrl = TextEditingController(text: profile.name);
    final companyCtrl = TextEditingController(text: profile.company);
    final roleCtrl = TextEditingController(text: profile.role);
    final locationCtrl = TextEditingController(text: profile.location);

    final updated = await showDialog<PersonProfile>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: RecallrColors.charcoalCard,
        shape: RoundedRectangleBorder(
          borderRadius: RecallrRadii.radiusLg,
          side: const BorderSide(color: RecallrColors.borderSubtle),
        ),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: RecallrColors.aiCyanHighlight, size: 22.0),
            const SizedBox(width: 8.0),
            Text('Edit Contact Details', style: RecallrTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NAME', style: RecallrTypography.labelSmall.copyWith(color: RecallrColors.textTertiary, fontSize: 9.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4.0),
              TextField(
                key: const Key('edit_person_name_field'),
                controller: nameCtrl,
                style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: RecallrColors.slateSurface,
                  border: OutlineInputBorder(borderRadius: RecallrRadii.radiusSm, borderSide: const BorderSide(color: RecallrColors.borderSubtle)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                ),
              ),
              const SizedBox(height: 12.0),
              Text('COMPANY', style: RecallrTypography.labelSmall.copyWith(color: RecallrColors.textTertiary, fontSize: 9.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4.0),
              TextField(
                key: const Key('edit_person_company_field'),
                controller: companyCtrl,
                style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: RecallrColors.slateSurface,
                  border: OutlineInputBorder(borderRadius: RecallrRadii.radiusSm, borderSide: const BorderSide(color: RecallrColors.borderSubtle)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                ),
              ),
              const SizedBox(height: 12.0),
              Text('ROLE', style: RecallrTypography.labelSmall.copyWith(color: RecallrColors.textTertiary, fontSize: 9.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4.0),
              TextField(
                key: const Key('edit_person_role_field'),
                controller: roleCtrl,
                style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: RecallrColors.slateSurface,
                  border: OutlineInputBorder(borderRadius: RecallrRadii.radiusSm, borderSide: const BorderSide(color: RecallrColors.borderSubtle)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                ),
              ),
              const SizedBox(height: 12.0),
              Text('LOCATION / ADDRESS', style: RecallrTypography.labelSmall.copyWith(color: RecallrColors.textTertiary, fontSize: 9.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4.0),
              TextField(
                key: const Key('edit_person_location_field'),
                controller: locationCtrl,
                style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: RecallrColors.slateSurface,
                  border: OutlineInputBorder(borderRadius: RecallrRadii.radiusSm, borderSide: const BorderSide(color: RecallrColors.borderSubtle)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel', style: TextStyle(color: RecallrColors.textTertiary)),
          ),
          ElevatedButton(
            key: const Key('save_person_edit_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: RecallrColors.aiElectricViolet,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: RecallrRadii.radiusSm),
            ),
            onPressed: () {
              final newName = nameCtrl.text.trim();
              final updatedProfile = profile.copyWith(
                name: newName.isNotEmpty ? newName : profile.name,
                company: companyCtrl.text.trim(),
                role: roleCtrl.text.trim(),
                location: locationCtrl.text.trim(),
                initials: PersonProfile.computeInitials(newName.isNotEmpty ? newName : profile.name),
              );
              Navigator.of(ctx).pop(updatedProfile);
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );

    if (updated != null && mounted) {
      await _repository.saveProfile(updated);
      setState(() {
        _profile = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact details updated successfully.')),
      );
    }
  }

  Widget _buildMobileLayout(PersonProfile profile) {
    final bool isPartial = profile.timeline.isEmpty && profile.memories.isEmpty && profile.aiSummary.isNotEmpty;
    final syncIntel = (mounted ? context.unifiedRelationshipIntelligence : RecallrDependencies.instance.unifiedRelationshipIntelligenceService)
        .computePersonIntelligenceSync(profile: profile);
    final unified = (_intelligence != null && _intelligence!.personId == profile.id && (_intelligence!.relationshipSignals.interactionCount > 0 || _intelligence!.relationshipStrength.score > 0))
        ? _intelligence!
        : syncIntel;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PersonProfileHeader(
            profile: profile,
            onBack: () => Navigator.of(context).pop(),
            onEdit: () => _showEditPersonDialog(profile),
            onShare: () => _handleSharePerson(profile),
            onDelete: () => _handleDeletePerson(profile),
          ),
        ),
        SliverPadding(
          padding: RecallrSpacing.pagePadding,
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (OcrEntityExtractor.isLikelyInvalidName(profile.name)) ...[
                _buildInvalidNamePrompt(profile),
                RecallrSpacing.gapLg,
              ],
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
    final syncIntel = (mounted ? context.unifiedRelationshipIntelligence : RecallrDependencies.instance.unifiedRelationshipIntelligenceService)
        .computePersonIntelligenceSync(profile: profile);
    final unified = (_intelligence != null && _intelligence!.personId == profile.id && (_intelligence!.relationshipSignals.interactionCount > 0 || _intelligence!.relationshipStrength.score > 0))
        ? _intelligence!
        : syncIntel;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PersonProfileHeader(
            profile: profile,
            onBack: () => Navigator.of(context).pop(),
            onEdit: () => _showEditPersonDialog(profile),
            onShare: () => _handleSharePerson(profile),
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
                      if (OcrEntityExtractor.isLikelyInvalidName(profile.name)) ...[
                        _buildInvalidNamePrompt(profile),
                        RecallrSpacing.gapLg,
                      ],
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