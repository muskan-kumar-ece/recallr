import 'package:flutter/material.dart';
import 'home_memory_item.dart';

/// Isolated deterministic mock data for Phase 05 Home experience.
class HomeMockData {
  HomeMockData._();

  static const MemoryPulseStats pulseStats = MemoryPulseStats(
    peopleCount: 42,
    companiesCount: 18,
    interactionsCount: 89,
    followUpsCount: 3,
  );

  static final List<AttentionItem> attentionItems = [
    const AttentionItem(
      id: 'att_1',
      type: AttentionType.pendingCommitment,
      title: 'Send API Specs to Arjun',
      description: 'Promised during Bengaluru AI meet on Tuesday',
      targetRoute: '/follow-up/fol_101',
      badgeText: 'I PROMISED',
      dueText: 'Due today',
      icon: Icons.assignment_late_outlined,
    ),
    const AttentionItem(
      id: 'att_2',
      type: AttentionType.followUp,
      title: 'Hearing back from Dr. Rao on grant',
      description: 'Expected response regarding DST hardware grant review',
      targetRoute: '/follow-up/fol_102',
      badgeText: 'THEY PROMISED',
      dueText: '2d ago',
      icon: Icons.reply_outlined,
    ),
    const AttentionItem(
      id: 'att_3',
      type: AttentionType.missingContext,
      title: 'Kavita Menon — Visiting Card Scanned',
      description: 'Role missing: Verify VP Product @ Razorpay context',
      targetRoute: '/person/per_203',
      badgeText: 'MISSING CONTEXT',
      dueText: null,
      icon: Icons.contact_page_outlined,
    ),
  ];

  static final List<RecentPersonItem> recentPeople = [
    const RecentPersonItem(
      id: 'per_301',
      name: 'Priya Sharma',
      role: 'Principal Architect',
      company: 'Microsoft',
      lastInteracted: 'Yesterday',
      initials: 'PS',
      topCapability: 'Embedded SLMs',
      targetRoute: '/person/per_301',
    ),
    const RecentPersonItem(
      id: 'per_302',
      name: 'Vivek Raghavan',
      role: 'Co-founder',
      company: 'Sarvam AI',
      lastInteracted: '3d ago',
      initials: 'VR',
      topCapability: 'Indic Speech AI',
      targetRoute: '/person/per_302',
    ),
    const RecentPersonItem(
      id: 'per_303',
      name: 'Arjun Mehta',
      role: 'Partner',
      company: 'Nexus Venture',
      lastInteracted: '5d ago',
      initials: 'AM',
      topCapability: 'Fintech Seed',
      targetRoute: '/person/per_303',
    ),
    const RecentPersonItem(
      id: 'per_304',
      name: 'Dr. K. S. Rao',
      role: 'Director Quantum Lab',
      company: 'IISc Bangalore',
      lastInteracted: '1w ago',
      initials: 'KR',
      topCapability: 'Cryo CMOS',
      targetRoute: '/person/per_304',
    ),
  ];

  static final List<RecentMemoryItem> recentMemories = [
    const RecentMemoryItem(
      id: 'rec_1',
      type: MemoryType.person,
      title: 'Priya Sharma',
      subtitle: 'Principal Architect · Microsoft',
      eventOrLocation: 'Hyderabad Tech Summit',
      contextSnippet: 'Discussed embedded RISC-V kernels, on-device SLMs, and potential joint workshop in Q3.',
      timeAgo: 'Yesterday',
      initials: 'PS',
      targetRoute: '/person/per_301',
      tags: ['RISC-V', 'Embedded AI', 'Hyderabad'],
    ),
    const RecentMemoryItem(
      id: 'rec_2',
      type: MemoryType.company,
      title: 'Sarvam AI',
      subtitle: 'Generative AI & Indic LLMs · Bengaluru',
      eventOrLocation: 'Founders Dinner',
      contextSnippet: 'Spoke with Vivek about Hindi/Telugu speech models and low-latency audio pipelines.',
      timeAgo: '3d ago',
      initials: 'SA',
      targetRoute: '/company/cmp_401',
      tags: ['Indic AI', 'Audio', 'Founders'],
    ),
    const RecentMemoryItem(
      id: 'rec_3',
      type: MemoryType.interaction,
      title: 'Q2 Partnership Sync w/ Stripe',
      subtitle: 'Meeting · 4 Attendees',
      eventOrLocation: 'Google Meet',
      contextSnippet: 'Agreed to beta test recurring UPI auto-debit integration for cross-border SaaS tiers.',
      timeAgo: '4d ago',
      initials: 'ST',
      targetRoute: '/interaction/int_501',
      tags: ['Partnership', 'Stripe', 'Fintech'],
    ),
    const RecentMemoryItem(
      id: 'rec_4',
      type: MemoryType.note,
      title: 'Quantum Hardware Trends',
      subtitle: 'Conference Notes',
      eventOrLocation: 'IISc DeepTech Symposium',
      contextSnippet: 'Cryogenic control CMOS circuits and photonic interconnects will dominate scalable qubits by 2028.',
      timeAgo: '1w ago',
      initials: 'QN',
      targetRoute: '/file/fil_601',
      tags: ['DeepTech', 'Hardware', 'IISc'],
    ),
  ];
}