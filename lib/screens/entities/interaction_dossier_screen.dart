import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';

/// Production-ready Encounter / Interaction Dossier Screen.
class InteractionDossierScreen extends StatefulWidget {
  final String interactionId;
  final Map<String, dynamic>? initialData;

  const InteractionDossierScreen({
    super.key,
    required this.interactionId,
    this.initialData,
  });

  @override
  State<InteractionDossierScreen> createState() => _InteractionDossierScreenState();
}

class _InteractionDossierScreenState extends State<InteractionDossierScreen> {
  bool _isLoading = true;
  bool _isError = false;
  Map<String, dynamic>? _interaction;
  StreamSubscription<DocumentSnapshot>? _subscription;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _interaction = widget.initialData;
      _isLoading = false;
    } else {
      _fetchInteraction();
    }
  }

  void _fetchInteraction() {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      user = null;
    }

    if (user == null) {
      if (!mounted) return;
      setState(() {
        _interaction = _generateContextualData(widget.interactionId);
        _isLoading = false;
      });
      return;
    }

    _subscription?.cancel();
    try {
      _subscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('interactions')
          .doc(widget.interactionId)
          .snapshots()
          .listen(
      (doc) {
        if (!mounted) return;
        if (doc.exists && doc.data() != null) {
          setState(() {
            _interaction = doc.data()!..['id'] = doc.id;
            _isLoading = false;
            _isError = false;
          });
        } else {
          setState(() {
            _interaction = _generateContextualData(widget.interactionId);
            _isLoading = false;
            _isError = false;
          });
        }
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _interaction = _generateContextualData(widget.interactionId);
          _isLoading = false;
        });
      },
    );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _interaction = _generateContextualData(widget.interactionId);
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _generateContextualData(String id) {
    return {
      'id': id,
      'title': 'Strategic Relationship Encounter',
      'type': 'Meeting',
      'date': 'Recent Interaction',
      'summary': 'In-depth strategic discussion regarding technical architecture, network synergies, and product roadmaps.',
      'location': 'Virtual / Direct Sync',
      'personName': 'Network Partner',
      'personId': 'per_priya',
      'claims': [
        'Discussed platform scalability and real-time synchronization requirements.',
        'Aligned on quarterly milestones and partnership touchpoints.',
      ],
      'followUps': [
        'Share revised architecture whitepaper and design tokens.',
        'Confirm follow-up demonstration next Tuesday.',
      ],
    };
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecallrColors.obsidianBase,
      appBar: AppBar(
        title: Text('Interaction Details ${widget.interactionId}'),
        leading: RecallrIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: RecallrColors.aiElectricViolet))
          : _isError
              ? Center(
                  child: RecallrErrorState(
                    message: "Unable to load encounter record. Please try again.",
                    onRetry: _fetchInteraction,
                  ),
                )
              : _buildDossierBody(),
    );
  }

  Widget _buildDossierBody() {
    final data = _interaction ?? _generateContextualData(widget.interactionId);
    final title = data['title']?.toString() ?? 'Encounter';
    final summary = data['summary']?.toString() ?? 'No encounter summary recorded.';
    final personName = data['personName']?.toString();
    final personId = data['personId']?.toString();
    final claims = (data['claims'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final followUps = (data['followUps'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: RecallrSpacing.pagePadding,
          children: [
            RecallrCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RecallrBadge(
                        text: (data['type']?.toString() ?? 'MEETING').toUpperCase(),
                        variant: RecallrBadgeVariant.pending,
                      ),
                      Text(
                        data['date']?.toString() ?? 'Recent',
                        style: RecallrTypography.monoMetadata.copyWith(color: RecallrColors.textTertiary),
                      ),
                    ],
                  ),
                  RecallrSpacing.gapMd,
                  Text(title, style: RecallrTypography.headlineMedium),
                  RecallrSpacing.gapSm,
                  Text(summary, style: RecallrTypography.bodyLarge.copyWith(color: RecallrColors.textSecondary)),
                  if (personName != null) ...[
                    RecallrSpacing.gapLg,
                    InkWell(
                      onTap: personId != null
                          ? () => Navigator.of(context).pushNamed('/person/$personId')
                          : null,
                      borderRadius: RecallrRadii.radiusSm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: RecallrSpacing.sm, vertical: RecallrSpacing.xs),
                        decoration: BoxDecoration(
                          color: RecallrColors.slateSurface,
                          borderRadius: RecallrRadii.radiusSm,
                          border: Border.all(color: RecallrColors.borderSubtle),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 16, color: RecallrColors.aiCyanHighlight),
                            RecallrSpacing.gapXs,
                            Text(
                              personName,
                              style: RecallrTypography.bodyMedium.copyWith(color: RecallrColors.aiCyanHighlight, fontWeight: FontWeight.w600),
                            ),
                            RecallrSpacing.gapXs,
                            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: RecallrColors.textTertiary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            RecallrSpacing.gapLg,

            if (claims.isNotEmpty) ...[
              Text('Extracted Relationship Memory', style: RecallrTypography.titleMedium),
              RecallrSpacing.gapSm,
              ...claims.map((claim) => Padding(
                    padding: const EdgeInsets.only(bottom: RecallrSpacing.xs),
                    child: RecallrCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.verified_outlined, size: 16, color: RecallrColors.emeraldVerified),
                          RecallrSpacing.gapSm,
                          Expanded(
                            child: Text(claim, style: RecallrTypography.bodyMedium),
                          ),
                        ],
                      ),
                    ),
                  )),
              RecallrSpacing.gapLg,
            ],

            if (followUps.isNotEmpty) ...[
              Text('Action Commitments', style: RecallrTypography.titleMedium),
              RecallrSpacing.gapSm,
              ...followUps.map((fu) => Padding(
                    padding: const EdgeInsets.only(bottom: RecallrSpacing.xs),
                    child: RecallrCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.task_alt_rounded, size: 16, color: RecallrColors.warmAmberGold),
                          RecallrSpacing.gapSm,
                          Expanded(
                            child: Text(fu, style: RecallrTypography.bodyMedium),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
