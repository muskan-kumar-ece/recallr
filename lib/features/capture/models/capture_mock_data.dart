import 'capture_models.dart';

/// Isolated, deterministic mock repository and extraction engine for Recallr Phase 11.
class CaptureMockData {
  CaptureMockData._();

  static List<CaptureItem> get initialRecentCaptures => [
    const CaptureItem(
      id: 'cap_1',
      type: CaptureType.voice,
      title: 'RISC-V discussion',
      description: 'Discussed embedded RISC-V kernels and on-device SLMs.',
      timestamp: '2 minutes ago',
      personId: 'per_priya',
      personName: 'Priya Sharma',
      personRole: 'VP of Silicon Architecture',
      companyId: 'comp_microsoft',
      companyName: 'Microsoft',
      eventName: 'Hyderabad Tech Summit',
      location: 'HICC · Hyderabad',
      targetRoute: '/interaction/int_101',
      isVerified: true,
    ),
    const CaptureItem(
      id: 'cap_2',
      type: CaptureType.businessCard,
      title: 'Visiting Card: Arjun Mehta',
      description: 'Physical card captured with AI fund scope and contact details.',
      timestamp: 'Today · 2:15 PM',
      personId: 'per_arjun',
      personName: 'Arjun Mehta',
      personRole: 'Partner',
      companyId: 'comp_nexus',
      companyName: 'Nexus Venture Partners',
      eventName: 'Portfolio Mixer',
      location: 'Indiranagar · Bengaluru',
      targetRoute: '/person/per_arjun',
      isVerified: true,
    ),
    const CaptureItem(
      id: 'cap_3',
      type: CaptureType.note,
      title: 'Note: Indic Voice Pipeline',
      description: 'Discussed Indic speech benchmark on low-power DSP accelerators.',
      timestamp: 'Yesterday · 6:30 PM',
      personId: 'per_vivek',
      personName: 'Vivek Raghavan',
      personRole: 'Chief AI Scientist',
      companyId: 'comp_sarvam',
      companyName: 'Sarvam AI',
      eventName: 'TiE Global Summit',
      location: 'TiE Summit · Hyderabad',
      targetRoute: '/person/per_vivek',
      isVerified: true,
    ),
  ];

  static CaptureReviewData getMockExtraction(
    CaptureType type, {
    String? customTitle,
    String? customNote,
    String? customPerson,
    String? customCompany,
    String? customEvent,
    String? customLocation,
  }) {
    switch (type) {
      case CaptureType.businessCard:
        return CaptureReviewData(
          title: customTitle?.isNotEmpty == true ? customTitle! : 'Arjun Mehta',
          summary: 'Scanned visiting card with verified contact credentials and investment focus.',
          personName: customPerson?.isNotEmpty == true ? customPerson! : 'Arjun Mehta',
          personRole: 'Partner',
          companyName: customCompany?.isNotEmpty == true ? customCompany! : 'Nexus Venture Partners',
          eventName: customEvent?.isNotEmpty == true ? customEvent! : 'Indiranagar Portfolio Mixer',
          location: customLocation?.isNotEmpty == true ? customLocation! : 'Bengaluru',
          date: 'Aug 18, 2026',
          contactDetails: const {
            'Email': 'arjun.mehta@nexusvp.com',
            'Phone': '+91 98450 12345',
            'Focus': 'Early Stage AI & Deep Tech',
          },
          bulletPoints: const [
            'Card text detected with 99.4% OCR confidence',
            'Nexus Venture Partners entity matched in network database',
            'Added follow-up promise: Send API specifications',
          ],
        );

      case CaptureType.voice:
        return CaptureReviewData(
          title: customTitle?.isNotEmpty == true ? customTitle! : 'Voice Memo: RISC-V discussion',
          summary: customNote?.isNotEmpty == true
              ? customNote!
              : 'Discussed embedded RISC-V kernels, on-device SLM inference latency, and potential collaboration on custom tensor accelerators.',
          personName: customPerson?.isNotEmpty == true ? customPerson! : 'Priya Sharma',
          personRole: 'VP of Silicon Architecture',
          companyName: customCompany?.isNotEmpty == true ? customCompany! : 'Microsoft',
          eventName: customEvent?.isNotEmpty == true ? customEvent! : 'Hyderabad Tech Summit',
          location: customLocation?.isNotEmpty == true ? customLocation! : 'HICC · Hyderabad',
          date: 'Today · 10:42 AM',
          audioDuration: '00:32',
          bulletPoints: const [
            'Key takeaway: Microsoft testing sub-5ms transformer inference',
            'Priya requested architecture spec sheet by Friday',
            'Context linked to Priya Sharma dossier',
          ],
        );

      case CaptureType.note:
        return CaptureReviewData(
          title: customTitle?.isNotEmpty == true ? customTitle! : 'Quick Note: RISC-V discussion',
          summary: customNote?.isNotEmpty == true
              ? customNote!
              : 'Discussed embedded inference and possible collaboration on hardware evaluation board.',
          personName: customPerson?.isNotEmpty == true ? customPerson! : 'Priya Sharma',
          personRole: 'VP of Silicon Architecture',
          companyName: customCompany?.isNotEmpty == true ? customCompany! : 'Microsoft',
          eventName: customEvent?.isNotEmpty == true ? customEvent! : 'Hyderabad Tech Summit',
          location: customLocation?.isNotEmpty == true ? customLocation! : 'Hyderabad',
          date: 'Today',
          bulletPoints: const [
            'Note saved directly to network timeline',
            'Associated with Microsoft company dossier',
          ],
        );

      case CaptureType.photo:
        return CaptureReviewData(
          title: customTitle?.isNotEmpty == true ? customTitle! : 'Photo: Architecture Whiteboard',
          summary: customNote?.isNotEmpty == true
              ? customNote!
              : 'Whiteboard diagram showing 16nm TSMC floorplan and memory bus topology.',
          personName: customPerson?.isNotEmpty == true ? customPerson! : 'Sarah Chen',
          personRole: 'Head of Architecture',
          companyName: customCompany?.isNotEmpty == true ? customCompany! : 'Mosaic Neuromorphic',
          eventName: customEvent?.isNotEmpty == true ? customEvent! : 'TiE Summit · Hyderabad',
          location: customLocation?.isNotEmpty == true ? customLocation! : 'TiE Summit Floor',
          date: 'Monday · 3:00 PM',
          bulletPoints: const [
            'Visual artifact captured: floorplan_diagram.jpg',
            'Floorplan latency specs extracted to note',
          ],
        );

      case CaptureType.document:
        return CaptureReviewData(
          title: customTitle?.isNotEmpty == true ? customTitle! : 'Document: riscv_v2_spec.pdf',
          summary: customNote?.isNotEmpty == true
              ? customNote!
              : 'Technical architecture specification sheet for RISC-V edge tensor compiler.',
          personName: customPerson?.isNotEmpty == true ? customPerson! : 'Priya Sharma',
          personRole: 'VP of Silicon Architecture',
          companyName: customCompany?.isNotEmpty == true ? customCompany! : 'Synthetix AI',
          eventName: customEvent?.isNotEmpty == true ? customEvent! : 'Bengaluru R&D Lab',
          location: customLocation?.isNotEmpty == true ? customLocation! : 'Bengaluru',
          date: 'Jul 12, 2026',
          bulletPoints: const [
            'PDF document indexed: riscv_v2_spec.pdf (2.4 MB)',
            'Grounded in Synthetix AI company memory',
          ],
        );
    }
  }
}