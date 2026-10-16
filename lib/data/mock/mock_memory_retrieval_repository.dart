import 'dart:async';
import '../../features/activity/models/activity_models.dart';
import '../../features/ask/models/memory_retrieval_models.dart';
import '../../features/capture/models/capture_models.dart';
import '../../features/follow_ups/models/follow_up_models.dart';
import '../../features/people/models/person_item.dart';
import '../../repositories/activity_repository.dart';
import '../../repositories/capture_repository.dart';
import '../../repositories/follow_up_repository.dart';
import '../../repositories/memory_retrieval_repository.dart';
import '../../repositories/people_repository.dart';
import '../../repositories/person_detail_repository.dart';
import 'mock_activity_repository.dart';
import 'mock_capture_repository.dart';
import 'mock_follow_up_repository.dart';
import 'mock_people_repository.dart';
import 'mock_person_detail_repository.dart';
import '../../services/retrieval/query_normalizer.dart';

/// Deterministic mock repository for Memory Retrieval tests and offline preview.
class MockMemoryRetrievalRepository implements MemoryRetrievalRepository {
  final PeopleRepository peopleRepository;
  final ActivityRepository activityRepository;
  final CaptureRepository captureRepository;
  final FollowUpRepository followUpRepository;
  final PersonDetailRepository personDetailRepository;

  MockMemoryRetrievalRepository({
    PeopleRepository? peopleRepository,
    ActivityRepository? activityRepository,
    CaptureRepository? captureRepository,
    FollowUpRepository? followUpRepository,
    PersonDetailRepository? personDetailRepository,
  })  : peopleRepository = peopleRepository ?? _createDefaultPeopleRepo(),
        activityRepository = activityRepository ?? _createDefaultActivityRepo(),
        captureRepository = captureRepository ?? _createDefaultCaptureRepo(),
        followUpRepository = followUpRepository ?? _createDefaultFollowUpRepo(),
        personDetailRepository = personDetailRepository ?? _createDefaultPersonDetailRepo();

  static PeopleRepository _createDefaultPeopleRepo() {
    return MockPeopleRepository(initialPeople: [
      PersonItem(
        id: 'per_sarah_01',
        name: 'Sarah Chen',
        role: 'VP of System Architecture',
        company: 'Mosaic Neuromorphic',
        email: 'sarah.chen@mosaic-neuro.io',
        phone: '+1 415 555 0101',
        locationOrEvent: 'San Francisco, CA',
        contextSnippet: 'Met at Stanford Tech Summit. Leading silicon photonics.',
        lastInteraction: 'Today at 4:00 PM',
        initials: 'SC',
        capabilities: ['Synaptic crossbars', 'Silicon photonics', 'RISC-V'],
        relationshipType: RelationshipContextType.collaborator,
      ),
      PersonItem(
        id: 'per_priya_01',
        name: 'Dr. Priya Sharma',
        role: 'Principal Architect & SLM Lead',
        company: 'Microsoft Research India',
        email: 'priya.sharma@microsoft.com',
        locationOrEvent: 'Bengaluru, India',
        contextSnippet: 'Expert in edge quantization and on-device SLMs.',
        lastInteraction: 'Yesterday',
        initials: 'PS',
        capabilities: ['Edge Quantization', 'On-Device SLM', 'RISC-V Vector'],
        relationshipType: RelationshipContextType.collaborator,
      ),
      PersonItem(
        id: 'per_marcus_01',
        name: 'Marcus Vance',
        role: 'Chief Technology Officer',
        company: 'Vance Dynamics',
        email: 'marcus@vance-dyn.com',
        locationOrEvent: 'Austin, TX',
        contextSnippet: 'High-density power electronics and GaN switches.',
        lastInteraction: '3 days ago',
        initials: 'MV',
        capabilities: ['GaN Power', 'High Density Inverters'],
        relationshipType: RelationshipContextType.advisor,
      ),
    ]);
  }

  static ActivityRepository _createDefaultActivityRepo() {
    return MockActivityRepository();
  }

  static CaptureRepository _createDefaultCaptureRepo() {
    return MockCaptureRepository();
  }

