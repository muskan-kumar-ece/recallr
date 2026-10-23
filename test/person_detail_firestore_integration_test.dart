import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/errors/data_exceptions.dart';
import 'package:recaller/features/follow_ups/models/follow_up_models.dart';
import 'package:recaller/features/people/models/person_item.dart';
import 'package:recaller/features/person_detail/models/person_profile_model.dart';
import 'package:recaller/features/person_detail/models/relationship_memory_models.dart';
import 'package:recaller/repositories/person_detail_repository.dart';
import 'package:recaller/screens/person/person_detail_screen.dart';

/// Fake implementation of PersonDetailRepository to test streaming and CRUD state transitions.
class FakeFirestorePersonDetailRepository implements PersonDetailRepository {
  final Map<String, PersonProfile> _store = {};
  final StreamController<PersonProfile?> _streamController = StreamController<PersonProfile?>.broadcast();
  bool shouldThrowUnauthenticated = false;
  bool shouldThrowError = false;

  FakeFirestorePersonDetailRepository({Map<String, PersonProfile>? initialData}) {
    if (initialData != null) {
      _store.addAll(initialData);
    }
  }

  @override
  Future<PersonProfile?> getProfile(String personId) async {
    if (shouldThrowUnauthenticated) throw RecallrDataException.unauthenticated();
    if (shouldThrowError) throw RecallrDataException.networkUnavailable();
    return _store[personId];
  }

  @override
  Stream<PersonProfile?> streamProfile(String personId) {
    if (shouldThrowUnauthenticated) return Stream.error(RecallrDataException.unauthenticated());
    if (shouldThrowError) return Stream.error(RecallrDataException.networkUnavailable());
    return Stream.value(_store[personId]);
  }

  @override
  Future<List<PersonProfile>> getAllProfiles() async {
    if (shouldThrowUnauthenticated) throw RecallrDataException.unauthenticated();
    if (shouldThrowError) throw RecallrDataException.networkUnavailable();
    return _store.values.toList();
  }

  @override
  Future<void> saveProfile(PersonProfile profile) async {
    _store[profile.id] = profile.copyWith(updatedAt: DateTime.now());
    _streamController.add(_store[profile.id]);
  }

  @override
  Future<void> addTimelineItem(String personId, TimelineItem item) async {
    final existing = _store[personId];
    if (existing != null) {
      final updated = existing.copyWith(
        timeline: [item, ...existing.timeline],
        lastInteraction: item.date,
        totalInteractions: existing.totalInteractions + 1,
        updatedAt: DateTime.now(),
      );
      _store[personId] = updated;
      _streamController.add(updated);
    }
  }

  @override
  Future<void> addMemoryItem(String personId, MemoryItem item) async {
    final existing = _store[personId];
    if (existing != null) {
      final updated = existing.copyWith(
        memories: [item, ...existing.memories],
        updatedAt: DateTime.now(),
      );
      _store[personId] = updated;
      _streamController.add(updated);
    }
  }

  @override
  Future<PersonProfile> enrichRelationshipMemory({
    required String personId,
    required RelationshipMemoryUpdate update,
  }) async {
    final existing = _store[personId] ??
        PersonProfile(
          id: personId,
          name: 'Contact $personId',
          role: '',
          company: '',
          location: '',
          initials: 'C',
          relationshipType: RelationshipContextType.collaborator,
          relationshipStrength: 'Emerging Connection',
          firstMet: 'Recent',
          lastInteraction: 'Today',
          totalInteractions: 1,
          sharedEventsCount: 0,
          aiSummary: 'Summary',
        );

    final updated = existing.copyWith(
      timeline: update.timelineItem != null ? [update.timelineItem!, ...existing.timeline] : existing.timeline,
      memories: [...update.memories, ...existing.memories],
      followUps: update.followUpCandidate != null ? [update.followUpCandidate!, ...existing.followUps] : existing.followUps,
      totalInteractions: update.totalInteractions ?? (existing.totalInteractions + 1),
      lastInteraction: update.lastInteraction ?? existing.lastInteraction,
      relationshipStrength: update.relationshipStrength ?? existing.relationshipStrength,
      updatedAt: DateTime.now(),
    );
    _store[personId] = updated;
    _streamController.add(updated);
    return updated;
  }

  @override
  Future<void> updateRelationshipStats(
    String personId, {
    int? totalInteractions,
    String? lastInteraction,
    String? relationshipStrength,
    int? sharedEventsCount,
  }) async {
    final existing = _store[personId];
    if (existing != null) {
      final updated = existing.copyWith(
        totalInteractions: totalInteractions ?? existing.totalInteractions,
        lastInteraction: lastInteraction ?? existing.lastInteraction,
        relationshipStrength: relationshipStrength ?? existing.relationshipStrength,
        sharedEventsCount: sharedEventsCount ?? existing.sharedEventsCount,
        updatedAt: DateTime.now(),
      );
      _store[personId] = updated;
      _streamController.add(updated);
    }
  }


