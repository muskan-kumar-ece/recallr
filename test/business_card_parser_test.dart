import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/di/recallr_dependencies.dart';
import 'package:recaller/data/mock/mock_person_detail_repository.dart';
import 'package:recaller/features/capture/models/capture_models.dart';
import 'package:recaller/features/capture/widgets/capture_review_view.dart';
import 'package:recaller/features/people/models/person_item.dart';
import 'package:recaller/features/person_detail/models/person_profile_model.dart';
import 'package:recaller/features/person_detail/widgets/person_profile_header.dart';
import 'package:recaller/screens/person/person_detail_screen.dart';
import 'package:recaller/services/ocr/ocr_entity_extractor.dart';

void main() {
  group('Business Card OCR Parsing & Entity Extraction Tests', () {
    // -------------------------------------------------------------------------
    // Test Case A: Bandhan Enterprises card with address, brands & email
    // -------------------------------------------------------------------------
    test('a) Bandhan card text: name must NOT contain "Nagar" or "Estate", brands separated, address isolated', () {
      const bandhanCardText = '''
BANDHAN ENTERPRISES
Authorised Dealers: WAGO, HAVELLS
Plot No. 42, Nagar (Industrial Estate),
Pune - 411018
aniln@bandhanindustries.com
+91 98765 43210
www.bandhanindustries.com
''';

      final entities = OcrEntityExtractor.extract(bandhanCardText);
      final json = entities.toJson();

      // 1. Strict JSON structure contract
      expect(json.containsKey('name'), isTrue);
      expect(json.containsKey('designation'), isTrue);
      expect(json.containsKey('company'), isTrue);
      expect(json.containsKey('brands'), isTrue);
      expect(json.containsKey('phones'), isTrue);
      expect(json.containsKey('emails'), isTrue);
      expect(json.containsKey('website'), isTrue);
      expect(json.containsKey('address'), isTrue);
      expect(json.containsKey('confidence'), isTrue);

      // 2. Name field validation
      if (entities.name != null) {
        expect(entities.name!.toLowerCase(), isNot(contains('nagar')));
        expect(entities.name!.toLowerCase(), isNot(contains('estate')));
        expect(entities.name!.toLowerCase(), isNot(contains('industrial')));
        expect(entities.name!.toLowerCase(), isNot(contains('plot')));
      }

      // Name derived from email aniln -> "Anil N"
      expect(entities.name, equals('Anil N'));
      // Initials for Anil N must be AN (never NE from Nagar Estate)
      expect(PersonItem.computeInitials(entities.name!), equals('AN'));
      // Because name was derived from email, confidence is lower (< 0.70)
      expect(entities.nameConfidence, lessThan(0.70));

      // 3. Brands extraction: WAGO and HAVELLS must go to brands, NOT to location
      expect(entities.brands, containsAll(['WAGO', 'HAVELLS']));
      expect(entities.brands, isNot(contains('PUNE')));

      // 4. Address validation
      expect(entities.address, isNotNull);
      expect(entities.address!, contains('Nagar (Industrial Estate)'));
      expect(entities.address!, contains('Pune - 411018'));
      // Brands must NOT be in the address
      expect(entities.address!, isNot(contains('WAGO')));
      expect(entities.address!, isNot(contains('HAVELLS')));

      // 5. Contact fields
      expect(entities.emails, contains('aniln@bandhanindustries.com'));
      expect(entities.phones, contains('+91 98765 43210'));
      expect(entities.website, equals('www.bandhanindustries.com'));
      expect(entities.company, contains('Bandhan'));
    });

    // -------------------------------------------------------------------------
    // Test Case B: Normal card with clear person name, company and address
    // -------------------------------------------------------------------------
    test('b) Normal card: extracts clear person name, company, designation, address with high confidence', () {
      const normalCardText = '''
Dr. Sarah Chen
VP of Engineering
Mosaic Labs Inc.
sarah.chen@mosaiclabs.ai
+1 (415) 555-0142
https://mosaiclabs.ai
100 Innovation Way, Suite 400, San Francisco, CA 94105
''';

      final entities = OcrEntityExtractor.extract(normalCardText);

      expect(entities.name, equals('Sarah Chen'));
      expect(entities.designation, equals('VP of Engineering'));
      expect(entities.company, equals('Mosaic Labs Inc.'));
      expect(entities.emails, contains('sarah.chen@mosaiclabs.ai'));
      expect(entities.phones, contains('+1 (415) 555-0142'));
      expect(entities.website, equals('https://mosaiclabs.ai'));
      expect(entities.address, contains('100 Innovation Way'));
      expect(entities.address, contains('San Francisco'));

      // High confidence: name candidate matches email local part "sarah.chen"
      expect(entities.nameConfidence, greaterThanOrEqualTo(0.70));
      expect(PersonItem.computeInitials(entities.name!), equals('SC'));
    });

    // -------------------------------------------------------------------------
    // Test Case C: Card with no readable person name
    // -------------------------------------------------------------------------
    test('c) Card with no readable person name: name is null, confidence is 0.0', () {
      const corporateCardText = '''
TECH DISTRIBUTORS
Industrial Equipment & Components
info@techdistributors.com
+91 20 2555 1234
Sector 18, Industrial Area, Pune 411026
''';

      final entities = OcrEntityExtractor.extract(corporateCardText);

      expect(entities.name, isNull);
      expect(entities.nameConfidence, equals(0.0));
      expect(entities.company, equals('Tech Distributors'));
      expect(entities.address, contains('Sector 18, Industrial Area, Pune 411026'));
      expect(entities.phones, contains('+91 20 2555 1234'));
      expect(entities.emails, contains('info@techdistributors.com'));
    });

    // -------------------------------------------------------------------------
    // Test Case D: Two brands and PIN code in address
    // -------------------------------------------------------------------------
    test('d) Card with two brands and PIN code in address: brands go to brands, address has PIN code', () {
      const electricalCardText = '''
Rajesh Sharma
Managing Director
Apex Electricals
Dealers in: WAGO, HAVELLS
Shop 14, Gandhi Road, Near City Center, Hyderabad - 500001
rajesh@apexelectricals.com
+91 98490 12345
''';

      final entities = OcrEntityExtractor.extract(electricalCardText);

      expect(entities.name, equals('Rajesh Sharma'));
      expect(PersonItem.computeInitials(entities.name!), equals('RS'));
      expect(entities.nameConfidence, greaterThanOrEqualTo(0.70));
      expect(entities.designation, equals('Managing Director'));
      expect(entities.company, equals('Apex Electricals'));
      expect(entities.brands, containsAll(['WAGO', 'HAVELLS']));
      expect(entities.address, isNotNull);
      expect(entities.address!, contains('Shop 14, Gandhi Road, Near City Center, Hyderabad - 500001'));
      expect(entities.address!, isNot(contains('WAGO')));
      expect(entities.address!, isNot(contains('HAVELLS')));
      expect(entities.emails, contains('rajesh@apexelectricals.com'));
      expect(entities.phones, contains('+91 98490 12345'));
    });
  });

  // ---------------------------------------------------------------------------
  // Section 1: Substring Audit & Whole-Word Matching Tests
  // ---------------------------------------------------------------------------
  group('1. Substring Audit Tests', () {
    test('WAGO is not treated as a location, and Manager is not matched by shorter keyword inside it', () {
      const cardWithManagerAndWago = '''
Vikram Joshi
Sales Manager
WAGO
Kothrud, Pune - 411038
vikram@wago.com
''';

      final entities = OcrEntityExtractor.extract(cardWithManagerAndWago);

      // "WAGO" must be extracted into brands
      expect(entities.brands, contains('WAGO'));
      // "WAGO" must NOT be treated as a location or address
      if (entities.address != null) {
        expect(entities.address, isNot(contains('WAGO')));
      }

      // "Sales Manager" must be extracted as the role, and not broken or falsely triggered as an address
      expect(entities.designation, equals('Sales Manager'));
      expect(entities.name, equals('Vikram Joshi'));
      expect(entities.address, contains('Pune - 411038'));
    });
  });

  // ---------------------------------------------------------------------------
  // Section 2: Brand Detection Beyond Fixed List Tests
  // ---------------------------------------------------------------------------
  group('2. Brand Detection Beyond Fixed List Tests', () {
    test('Short ALL-CAPS single-word lines (made-up brands NEXAGRID and VOLTIS) are extracted as brands, not name or address', () {
      const cardWithMadeUpBrands = '''
Arun Verma
Technical Director
Apex Power Systems Ltd
NEXAGRID
VOLTIS
Plot 12, GIDC Phase 2, Vapi - 396195
arun@apexpower.com
''';

      final entities = OcrEntityExtractor.extract(cardWithMadeUpBrands);

      // NEXAGRID and VOLTIS are detected as brand candidates
      expect(entities.brands, containsAll(['NEXAGRID', 'VOLTIS']));

      // Must not be misclassified as person name or company
      expect(entities.name, equals('Arun Verma'));
      expect(entities.company, equals('Apex Power Systems Ltd'));
      expect(entities.designation, equals('Technical Director'));

      // Address must not contain the brands
      expect(entities.address, isNotNull);
      expect(entities.address!, contains('GIDC Phase 2, Vapi - 396195'));
      expect(entities.address!, isNot(contains('NEXAGRID')));
      expect(entities.address!, isNot(contains('VOLTIS')));
    });
  });

  // ---------------------------------------------------------------------------
  // Section 3: Realistic Messy ML Kit OCR Fixtures
  // ---------------------------------------------------------------------------
  group('3. Realistic OCR Fixtures Tests', () {
    test('a) Name in ALL CAPS ("ANIL NAGAR") plus a title like "Mr." or "Dr."', () {
      const cardWithAllCapsNameAndTitle = '''
Mr. ANIL NAGAR
Managing Director
Bandhan Industries Ltd
Road No. 2, Hadapsar, Pune - 411013
aniln@bandhanindustries.com
''';

      final entities = OcrEntityExtractor.extract(cardWithAllCapsNameAndTitle);

      expect(entities.name, equals('Anil Nagar'));
      expect(entities.designation, equals('Managing Director'));
      expect(entities.company, equals('Bandhan Industries Ltd'));
      expect(entities.nameConfidence, greaterThanOrEqualTo(0.70));
      expect(PersonItem.computeInitials(entities.name!), equals('AN'));
    });

    test('b) Phone lines with labels: "M: +91 94055 09531", "Ph: 020-2345678"', () {
      const cardWithLabeledPhones = '''
Suresh Patil
Chief Engineer
Patil Solutions
M: +91 94055 09531
Ph: 020-2345678
suresh@patilsolutions.com
''';

      final entities = OcrEntityExtractor.extract(cardWithLabeledPhones);

      expect(entities.phones, containsAll(['+91 94055 09531', '020-2345678']));
      expect(entities.name, equals('Suresh Patil'));
      expect(entities.designation, equals('Chief Engineer'));
    });

    test('c) Address broken across 3 lines with the PIN on the last line', () {
      const cardWithMultilineAddress = '''
Kavita Iyer
Senior Architect
Design Studio Ltd
Bandhan House, Plot No. 42
Hadapsar Industrial Estate
Pune - 411013
kavita@designstudio.com
''';

      final entities = OcrEntityExtractor.extract(cardWithMultilineAddress);

      expect(entities.address, isNotNull);
      expect(entities.address!, contains('Plot No. 42'));
      expect(entities.address!, contains('Hadapsar Industrial Estate'));
      expect(entities.address!, contains('Pune - 411013'));
      expect(entities.name, equals('Kavita Iyer'));
    });

    test('d) Company name on the same line as the designation', () {
      const cardWithCombinedRoleAndCompany = '''
Rohan Deshmukh
Managing Director, Bandhan Industries Ltd
Hadapsar, Pune - 411013
rohan@bandhanindustries.com
''';

      final entities = OcrEntityExtractor.extract(cardWithCombinedRoleAndCompany);

      expect(entities.designation, equals('Managing Director'));
      expect(entities.company, equals('Bandhan Industries Ltd'));
      expect(entities.name, equals('Rohan Deshmukh'));
    });

    test('e) Two phone numbers and two emails on one card', () {
      const cardWithMultiContacts = '''
Amit Kulkarni
Director
Kulkarni Enterprises
amit@kulkarni.com
sales@kulkarni.com
M: +91 98220 11223
Ph: 020-2445566
''';

      final entities = OcrEntityExtractor.extract(cardWithMultiContacts);

      expect(entities.emails, containsAll(['amit@kulkarni.com', 'sales@kulkarni.com']));
      expect(entities.email, equals('amit@kulkarni.com')); // personal prioritized over sales
      expect(entities.phones, containsAll(['+91 98220 11223', '020-2445566']));
    });

    test('f) Noise lines like "www", "•", or a single stray character', () {
      const cardWithOcrNoise = '''
•
www
-
|
a
Rajesh Mehta
Consultant
Mehta Solutions
Pune - 411001
rajesh@mehtasolutions.com
''';

      final entities = OcrEntityExtractor.extract(cardWithOcrNoise);

      expect(entities.name, equals('Rajesh Mehta'));
      expect(entities.designation, equals('Consultant'));
      expect(entities.company, equals('Mehta Solutions'));
      // Noise tokens must NOT be added to key points or brands
      expect(entities.keyPoints, isNot(contains('•')));
      expect(entities.keyPoints, isNot(contains('www')));
      expect(entities.keyPoints, isNot(contains('a')));
    });
  });

  // ---------------------------------------------------------------------------
  // Section 4 & 5: Persistence, Display Check & Invalid Name Validator Tests
  // ---------------------------------------------------------------------------
  group('4 & 5. Persistence, Display & Existing Bad Records Tests', () {
    test('4. Confirm brands serialization to/from Map for Firestore persistence', () {
      const person = PersonItem(
        id: 'test_123',
        name: 'Anil Kumar',
        initials: 'AK',
        company: 'Bandhan Enterprises',
        role: 'Director',
        brands: ['WAGO', 'HAVELLS'],
      );

      final map = person.toMap();
      expect(map['brands'], equals(['WAGO', 'HAVELLS']));

      final reconstituted = PersonItem.fromMap(map, 'test_123');
      expect(reconstituted.brands, equals(['WAGO', 'HAVELLS']));
    });

    test('5. isLikelyInvalidName correctly flags "Nagar (Industrial Estate)," while accepting real names', () {
      expect(OcrEntityExtractor.isLikelyInvalidName('Nagar (Industrial Estate),'), isTrue);
      expect(OcrEntityExtractor.isLikelyInvalidName('Plot 42, Hadapsar Industrial Area'), isTrue);
      expect(OcrEntityExtractor.isLikelyInvalidName('Bandhan Industries Ltd'), isTrue);
      expect(OcrEntityExtractor.isLikelyInvalidName('info@bandhan.com'), isTrue);

      expect(OcrEntityExtractor.isLikelyInvalidName('Anil Kumar'), isFalse);
      expect(OcrEntityExtractor.isLikelyInvalidName('Dr. Sarah Chen'), isFalse);
      expect(OcrEntityExtractor.isLikelyInvalidName('Anil Nagar'), isFalse);
    });

    testWidgets('5. Dossier displays "Name may be wrong - Fix" prompt for bad names and opens edit dialog', (tester) async {
      const badNameProfile = PersonProfile(
        id: 'bad_person_1',
        name: 'Nagar (Industrial Estate),',
        role: 'Director',
        company: 'Bandhan Enterprises',
        location: 'Pune',
        initials: 'NE',
        relationshipType: RelationshipContextType.collaborator,
        relationshipStrength: 'Active',
        firstMet: '2026-01-01',
        lastInteraction: 'Yesterday',
        totalInteractions: 1,
        sharedEventsCount: 0,
        aiSummary: 'Summary context',
        brands: ['WAGO', 'HAVELLS'],
      );

      final mockPersonRepo = MockPersonDetailRepository(
        initialProfiles: {'bad_person_1': badNameProfile},
      );

      await tester.pumpWidget(
        RecallrScope(
          dependencies: RecallrDependencies.mock(
            personDetailRepository: mockPersonRepo,
          ),
          child: MaterialApp(
            home: PersonDetailScreen(
              personId: 'bad_person_1',
              initialProfile: badNameProfile,
              repository: mockPersonRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Warning banner must be visible
      expect(find.byKey(const Key('name_warning_banner')), findsOneWidget);
      expect(find.text('Name may be wrong - Fix'), findsOneWidget);

      // Tap the Fix button
      await tester.tap(find.byKey(const Key('fix_name_button')));
      await tester.pumpAndSettle();

      // Edit dialog appears prefilled
      expect(find.text('Edit Contact Details'), findsOneWidget);
      expect(find.byKey(const Key('edit_person_name_field')), findsOneWidget);
      expect(find.text('Nagar (Industrial Estate),'), findsNWidgets(2));

      // Edit the name to "Anil Nagar"
      await tester.enterText(find.byKey(const Key('edit_person_name_field')), 'Anil Nagar');
      await tester.pumpAndSettle();

      // Save changes
      await tester.tap(find.byKey(const Key('save_person_edit_button')));
      await tester.pumpAndSettle();

      // Profile is updated in repository and state
      final updatedInRepo = await mockPersonRepo.getProfile('bad_person_1');
      expect(updatedInRepo, isNotNull);
      expect(updatedInRepo!.name, equals('Anil Nagar'));
      expect(updatedInRepo.initials, equals('AN'));

      // Warning banner is now gone!
      expect(find.byKey(const Key('name_warning_banner')), findsNothing);
    });

    testWidgets('4. PersonProfileHeader displays location pin only for location, and tag chips for brands', (tester) async {
      const profileWithBrands = PersonProfile(
        id: 'p_1',
        name: 'Rajesh Sharma',
        role: 'Director',
        company: 'Apex Electricals',
        location: 'Pune, Maharashtra',
        initials: 'RS',
        relationshipType: RelationshipContextType.collaborator,
        relationshipStrength: 'Active',
        firstMet: '2026-01-01',
        lastInteraction: 'Today',
        totalInteractions: 1,
        sharedEventsCount: 0,
        aiSummary: 'Summary',
        brands: ['WAGO', 'HAVELLS'],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PersonProfileHeader(profile: profileWithBrands),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Exactly 1 location pin icon for location
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
      expect(find.text('Pune, Maharashtra'), findsOneWidget);

      // 2 tag icons for WAGO and HAVELLS
      expect(find.byIcon(Icons.sell_outlined), findsNWidgets(2));
      expect(find.text('WAGO'), findsOneWidget);
      expect(find.text('HAVELLS'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Widget Tests: CaptureReviewView Edit & Confirmation UI Tests
  // ---------------------------------------------------------------------------
  group('CaptureReviewView Edit & Confirmation UI Tests', () {
    testWidgets('c.2) Low confidence or null name triggers edit screen with highlighted name field', (tester) async {
      const lowConfidenceData = CaptureReviewData(
        title: 'Business Card',
        summary: 'Scanned visiting card context.',
        personName: 'Anil N',
        nameConfidence: 0.55,
        needsNameConfirmation: true,
        companyName: 'Bandhan Enterprises',
        location: 'Plot No. 42, Industrial Estate, Pune - 411018',
        address: 'Plot No. 42, Industrial Estate, Pune - 411018',
        brands: ['WAGO', 'HAVELLS'],
        contactDetails: {
          'email': 'aniln@bandhanindustries.com',
          'phone': '+91 98765 43210',
        },
      );

      CaptureReviewData? savedData;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CaptureReviewView(
              type: CaptureType.businessCard,
              reviewData: lowConfidenceData,
              onEdit: () {},
              onSave: () {},
              onUpdateData: (updated) => savedData = updated,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Must show the edit screen because confidence < 0.70
      expect(find.textContaining('Please verify contact name'), findsOneWidget);
      expect(find.byKey(const Key('card_ocr_name_field')), findsOneWidget);
      expect(find.text('Anil N'), findsOneWidget);
      expect(find.text('Initials: AN'), findsOneWidget);

      // Brands must be displayed with brand chip
      expect(find.text('WAGO'), findsOneWidget);
      expect(find.text('HAVELLS'), findsOneWidget);

      // Edit the name to "Anil Nair"
      await tester.enterText(find.byKey(const Key('card_ocr_name_field')), 'Anil Nair');
      await tester.pumpAndSettle();

      expect(find.text('Initials: AN'), findsOneWidget);

      // Tap Confirm & Save to Memory
      await tester.tap(find.text('Confirm & Save to Memory'));
      await tester.pumpAndSettle();

      expect(savedData, isNotNull);
      expect(savedData!.personName, equals('Anil Nair'));
      expect(PersonItem.computeInitials(savedData!.personName!), equals('AN'));
      expect(savedData!.needsNameConfirmation, isFalse);
    });

    testWidgets('Brands use tag icon, while address uses location pin icon in CaptureReviewView', (tester) async {
      const highConfidenceData = CaptureReviewData(
        title: 'Rajesh Sharma',
        summary: 'Scanned visiting card context.',
        personName: 'Rajesh Sharma',
        nameConfidence: 0.95,
        needsNameConfirmation: false,
        companyName: 'Apex Electricals',
        location: 'Shop 14, Gandhi Road, Hyderabad - 500001',
        address: 'Shop 14, Gandhi Road, Hyderabad - 500001',
        brands: ['WAGO', 'HAVELLS'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CaptureReviewView(
              type: CaptureType.businessCard,
              reviewData: highConfidenceData,
              onEdit: () {},
              onSave: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In preview mode:
      expect(find.text('Rajesh Sharma'), findsWidgets);
      expect(find.text('Shop 14, Gandhi Road, Hyderabad - 500001'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);

      // Brands have sell_outlined tag icon
      expect(find.byIcon(Icons.sell_outlined), findsNWidgets(2));
    });
  });
}