  static FollowUpRepository _createDefaultFollowUpRepo() {
    return MockFollowUpRepository(initialFollowUps: [
      FollowUpItem(
        id: 'fu_sarah_01',
        title: 'Send proposal deliverables to Sarah Chen',
        context: 'Commitment detected from Voice Memo: send proposal with pricing tiers.',
        commitmentType: CommitmentType.iPromised,
        status: FollowUpStatus.upcoming,
        priority: FollowUpPriority.high,
        dueDate: 'Tomorrow',
        createdDate: 'Today',
        personId: 'per_sarah_01',
        personName: 'Sarah Chen',
        companyName: 'Mosaic Neuromorphic',
        targetRoute: '/follow-up/fu_sarah_01',
      ),
      FollowUpItem(
        id: 'fu_priya_01',
        title: 'Coordinate edge quantization benchmarks with Priya',
        context: 'Agreed to share 4-bit integer matrix benchmark scripts.',
        commitmentType: CommitmentType.followUp,
        status: FollowUpStatus.upcoming,
        priority: FollowUpPriority.medium,
        dueDate: 'Next Week',
        createdDate: 'Yesterday',
        personId: 'per_priya_01',
        personName: 'Dr. Priya Sharma',
        companyName: 'Microsoft Research India',
        targetRoute: '/follow-up/fu_priya_01',
      ),
    ]);
  }

  static PersonDetailRepository _createDefaultPersonDetailRepo() {
    return MockPersonDetailRepository();
  }

  @override
  Future<List<PersonItem>> searchPeople(String query, {int limit = 10}) async {
    final lower = query.toLowerCase().trim();
    if (lower.isEmpty) return const [];
    final tokens = QueryNormalizer.extractTokens(lower);

    final peopleStream = peopleRepository.streamPeople();
    final allPeople = await peopleStream.first;

    return allPeople.where((p) {
      final haystacks = [
        p.name,
        p.role,
        p.company,
        p.email ?? '',
        p.phone ?? '',
        ...p.capabilities,
      ];
      return haystacks.any((h) => QueryNormalizer.matches(h, lower, precomputedTokens: tokens));
    }).take(limit).toList();
  }

  @override
  Future<List<ActivityItem>> searchActivities(String query, {int limit = 10}) async {
    final lower = query.toLowerCase().trim();
    if (lower.isEmpty) return const [];
    final tokens = QueryNormalizer.extractTokens(lower);

    final activities = await activityRepository.streamActivities().first;
    return activities.where((a) {
      final haystacks = [
        a.title,
        a.summary,
        a.personName ?? '',
        a.companyName ?? '',
      ];
      return haystacks.any((h) => QueryNormalizer.matches(h, lower, precomputedTokens: tokens));
    }).take(limit).toList();
  }

  @override
  Future<List<CaptureItem>> searchCaptures(String query, {int limit = 10}) async {
    final lower = query.toLowerCase().trim();
    if (lower.isEmpty) return const [];
    final tokens = QueryNormalizer.extractTokens(lower);

    final captures = await captureRepository.streamRecentCaptures().first;
    return captures.where((c) {
      final haystacks = [
        c.title,
        c.description,
        c.extractedText ?? '',
        c.summary ?? '',
        c.personName ?? '',
        c.companyName ?? '',
      ];
      return haystacks.any((h) => QueryNormalizer.matches(h, lower, precomputedTokens: tokens));
    }).take(limit).toList();
  }

  @override
  Future<List<FollowUpItem>> searchFollowUps(String query, {int limit = 10}) async {
    final lower = query.toLowerCase().trim();
    if (lower.isEmpty) return const [];
    final tokens = QueryNormalizer.extractTokens(lower);

    final followUps = await followUpRepository.streamFollowUps().first;
    return followUps.where((f) {
      final haystacks = [
        f.title,
        f.context,
        f.personName ?? '',
        f.companyName ?? '',
      ];
      return haystacks.any((h) => QueryNormalizer.matches(h, lower, precomputedTokens: tokens));
    }).take(limit).toList();
  }