  @override
  Future<void> deleteProfile(String personId) async {
    _store.remove(personId);
    _streamController.add(null);
  }

  @override
  Future<void> deleteMemoryItem(String personId, String memoryId) async {
    final existing = _store[personId];
    if (existing != null) {
      final updated = existing.copyWith(
        memories: existing.memories.where((m) => m.id != memoryId).toList(),
      );
      _store[personId] = updated;
      _streamController.add(updated);
    }
  }

  @override
  Future<void> deleteTimelineItem(String personId, String timelineId) async {
    final existing = _store[personId];
    if (existing != null) {
      final updated = existing.copyWith(
        timeline: existing.timeline.where((t) => t.id != timelineId).toList(),
      );
      _store[personId] = updated;
      _streamController.add(updated);
    }
  }

  void dispose() {
    _streamController.close();
  }
}

void main() {
  group('Phase 13C-03: Person Detail Domain Models & Serialization Tests', () {
    test('1. PersonProfile serializes and deserializes all nested structures accurately', () {
      final now = DateTime(2026, 8, 28, 10, 30);
      final profile = PersonProfile(
        id: 'per_301',
        name: 'Dr. Priya Sharma',
        role: 'Principal Architect & SLM Lead',
        company: 'Microsoft Research India',
        companyId: 'comp_msr',
        email: 'priya.sharma@microsoft.com',
        phone: '+91 98765 43210',
        location: 'Bengaluru / Hyderabad',
        initials: 'PS',
        relationshipType: RelationshipContextType.collaborator,
        relationshipStrength: 'Core Network',
        firstMet: 'India AI Summit 2024',
        lastInteraction: '2 days ago · Coffee catch-up',
        totalInteractions: 8,
        sharedEventsCount: 3,
        aiSummary: 'Leading edge research on quantization for Indic SLMs.',
        keyTakeaways: const ['Specializes in RISC-V LLVM quantization', 'Key speaker at Bengaluru AI Summit'],
        capabilities: const ['Quantization', 'SLMs', 'RISC-V', 'LLVM'],
        timeline: const [
          TimelineItem(
            id: 'time_1',
            type: TimelineType.meeting,
            title: 'Coffee catch-up at Indiranagar',
            subtitle: 'Discussed edge deployment',
            date: '2 days ago',
            locationOrEvent: 'Third Wave Coffee, Indiranagar',
            summary: 'Priya shared insights on 4-bit quantization.',
            keyBullets: ['Explored ONNX runtime', 'Agreed to exchange drafts'],
            targetRoute: '/interaction/time_1',
          ),
        ],
        memories: const [
          MemoryItem(
            id: 'mem_1',
            category: 'Expertise',
            text: 'Specializes in INT4 quantization on ARM and RISC-V',
            isVerified: true,
            source: 'India AI Summit 2024',
            timestamp: 'Nov 2024',
          ),
        ],
        followUps: const [
          FollowUpItem(
            id: 'fol_1',
            title: 'Send SLM quantization benchmark paper',
            personName: 'Dr. Priya Sharma',
            personId: 'per_301',
            dueDate: 'Tomorrow',
            commitmentType: CommitmentType.iPromised,
            targetRoute: '/follow-up/fol_1',
          ),
        ],
        connectedEntities: const [
          ConnectedEntity(
            id: 'ent_1',
            type: EntityType.company,
            title: 'Microsoft Research',
            subtitle: 'Enterprise AI',
            targetRoute: '/company/comp_msr',
          ),
        ],
        promptSuggestions: const ['What were Priya’s thoughts on 4-bit quantization?'],
        userId: 'usr_auth_789',
        createdAt: now,
        updatedAt: now,
      );

      final map = profile.toMap();
      expect(map['id'], equals('per_301'));
      expect(map['name'], equals('Dr. Priya Sharma'));
      expect(map['email'], equals('priya.sharma@microsoft.com'));
      expect(map['userId'], equals('usr_auth_789'));
      expect(map['timeline'], hasLength(1));
      expect(map['memories'], hasLength(1));
      expect(map['followUps'], hasLength(1));
      expect(map['connectedEntities'], hasLength(1));

      final restored = PersonProfile.fromMap(map, 'per_301');
      expect(restored.id, equals('per_301'));
      expect(restored.name, equals(profile.name));
      expect(restored.initials, equals('PS'));
      expect(restored.timeline.first.title, equals('Coffee catch-up at Indiranagar'));
      expect(restored.memories.first.text, equals('Specializes in INT4 quantization on ARM and RISC-V'));
      expect(restored.followUps.first.title, equals('Send SLM quantization benchmark paper'));
      expect(restored.connectedEntities.first.title, equals('Microsoft Research'));
    });

    test('2. PersonProfile fallback initials computation handles edge cases', () {
      expect(PersonProfile.computeInitials('Dr. Priya Sharma'), equals('DS'));
      expect(PersonProfile.computeInitials('Vivek Raghavan'), equals('VR'));
      expect(PersonProfile.computeInitials('Arjun'), equals('AR'));
      expect(PersonProfile.computeInitials(''), equals('??'));
    });
  });

  group('Phase 13C-03: Person Detail Repository Live State & UI Tests', () {
    late FakeFirestorePersonDetailRepository fakeRepo;
    final testProfile = PersonProfile(
      id: 'per_301',
      name: 'Dr. Priya Sharma',
      role: 'Principal Architect & SLM Lead',
      company: 'Microsoft Research India',
      location: 'Bengaluru',
      initials: 'PS',
      relationshipType: RelationshipContextType.collaborator,
      relationshipStrength: 'Core Network',
      firstMet: 'India AI Summit 2024',
      lastInteraction: '2 days ago',
      totalInteractions: 8,
      sharedEventsCount: 3,
      aiSummary: 'Leading edge research on quantization for Indic SLMs.',
      capabilities: const ['Quantization', 'SLMs'],
      timeline: const [
        TimelineItem(
          id: 'time_1',
          type: TimelineType.meeting,
          title: 'Coffee catch-up',
          subtitle: 'Discussed edge deployment',
          date: '2 days ago',
          summary: 'Priya shared insights on 4-bit quantization.',
        ),
      ],
      memories: const [
        MemoryItem(
          id: 'mem_1',
          category: 'Expertise',
          text: 'Specializes in INT4 quantization',
          isVerified: true,
          source: 'India AI Summit 2024',
        ),
      ],
      followUps: const [
        FollowUpItem(
          id: 'fol_1',
          title: 'Send SLM quantization paper',
          personName: 'Dr. Priya Sharma',
          personId: 'per_301',
          dueDate: 'Tomorrow',
          commitmentType: CommitmentType.iPromised,
          targetRoute: '/follow-up/fol_1',
        ),
      ],
      connectedEntities: const [
        ConnectedEntity(
          id: 'ent_1',
          type: EntityType.company,
          title: 'Microsoft Research',
          subtitle: 'Enterprise AI',
          targetRoute: '/company/comp_msr',
        ),
      ],
      promptSuggestions: const ['What did Priya say about quantization?'],
    );

    setUp(() {
      fakeRepo = FakeFirestorePersonDetailRepository(initialData: {
        'per_301': testProfile,
      });
    });

    tearDown(() {
      fakeRepo.dispose();
    });

    test('3. Repository adds timeline item and updates lastInteraction', () async {
      const newItem = TimelineItem(
        id: 'time_2',
        type: TimelineType.voiceNote,
        title: 'Voice memo: Kernel optimizations',
        subtitle: 'Quick debrief',
        date: 'Just now',
        summary: 'Recorded note about CUDA vs Triton.',
      );

      await fakeRepo.addTimelineItem('per_301', newItem);
      final updated = await fakeRepo.getProfile('per_301');
      expect(updated!.timeline, hasLength(2));
      expect(updated.timeline.first.id, equals('time_2'));
      expect(updated.lastInteraction, equals('Just now'));
      expect(updated.totalInteractions, equals(9));
    });

    test('4. Repository adds memory claim to dossier', () async {
      const newMemory = MemoryItem(
        id: 'mem_2',
        category: 'Project',
        text: 'Building open-source benchmark suite',
        isVerified: true,
        source: 'Voice memo',
      );

      await fakeRepo.addMemoryItem('per_301', newMemory);
      final updated = await fakeRepo.getProfile('per_301');
      expect(updated!.memories, hasLength(2));
      expect(updated.memories.first.id, equals('mem_2'));
    });

    testWidgets('5. PersonDetailScreen renders live profile from injected repository', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PersonDetailScreen(
              personId: 'per_301',
              repository: fakeRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dr. Priya Sharma'), findsWidgets);
      expect(find.textContaining('Microsoft Research India'), findsWidgets);
      expect(find.text('Strong Partner'), findsWidgets);
      expect(find.text('Leading edge research on quantization for Indic SLMs.'), findsOneWidget);
      expect(find.text('Coffee catch-up'), findsWidgets);
      expect(find.text('Send SLM quantization paper'), findsWidgets);
    });

    testWidgets('6. PersonDetailScreen displays error state and recovers on retry', (tester) async {
      final errorRepo = FakeFirestorePersonDetailRepository()..shouldThrowError = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PersonDetailScreen(
              personId: 'per_301',
              repository: errorRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining("couldn't load this person's memory dossier"), findsOneWidget);

      // Fix error and tap retry
      errorRepo.shouldThrowError = false;
      await errorRepo.saveProfile(testProfile);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Dr. Priya Sharma'), findsWidgets);
    });
  });
}