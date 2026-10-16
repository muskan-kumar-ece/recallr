import 'package:flutter/material.dart';
import 'ask_models.dart';

/// Local deterministic mock memory engine for Phase 07 Grounded Ask.
class MockMemoryEngine {
  const MockMemoryEngine();

  static const List<String> suggestedQuestions = [
    'What did I discuss with Priya about RISC-V?',
    'Who knows about embedded AI?',
    'What did Vivek promise to send me?',
    'Where did I meet Arjun?',
    'Which founders have I spoken with about AI hardware?',
    'Who should I follow up with this week?',
  ];

  static const List<String> recentQuestions = [
    'Priya Sharma RISC-V quantization',
    'Sarvam AI speech model latency',
    'IISc DeepTech hardware grant',
  ];

  /// Simulates memory retrieval with deterministic domain answers and citations.
  Future<GroundedAnswer?> ask(String question) async {
    final q = question.trim().toLowerCase();

    // 1. Check for ungrounded/unknown questions
    if (q.contains('alien') ||
        q.contains('unicorn') ||
        q.contains('mars') ||
        q.contains('xyznonexistent') ||
        q.contains('quantum teleportation')) {
      return null;
    }

    // 2. Priya Sharma / RISC-V
    if (q.contains('priya') || q.contains('risc-v') || q.contains('quantization')) {
      return const GroundedAnswer(
        queryId: 'ans_priya_riscv',
        queryText: 'What did I discuss with Priya about RISC-V?',
        answerText:
            'You discussed embedded RISC-V kernels and on-device small language models with Priya at the Hyderabad Tech Summit. You promised to send her your internal slide deck on 4-bit quantization benchmarks by tomorrow.',
        metadata: GroundingMetadata(
          memoryCount: 3,
          personCount: 1,
          groundingSummary: 'Grounded in 3 memories',
        ),
        relatedPeople: [
          PersonReference(
            id: 'per_301',
            name: 'Priya Sharma',
            role: 'Principal Architect',
            company: 'Microsoft',
            initials: 'PS',
            relationshipContext: 'Core Technical Collaborator · Discussed edge SLMs',
            targetRoute: '/person/per_301',
          ),
        ],
        sources: [
          MemorySource(
            id: 'src_1',
            sourceType: 'Conversation',
            icon: Icons.forum_outlined,
            personName: 'Priya Sharma',
            personRole: 'Principal Architect',
            company: 'Microsoft',
            eventOrLocation: 'Hyderabad Tech Summit · HICC Novotel',
            date: 'Jul 18 · Conversation',
            excerpt:
                'Evaluated 4-bit INT quantization latency gains on edge NPUs. Agreed to share internal slide deck by end of week.',
            isVerified: true,
            targetRoute: '/interaction/int_301',
          ),
          MemorySource(
            id: 'src_2',
            sourceType: 'Visiting Card',
            icon: Icons.contact_page_outlined,
            personName: 'Priya Sharma',
            personRole: 'Principal Architect',
            company: 'Microsoft',
            eventOrLocation: 'Open Source RISC-V Summit',
            date: 'Oct 14, 2024',
            excerpt:
                'Scanned physical business card. Contact: priya.sharma@microsoft.com, Hyderabad AI Campus.',
            isVerified: true,
            targetRoute: '/file/fil_301',
          ),
          MemorySource(
            id: 'src_3',
            sourceType: 'Follow-up Commitment',
            icon: Icons.bolt_rounded,
            personName: 'Priya Sharma',
            personRole: 'Principal Architect',
            company: 'Microsoft',
            eventOrLocation: 'Active Follow-up',
            date: 'Due Tomorrow',
            excerpt:
                'I PROMISED: Send slide deck on on-device quantization benchmarks.',
            isVerified: true,
            targetRoute: '/follow-up/fol_101',
          ),
        ],
        followUpSuggestions: [
          'What else did we discuss?',
          'When did I last meet Priya?',
          'What did she recommend?',
          'Do I have a follow-up with her?',
        ],
      );
    }

    // 3. Who knows about embedded AI?
    if (q.contains('embedded ai') || q.contains('embedded') || (q.contains('who') && q.contains('ai'))) {
      return const GroundedAnswer(
        queryId: 'ans_embedded_ai',
        queryText: 'Who knows about embedded AI?',
        answerText:
            'Priya Sharma (Principal Architect at Microsoft) specializes in embedded AI silicon and RISC-V acceleration, and Vivek Raghavan (Sarvam AI) specializes in on-device Indic speech AI models.',
        metadata: GroundingMetadata(
          memoryCount: 2,
          personCount: 2,
          groundingSummary: 'Grounded in 2 memories',
        ),
        relatedPeople: [
          PersonReference(
            id: 'per_301',
            name: 'Priya Sharma',
            role: 'Principal Architect',
            company: 'Microsoft',
            initials: 'PS',
            relationshipContext: 'Embedded Systems & RISC-V Lead',
            targetRoute: '/person/per_301',
          ),
          PersonReference(
            id: 'per_302',
            name: 'Vivek Raghavan',
            role: 'Co-founder',
            company: 'Sarvam AI',
            initials: 'VR',
            relationshipContext: 'On-device Indic Speech AI Lead',
            targetRoute: '/person/per_302',
          ),
        ],
        sources: [
          MemorySource(
            id: 'src_emb_1',
            sourceType: 'Discussion Note',
            icon: Icons.forum_outlined,
            personName: 'Priya Sharma',
            personRole: 'Principal Architect',
            company: 'Microsoft',
            eventOrLocation: 'Hyderabad Tech Summit',
            date: 'Jul 18',
            excerpt:
                'Priya presented Microsoft on-device embedded SLM kernel compilation on RISC-V.',
            isVerified: true,
            targetRoute: '/interaction/int_301',
          ),
          MemorySource(
            id: 'src_emb_2',
            sourceType: 'Founders Sync',
            icon: Icons.psychology_outlined,
            personName: 'Vivek Raghavan',
            personRole: 'Co-founder',
            company: 'Sarvam AI',
            eventOrLocation: 'Founders Dinner · Bengaluru',
            date: '3d ago',
            excerpt:
                'Vivek shared benchmarks on sub-100ms streaming voice models running on edge NPUs.',
            isVerified: true,
            targetRoute: '/interaction/int_303',
          ),
        ],
        followUpSuggestions: [
          'What did Priya say about RISC-V?',
          'When did I meet Vivek?',
        ],
      );
    }

    // 4. Vivek Raghavan / Promises
    if (q.contains('vivek') || (q.contains('promise') && q.contains('send'))) {
      return const GroundedAnswer(
        queryId: 'ans_vivek_promise',
        queryText: 'What did Vivek promise to send me?',
        answerText:
            'Vivek Raghavan promised to share early developer API access keys for Sarvam AI\'s sub-100ms streaming Indic speech models following your discussion in Koramangala.',
        metadata: GroundingMetadata(
          memoryCount: 2,
          personCount: 1,
          groundingSummary: 'Grounded in 2 memories',
        ),
        relatedPeople: [
          PersonReference(
            id: 'per_302',
            name: 'Vivek Raghavan',
            role: 'Co-founder',
            company: 'Sarvam AI',
            initials: 'VR',
            relationshipContext: 'Founder · Promised API access keys',
            targetRoute: '/person/per_302',
          ),
        ],
        sources: [
          MemorySource(
            id: 'src_vr_1',
            sourceType: 'Meeting Note',
            icon: Icons.forum_outlined,
            personName: 'Vivek Raghavan',
            personRole: 'Co-founder',
            company: 'Sarvam AI',
            eventOrLocation: 'Founders Dinner · Koramangala',
            date: '3d ago',
            excerpt:
                'THEY PROMISED: Send early developer API access keys for Sarvam Indic voice models.',
            isVerified: true,
            targetRoute: '/interaction/int_303',
          ),
        ],
        followUpSuggestions: [
          'When is Sarvam AI launching API access?',
          'Who else is working on speech models?',
        ],
      );
    }

    // 5. Where did I meet Arjun?
    if (q.contains('arjun') || q.contains('nexus')) {
      return const GroundedAnswer(
        queryId: 'ans_arjun_meet',
        queryText: 'Where did I meet Arjun?',
        answerText:
            'You met Arjun Mehta at the Nexus Venture Partners Bengaluru portfolio mixer on 10 Aug 2026. You discussed Seed stage hardware allocation and DeepTech investing.',
        metadata: GroundingMetadata(
          memoryCount: 2,
          personCount: 1,
          groundingSummary: 'Grounded in 2 memories',
        ),
        relatedPeople: [
          PersonReference(
            id: 'per_303',
            name: 'Arjun Mehta',
            role: 'Partner',
            company: 'Nexus Venture Partners',
            initials: 'AM',
            relationshipContext: 'DeepTech Investor · Met at Bengaluru mixer',
            targetRoute: '/person/per_303',
          ),
        ],
        sources: [
          MemorySource(
            id: 'src_am_1',
            sourceType: 'Portfolio Mixer Note',
            icon: Icons.place_outlined,
            personName: 'Arjun Mehta',
            personRole: 'Partner',
            company: 'Nexus Venture Partners',
            eventOrLocation: 'Nexus Portfolio Mixer · Indiranagar, Bengaluru',
            date: '10 Aug 2026',
            excerpt:
                'Exchanged views on DeepTech silicon seed valuations and Indian hardware startups.',
            isVerified: true,
            targetRoute: '/interaction/int_306',
          ),
        ],
        followUpSuggestions: [
          'What portfolio companies is Arjun supporting?',
          'Do I owe Arjun a follow-up?',
        ],
      );
    }

    // 6. Which founders have I spoken with about AI hardware? / PCB
    if (q.contains('founders') || q.contains('hardware') || q.contains('pcb')) {
      return const GroundedAnswer(
        queryId: 'ans_hardware_founders',
        queryText: 'Which founders have I spoken with about AI hardware?',
        answerText:
            'You have spoken with Vivek Raghavan (Co-founder, Sarvam AI) regarding edge voice models, and Rajesh Sharma (Managing Director, Delta Circuits) regarding multi-layer PCB prototyping.',
        metadata: GroundingMetadata(
          memoryCount: 2,
          personCount: 2,
          groundingSummary: 'Grounded in 2 memories',
        ),
        relatedPeople: [
          PersonReference(
            id: 'per_302',
            name: 'Vivek Raghavan',
            role: 'Co-founder',
            company: 'Sarvam AI',
            initials: 'VR',
            relationshipContext: 'Co-founder · Speech AI models',
            targetRoute: '/person/per_302',
          ),
          PersonReference(
            id: 'per_308',
            name: 'Rajesh Sharma',
            role: 'Managing Director',
            company: 'Delta Circuits',
            initials: 'RS',
            relationshipContext: 'Hardware Vendor · PCB Prototyping',
            targetRoute: '/person/per_308',
          ),
        ],
        sources: [
          MemorySource(
            id: 'src_rs_1',
            sourceType: 'Discussion Excerpt',
            icon: Icons.precision_manufacturing_outlined,
            personName: 'Rajesh Sharma',
            personRole: 'Managing Director',
            company: 'Delta Circuits',
            eventOrLocation: 'Hyderabad Tech Summit · Hardware Expo',
            date: '12 Aug 2026',
            excerpt:
                'Discussed multi-layer PCB fabrication and 48-hour quick-turn prototypes.',
            isVerified: true,
            targetRoute: '/interaction/int_305',
          ),
        ],
        followUpSuggestions: [
          'What is Delta Circuits turnaround time?',
          'When did I meet Vivek?',
        ],
      );
    }

    // 7. Follow-ups / Commitments
    if (q.contains('follow up') || q.contains('follow-up') || q.contains('commitments') || q.contains('week')) {
      return const GroundedAnswer(
        queryId: 'ans_followups_week',
        queryText: 'Who should I follow up with this week?',
        answerText:
            'You have 2 pending commitments: Send quantization benchmarks to Priya Sharma (Microsoft) by tomorrow, and review the DST quantum grant with Dr. K.S. Rao (IISc) by Friday.',
        metadata: GroundingMetadata(
          memoryCount: 2,
          personCount: 2,
          groundingSummary: 'Grounded in 2 memories',
        ),
        relatedPeople: [
          PersonReference(
            id: 'per_301',
            name: 'Priya Sharma',
            role: 'Principal Architect',
            company: 'Microsoft',
            initials: 'PS',
            relationshipContext: 'I PROMISED: Quantization deck by tomorrow',
            targetRoute: '/person/per_301',
          ),
          PersonReference(
            id: 'per_304',
            name: 'Dr. K. S. Rao',
            role: 'Director Quantum Lab',
            company: 'IISc Bangalore',
            initials: 'KR',
            relationshipContext: 'I PROMISED: Grant review comments by Friday',
            targetRoute: '/person/per_304',
          ),
        ],
        sources: [
          MemorySource(
            id: 'src_fol_1',
            sourceType: 'Active Follow-up',
            icon: Icons.bolt_rounded,
            personName: 'Priya Sharma',
            personRole: 'Principal Architect',
            company: 'Microsoft',
            date: 'Due Tomorrow',
            excerpt: 'I PROMISED: Send slide deck on on-device quantization benchmarks.',
            isVerified: true,
            targetRoute: '/follow-up/fol_101',
          ),
        ],
        followUpSuggestions: [
          'What did Priya ask for in the deck?',
          'What did Dr. Rao say about the grant?',
        ],
      );
    }

    // 8. General synthesis fallback
    return GroundedAnswer(
      queryId: 'ans_general_synth',
      queryText: question,
      answerText:
          'Based on your memory network, you have active relationships with Priya Sharma (Microsoft embedded AI), Vivek Raghavan (Sarvam AI speech models), and Dr. K.S. Rao (IISc Quantum Labs). Your most urgent pending commitment is sending quantization benchmarks to Priya by tomorrow.',
      metadata: const GroundingMetadata(
        memoryCount: 3,
        personCount: 2,
        groundingSummary: 'Grounded in 3 memories',
      ),
      relatedPeople: const [
        PersonReference(
          id: 'per_301',
          name: 'Priya Sharma',
          role: 'Principal Architect',
          company: 'Microsoft',
          initials: 'PS',
          relationshipContext: 'Core Technical Collaborator',
          targetRoute: '/person/per_301',
        ),
        PersonReference(
          id: 'per_302',
          name: 'Vivek Raghavan',
          role: 'Co-founder',
          company: 'Sarvam AI',
          initials: 'VR',
          relationshipContext: 'Founder',
          targetRoute: '/person/per_302',
        ),
      ],
      sources: const [
        MemorySource(
          id: 'src_gen_1',
          sourceType: 'Conversation Note',
          icon: Icons.forum_outlined,
          personName: 'Priya Sharma',
          personRole: 'Principal Architect',
          company: 'Microsoft',
          eventOrLocation: 'Hyderabad Tech Summit',
          date: 'Jul 18',
          excerpt:
              'Discussed embedded RISC-V kernels and low-power on-device SLMs.',
          isVerified: true,
          targetRoute: '/interaction/int_301',
        ),
      ],
      followUpSuggestions: const [
        'What did I discuss with Priya about RISC-V?',
        'Who knows about embedded AI?',
      ],
    );
  }
}