  @override
  Future<List<MemoryEvidence>> searchEvidence(MemoryQuery query, {int limit = 30}) async {
    final queryText = query.rawQuery.toLowerCase().trim();
    final results = <MemoryEvidence>[];

    // 1. Search People
    final people = await searchPeople(queryText, limit: 10);
    for (final p in people) {
      results.add(MemoryEvidence(
        id: 'ev_p_${p.id}',
        sourceType: MemorySourceType.person,
        sourceId: p.id,
        personId: p.id,
        personName: p.name,
        timestamp: p.lastInteraction,
        content: '${p.name} · ${p.role} at ${p.company}. Capabilities: ${p.capabilities.join(", ")}. ${p.contextSnippet ?? ""}',
        relevanceScore: 0.90,
        matchReason: 'Person profile match for "$queryText"',
      ));

      // Also pull profile memories & timeline if available
      final profile = await personDetailRepository.getProfile(p.id);
      if (profile != null) {
        for (final m in profile.memories) {
          if (m.text.toLowerCase().contains(queryText) || m.category.toLowerCase().contains(queryText)) {
            results.add(MemoryEvidence(
              id: 'ev_mem_${m.id}',
              sourceType: MemorySourceType.memory,
              sourceId: m.id,
              personId: p.id,
              personName: p.name,
              timestamp: m.timestamp,
              content: '[${m.category}] ${m.text}',
              relevanceScore: 0.85,
              matchReason: 'Memory claim match for "$queryText"',
            ));
          }
        }
      }
    }

    // 2. Search Follow-ups
    final followUps = await searchFollowUps(queryText, limit: 10);
    for (final f in followUps) {
      results.add(MemoryEvidence(
        id: 'ev_fu_${f.id}',
        sourceType: MemorySourceType.followUp,
        sourceId: f.id,
        personId: f.personId,
        personName: f.personName,
        timestamp: f.dueDate,
        content: '${f.commitmentType.badgeText}: ${f.title}. Due: ${f.dueDate}. Context: ${f.context}',
        relevanceScore: 0.88,
        matchReason: 'Follow-up commitment match for "$queryText"',
      ));
    }

    // 3. Search Activities
    final activities = await searchActivities(queryText, limit: 10);
    for (final a in activities) {
      results.add(MemoryEvidence(
        id: 'ev_act_${a.id}',
        sourceType: MemorySourceType.activity,
        sourceId: a.id,
        personId: a.personId,
        personName: a.personName,
        timestamp: a.timestamp,
        content: '${a.title} (${a.timestamp}): ${a.summary}',
        relevanceScore: 0.80,
        matchReason: 'Activity encounter match for "$queryText"',
      ));
    }

    // 4. Search Captures
    final captures = await searchCaptures(queryText, limit: 10);
    for (final c in captures) {
      results.add(MemoryEvidence(
        id: 'ev_cap_${c.id}',
        sourceType: MemorySourceType.capture,
        sourceId: c.id,
        personId: c.personId,
        personName: c.personName,
        timestamp: c.timestamp,
        content: '${c.title} (${c.type.label}): ${c.summary ?? c.description} Extracted: ${c.extractedText ?? ""}',
        relevanceScore: 0.75,
        matchReason: 'Omni-Capture intake match for "$queryText"',
      ));
    }

    return results.take(limit).toList();
  }

  @override
  Future<List<MemoryEvidence>> getRecentInteractions({int limit = 10}) async {
    final activities = await activityRepository.streamActivities().first;
    final results = <MemoryEvidence>[];

    for (final a in activities.take(limit)) {
      results.add(MemoryEvidence(
        id: 'ev_recent_act_${a.id}',
        sourceType: MemorySourceType.activity,
        sourceId: a.id,
        personId: a.personId,
        personName: a.personName,
        timestamp: a.timestamp,
        content: '${a.title} with ${a.personName ?? "Contact"} (${a.companyName ?? ""}): ${a.summary}',
        relevanceScore: 0.85,
        matchReason: 'Recent encounter on timeline',
      ));
    }

    return results;
  }
}