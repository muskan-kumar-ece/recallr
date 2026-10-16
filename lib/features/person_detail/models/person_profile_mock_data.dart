import '../../follow_ups/models/follow_up_models.dart';
import '../../people/models/person_item.dart';
import 'person_profile_model.dart';

/// Isolated deterministic mock repository for Phase 12 Person / Relationship Memory Detail.
class PersonProfileMockData {
  PersonProfileMockData._();

  static final Map<String, PersonProfile> _profiles = {
    // 1. Priya Sharma (per_301 / per_priya)
    'per_301': const PersonProfile(
      id: 'per_301',
      name: 'Priya Sharma',
      role: 'Principal Architect',
      company: 'Microsoft',
      companyId: 'cmp_microsoft',
      location: 'Hyderabad, India',
      initials: 'PS',
      relationshipType: RelationshipContextType.collaborator,
      relationshipStrength: 'High · Core Technical Collaborator',
      firstMet: 'October 2024 · Open Source RISC-V Summit',
      lastInteraction: 'Yesterday · 4:30 PM',
      totalInteractions: 5,
      sharedEventsCount: 2,
      aiSummary:
          'Priya leads Microsoft''s embedded RISC-V acceleration team in Hyderabad. She specializes in compiling lightweight on-device Small Language Models (SLMs) to low-power edge hardware. You met at Hyderabad Tech Summit and agreed to coordinate on edge quantization benchmarks.',
      keyTakeaways: [
        'Leading Microsoft edge AI kernel optimizations in Hyderabad',
        'Prefers asynchronous Signal/Telegram over formal emails',
        'Looking for collaborative benchmarking on 4-bit integer matrix ops',
      ],
      capabilities: [
        'RISC-V Vector Extensions',
        'Embedded AI',
        'On-Device SLMs',
        'Quantization',
        'Edge Compilers',
      ],
      promptSuggestions: [
        'What did we discuss about RISC-V quantization?',
        'What is Priya''s current role at Microsoft?',
        'What did I promise to send her?',
        'When did we first meet in Hyderabad?',
      ],
      timeline: [
        TimelineItem(
          id: 'tl_1',
          type: TimelineType.meeting,
          title: 'Hyderabad Tech Summit Sync',
          subtitle: '1:1 In-Person Meeting · 35 mins',
          date: 'Yesterday',
          locationOrEvent: 'HICC Novotel, Hyderabad',
          summary:
              'Discussed embedded RISC-V kernels, on-device SLMs, and potential joint workshop in Q3.',
          keyBullets: [
            'Evaluated 4-bit INT quantization latency gains on edge NPUs',
            'Agreed to share internal slide deck by end of week',
            'Priya offered to review compiler driver patch',
          ],
          targetRoute: '/interaction/int_103',
        ),
        TimelineItem(
          id: 'tl_2',
          type: TimelineType.cardScan,
          title: 'Visiting Card Scanned & Verified',
          subtitle: 'Optical Card OCR · Physical Encounter',
          date: 'Oct 14, 2024',
          locationOrEvent: 'Open Source RISC-V Summit',
          summary: 'Scanned business card at Microsoft AI booth. Verified role as Principal Architect.',
          keyBullets: [
            'Card email: priya.sharma@microsoft.com',
            'Added Hyderabad office location',
          ],
          targetRoute: '/file/fil_301',
        ),
        TimelineItem(
          id: 'tl_3',
          type: TimelineType.voiceNote,
          title: 'Voice Note: Key Takeaways on NPU Compilers',
          subtitle: 'Captured Voice Memo · 1 min 20 sec',
          date: 'Oct 15, 2024',
          locationOrEvent: 'Bengaluru Airport Lounge',
          summary:
              'Dictated notes on Priya''s perspective regarding LLVM vectorization bottlenecks.',
          keyBullets: [
            'Mentioned potential talk at LLVM Developers Meeting',
          ],
          targetRoute: '/interaction/int_302',
        ),
      ],
      memories: [
        MemoryItem(
          id: 'mem_1',
          category: 'Technical Working Focus',
          text:
              'Leads LLVM RISC-V vector extensions optimization working group for edge silicon accelerators.',
          isVerified: true,
          source: 'Verified during Tech Summit 1:1',
          timestamp: 'Yesterday',
        ),
        MemoryItem(
          id: 'mem_2',
          category: 'Communication Preference',
          text: 'Prefers concise bulleted updates on messaging apps; avoids lengthy scheduling email threads.',
          isVerified: true,
          source: 'Observed during collaboration',
          timestamp: 'Oct 2024',
        ),
        MemoryItem(
          id: 'mem_3',
          category: 'Shared Goal',
          text: 'Co-authoring edge SLM benchmarking whitepaper targeting Q3 2026 conference.',
          isVerified: true,
          source: 'Hyderabad Tech Summit Meeting',
          timestamp: 'Yesterday',
        ),
      ],
      followUps: [
        FollowUpItem(
          id: 'fol_103',
          title: 'Check with Priya about RISC-V discussion',
          commitmentType: CommitmentType.iPromised,
          dueDate: 'Due Tomorrow',
          isCompleted: false,
          targetRoute: '/follow-up/fol_103',
        ),
        FollowUpItem(
          id: 'fol_106',
          title: 'Shared embedded AI research with Priya',
          commitmentType: CommitmentType.theyPromised,
          dueDate: 'Completed',
          isCompleted: true,
          targetRoute: '/follow-up/fol_106',
        ),
      ],
      connectedEntities: [
        ConnectedEntity(
          id: 'cmp_microsoft',
          type: EntityType.company,
          title: 'Microsoft',
          subtitle: 'Principal Architect · Hyderabad Campus',
          targetRoute: '/company/cmp_microsoft',
        ),
        ConnectedEntity(
          id: 'evt_hyd_2025',
          type: EntityType.event,
          title: 'Hyderabad Tech Summit 2025',
          subtitle: 'Speaker & Attendee Encounter',
          targetRoute: '/event/evt_hyd_2025',
        ),
        ConnectedEntity(
          id: 'fil_301',
          type: EntityType.file,
          title: 'Priya_Sharma_Visiting_Card.pdf',
          subtitle: 'Scanned Card & Extracted VCF',
          targetRoute: '/file/fil_301',
        ),
        ConnectedEntity(
          id: 'per_304',
          type: EntityType.person,
          title: 'Dr. K. S. Rao',
          subtitle: 'Mutual Collaborator · IISc Bangalore',
          targetRoute: '/person/per_304',
        ),
      ],
    ),

    // 2. Vivek Raghavan (per_302 / per_vivek)
    'per_302': const PersonProfile(
      id: 'per_302',
      name: 'Vivek Raghavan',
      role: 'Co-founder',
      company: 'Sarvam AI',
      companyId: 'cmp_sarvam',
      location: 'Bengaluru, India',
      initials: 'VR',
      relationshipType: RelationshipContextType.founder,
      relationshipStrength: 'High · Industry Founder',
      firstMet: 'August 2024 · AI India Roundtable',
      lastInteraction: '3d ago · Founders Dinner',
      totalInteractions: 3,
      sharedEventsCount: 2,
      aiSummary:
          'Vivek is co-founder of Sarvam AI building Indic foundational models and low-latency voice AI pipelines. You met at the Founders Dinner in Koramangala and discussed Hindi & Telugu multi-speaker audio tokenization.',
      keyTakeaways: [
        'Building sovereign Indic speech and language models',
        'Scaling 10,000+ GPU cluster in India',
        'Deep domain expertise in ASR and TTS latency optimization',
      ],
      capabilities: ['Indic LLMs', 'Speech AI', 'GPU Infrastructure', 'Foundational Models'],
      promptSuggestions: [
        'What did Vivek say about Indic speech models?',
        'What is Sarvam AI currently focusing on?',
        'When did we last meet in Bengaluru?',
      ],
      timeline: [
        TimelineItem(
          id: 'tl_vr_1',
          type: TimelineType.meeting,
          title: 'TiE Global Summit Discussion',
          subtitle: 'Dinner Discussion · 1 hr 20 mins',
          date: '3d ago',
          locationOrEvent: 'Bengaluru',
          summary: 'Exchanged notes on streaming Indic voice agents and GPU allocation economics.',
          keyBullets: [
            'Discussed 100ms sub-word speech synthesis latency targets',
            'Explored potential test API access for Recallr Indic speech testing',
          ],
          targetRoute: '/interaction/int_102',
        ),
      ],
      memories: [
        MemoryItem(
          id: 'mem_vr_1',
          category: 'Domain Strategy',
          text: 'Pioneering vernacular voice interfaces for Indian population scale applications.',
          isVerified: true,
          source: 'Founders Dinner Conversation',
          timestamp: '3d ago',
        ),
      ],
      followUps: [
        FollowUpItem(
          id: 'fol_102',
          title: 'Vivek will send hardware architecture',
          commitmentType: CommitmentType.theyPromised,
          dueDate: 'Expected by Friday',
          isCompleted: false,
          targetRoute: '/follow-up/fol_102',
        ),
      ],
      connectedEntities: [
        ConnectedEntity(
          id: 'cmp_sarvam',
          type: EntityType.company,
          title: 'Sarvam AI',
          subtitle: 'Founding Organization',
          targetRoute: '/company/cmp_sarvam',
        ),
        ConnectedEntity(
          id: 'evt_tie_2025',
          type: EntityType.event,
          title: 'TiE Global Summit',
          subtitle: 'Speaker & Panelist',
          targetRoute: '/event/evt_tie_2025',
        ),
      ],
    ),

    // 3. Arjun Mehta (per_303 / per_arjun)
    'per_303': const PersonProfile(
      id: 'per_303',
      name: 'Arjun Mehta',
      role: 'Partner',
      company: 'Nexus Venture Partners',
      companyId: 'cmp_nexus',
      location: 'Bengaluru, India',
      initials: 'AM',
      relationshipType: RelationshipContextType.investor,
      relationshipStrength: 'High · Early Stage AI Investor',
      firstMet: 'May 2024 · Indiranagar Portfolio Mixer',
      lastInteraction: '5d ago · Nexus Office',
      totalInteractions: 4,
      sharedEventsCount: 2,
      aiSummary:
          'Arjun is a Partner at Nexus Venture Partners leading early-stage enterprise AI and developer tool investments. You met at the Indiranagar Portfolio Mixer and discussed memory systems and on-device inference.',
      keyTakeaways: [
        'Looking for defensible AI memory architecture and enterprise moats',
        'Requested API documentation and integration benchmarks',
      ],
      capabilities: ['Venture Capital', 'Enterprise SaaS', 'AI Infrastructure', 'Go-To-Market'],
      promptSuggestions: [
        'What did Arjun ask about Recallr API specs?',
        'What is Nexus Venture Partners investment focus?',
      ],
      timeline: [
        TimelineItem(
          id: 'tl_am_1',
          type: TimelineType.meeting,
          title: 'Indiranagar Portfolio Mixer',
          subtitle: '1:1 Discussion · 45 mins',
          date: '5d ago',
          locationOrEvent: 'Indiranagar · Bengaluru',
          summary: 'Discussed edge memory architecture and technical benchmarks.',
          keyBullets: [
            'Arjun requested developer API docs and latency profile',
          ],
          targetRoute: '/interaction/int_101',
        ),
      ],
      memories: [
        MemoryItem(
          id: 'mem_am_1',
          category: 'Investment Focus',
          text: 'Focuses on Series Seed to Series A AI infrastructure companies with proprietary runtime moats.',
          isVerified: true,
          source: 'Nexus Office Meeting',
          timestamp: '5d ago',
        ),
      ],
      followUps: [
        FollowUpItem(
          id: 'fol_101',
          title: 'Send API specs to Arjun',
          commitmentType: CommitmentType.iPromised,
          dueDate: 'Due Today',
          isCompleted: false,
          targetRoute: '/follow-up/fol_101',
        ),
      ],
      connectedEntities: [
        ConnectedEntity(
          id: 'cmp_nexus',
          type: EntityType.company,
          title: 'Nexus Venture Partners',
          subtitle: 'Investment Firm',
          targetRoute: '/company/cmp_nexus',
        ),
      ],
    ),

    // 4. Dr. K. S. Rao (per_304 / per_rao)
    'per_304': const PersonProfile(
      id: 'per_304',
      name: 'Dr. K. S. Rao',
      role: 'Director Quantum Lab',
      company: 'IISc Bangalore',
      companyId: 'cmp_iisc',
      location: 'Bengaluru, India',
      initials: 'KR',
      relationshipType: RelationshipContextType.mentor,
      relationshipStrength: 'Medium · Research Advisor',
      firstMet: 'November 2024 · IISc DeepTech Symposium',
      lastInteraction: '1w ago',
      totalInteractions: 2,
      sharedEventsCount: 1,
      aiSummary:
          'Dr. Rao heads the Quantum Technology Initiative at IISc Bangalore focusing on cryogenic CMOS circuits and silicon spin qubits. He advised on DST hardware grant applications.',
      keyTakeaways: [
        'Leading silicon spin qubit cryogenic control initiatives at IISc',
        'Regular consultant for National Quantum Mission',
      ],
      capabilities: ['Quantum Computing', 'Cryo CMOS', 'Hardware Design', 'DST Grants'],
      promptSuggestions: [
        'What did Dr. Rao advise on the DST grant?',
        'What research does his IISc lab conduct?',
      ],
      timeline: [
        TimelineItem(
          id: 'tl_kr_1',
          type: TimelineType.meeting,
          title: 'IISc DeepTech Symposium',
          subtitle: 'Research Consultation · 45 mins',
          date: '1w ago',
          locationOrEvent: 'IISc Main Campus, Bengaluru',
          summary: 'Reviewed cryogenic control CMOS circuit architectures and DST hardware review timeline.',
          keyBullets: [
            'Awaiting official DST panel feedback in Q2',
          ],
          targetRoute: '/interaction/int_104',
        ),
      ],
      memories: [
        MemoryItem(
          id: 'mem_kr_1',
          category: 'Advisory Guidance',
          text: 'Recommended focusing on low-power photonic interconnects for scalable qubit interfaces.',
          isVerified: true,
          source: 'IISc DeepTech Consultation',
          timestamp: '1w ago',
        ),
      ],
      followUps: [
        FollowUpItem(
          id: 'fol_105',
          title: 'Dr. Rao to confirm quantum lab grant review',
          commitmentType: CommitmentType.theyPromised,
          dueDate: 'Expected in 2 weeks',
          isCompleted: false,
          targetRoute: '/follow-up/fol_105',
        ),
      ],
      connectedEntities: [
        ConnectedEntity(
          id: 'cmp_iisc',
          type: EntityType.company,
          title: 'IISc Bangalore',
          subtitle: 'Department of Electrical & Quantum Engg',
          targetRoute: '/company/cmp_iisc',
        ),
      ],
    ),

    // 5. Kavita Menon (per_305 / per_kavita)
    'per_305': const PersonProfile(
      id: 'per_305',
      name: 'Kavita Menon',
      role: 'VP Partnerships',
      company: 'Peak AI',
      companyId: 'cmp_peak',
      location: 'Mumbai, India',
      initials: 'KM',
      relationshipType: RelationshipContextType.client,
      relationshipStrength: 'Medium · Enterprise Prospect',
      firstMet: 'December 2024 · Mumbai Enterprise Tech Forum',
      lastInteraction: '2w ago',
      totalInteractions: 2,
      sharedEventsCount: 1,
      aiSummary:
          'Kavita leads enterprise partnership channels at Peak AI. She explored pilot deployments of Recallr across executive sales cohorts.',
      keyTakeaways: [
        'Managing enterprise AI deployment pilots in Mumbai and Delhi',
        'Requested formal partnership proposal and SOC2 compliance summary',
      ],
      capabilities: ['Enterprise Sales', 'Partnerships', 'Channel Strategy'],
      promptSuggestions: [
        'What did Kavita ask regarding the enterprise proposal?',
        'When is our next partnership check-in?',
      ],
      timeline: [],
      memories: [],
      followUps: [
        FollowUpItem(
          id: 'fol_104',
          title: 'Send partnership proposal to Kavita',
          commitmentType: CommitmentType.iPromised,
          dueDate: 'Overdue',
          isCompleted: false,
          targetRoute: '/follow-up/fol_104',
        ),
      ],
      connectedEntities: [
        ConnectedEntity(
          id: 'cmp_peak',
          type: EntityType.company,
          title: 'Peak AI',
          subtitle: 'Enterprise AI Solutions',
          targetRoute: '/company/cmp_peak',
        ),
      ],
    ),

    // 6. Partial / Missing Context profile (per_partial)
    'per_partial': const PersonProfile(
      id: 'per_partial',
      name: 'Rohan Deshmukh',
      role: 'Software Engineer',
      company: 'CloudNative Inc.',
      companyId: 'cmp_cloudnative',
      location: 'Pune, India',
      initials: 'RD',
      relationshipType: RelationshipContextType.colleague,
      relationshipStrength: 'New Contact · Initial Card Scan',
      firstMet: 'Yesterday · Visiting Card Scanned',
      lastInteraction: 'Yesterday',
      totalInteractions: 1,
      sharedEventsCount: 0,
      aiSummary: "Recallr has this person's identity, but there isn't enough conversation history yet.",
      keyTakeaways: [],
      capabilities: ['Golang', 'Kubernetes'],
      timeline: [],
      memories: [],
      followUps: [],
      connectedEntities: [],
    ),

    // 7. Empty profile (per_empty)
    'per_empty': const PersonProfile(
      id: 'per_empty',
      name: 'Anonymous Contact',
      role: 'Unknown Role',
      company: 'Unknown Organization',
      location: 'Unknown Location',
      initials: 'AC',
      relationshipType: RelationshipContextType.colleague,
      relationshipStrength: 'No Recorded History',
      firstMet: 'Not recorded',
      lastInteraction: 'None',
      totalInteractions: 0,
      sharedEventsCount: 0,
      aiSummary: '',
      keyTakeaways: [],
      capabilities: [],
      timeline: [],
      memories: [],
      followUps: [],
      connectedEntities: [],
    ),
  };

  static PersonProfile? getProfile(String id) {
    // 1. Direct ID match
    if (_profiles.containsKey(id)) {
      return _profiles[id];
    }

    // 2. Alias match
    final normalized = id.toLowerCase();
    if (normalized.contains('priya')) return _profiles['per_301'];
    if (normalized.contains('vivek')) return _profiles['per_302'];
    if (normalized.contains('arjun')) return _profiles['per_303'];
    if (normalized.contains('rao')) return _profiles['per_304'];
    if (normalized.contains('kavita')) return _profiles['per_305'];
    if (normalized.contains('partial')) return _profiles['per_partial'];
    if (normalized.contains('empty')) return _profiles['per_empty'];

    if (id.contains('non_existent') || id.contains('not_found') || id == '404') {
      return null;
    }

    // Default fallback
    return _profiles['per_301'];
  }
}