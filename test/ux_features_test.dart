import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/utils/share_formatter.dart';
import 'package:recaller/core/widgets/destructive_confirm_dialog.dart';
import 'package:recaller/core/widgets/share_bottom_sheet.dart';
import 'package:recaller/features/activity/models/activity_models.dart';
import 'package:recaller/features/ask/models/ask_models.dart';
import 'package:recaller/features/follow_ups/models/follow_up_models.dart';
import 'package:recaller/features/people/models/person_item.dart';
import 'package:recaller/features/person_detail/models/person_profile_model.dart';

void main() {
  group('ShareFormatter Unit Tests', () {
    final sampleProfile = PersonProfile(
      id: 'per_test_1',
      name: 'Rohan Deshmukh',
      role: 'Founding Engineer',
      company: 'Antigravity Labs',
      location: 'Bangalore, KA',
      email: 'rohan@antigravity.io',
      phone: '+91 98765 43210',
      brands: ['WAGO', 'Bosch'],
      aiSummary: 'Leading edge distributed systems architect.',
      keyTakeaways: ['Met at DevCon 2026', 'Interested in edge AI'],
      lastInteraction: '2 days ago',
      initials: 'RD',
      relationshipType: RelationshipContextType.collaborator,
      relationshipStrength: 'Strong Partner',
      firstMet: 'Jan 2026',
      totalInteractions: 5,
      sharedEventsCount: 2,
    );

    test('formatPersonSummary generates rich formatted markdown', () {
      final summary = ShareFormatter.formatPersonSummary(sampleProfile);

      expect(summary, contains('👤 *Rohan Deshmukh*'));
      expect(summary, contains('💼 Founding Engineer · Antigravity Labs'));
      expect(summary, contains('📍 Bangalore, KA'));
      expect(summary, contains('✉️ rohan@antigravity.io'));
      expect(summary, contains('📞 +91 98765 43210'));
      expect(summary, contains('🏷️ Brands / Tags: WAGO, Bosch'));
      expect(summary, contains('🧠 *Context & Summary:*'));
      expect(summary, contains('• Met at DevCon 2026'));
      expect(summary, contains('⏱️ *Last Interaction:* 2 days ago'));
      expect(summary, contains('_Shared via Recallr_'));
    });

    test('toVCard generates RFC 2426 compliant vCard 3.0', () {
      final vcard = ShareFormatter.toVCard(sampleProfile);

      expect(vcard, startsWith('BEGIN:VCARD'));
      expect(vcard, contains('VERSION:3.0'));
      expect(vcard, contains('FN:Rohan Deshmukh'));
      expect(vcard, contains('N:Deshmukh;Rohan;;;'));
      expect(vcard, contains('ORG:Antigravity Labs'));
      expect(vcard, contains('TITLE:Founding Engineer'));
      expect(vcard, contains('EMAIL;TYPE=INTERNET:rohan@antigravity.io'));
      expect(vcard, contains('TEL;TYPE=CELL:+91 98765 43210'));
      expect(vcard, contains('ADR;TYPE=WORK:;;Bangalore\\, KA;;;;'));
      expect(vcard, endsWith('END:VCARD'));
    });

    test('formatPersonItemSummary and personItemToVCard support lightweight PersonItem', () {
      const item = PersonItem(
        id: 'pi_1',
        name: 'Sarah Connor',
        role: 'CTO',
        company: 'Cyberdyne',
        email: 'sarah@resistance.org',
        phone: '+1 555 0199',
        locationOrEvent: 'Los Angeles',
        brands: ['Skynet', 'Infiltration'],
        initials: 'SC',
      );

      final summary = ShareFormatter.formatPersonItemSummary(item);
      expect(summary, contains('👤 *Sarah Connor*'));
      expect(summary, contains('💼 CTO · Cyberdyne'));
      expect(summary, contains('📍 Los Angeles'));

      final vcard = ShareFormatter.personItemToVCard(item);
      expect(vcard, contains('FN:Sarah Connor'));
      expect(vcard, contains('ORG:Cyberdyne'));
      expect(vcard, contains('EMAIL;TYPE=INTERNET:sarah@resistance.org'));
    });

    test('formatActivityNote formats meeting encounter notes', () {
      final act = ActivityItem(
        id: 'act_1',
        type: ActivityType.meeting,
        period: TimelinePeriod.today,
        timestamp: 'Today at 3:00 PM',
        title: 'Q4 Architecture Review',
        summary: 'Discussed migrating AI inference behind Firebase Cloud Functions.',
        personName: 'Anil Sharma',
        personRole: 'VP Engineering',
        companyName: 'WAGO India',
        location: 'Pune Tech Park',
        relationshipIndicator: 'Core Network',
        targetRoute: '/activity',
        actionLabel: 'View Meeting',
      );

      final text = ShareFormatter.formatActivityNote(act);
      expect(text, contains('📝 *Q4 Architecture Review*'));
      expect(text, contains('👤 Contact: Anil Sharma (VP Engineering · WAGO India)'));
      expect(text, contains('📍 Location: Pune Tech Park'));
      expect(text, contains('Discussed migrating AI inference'));
      expect(text, contains('🔗 Relationship: Core Network'));
    });

    test('formatFollowUp formats commitment reminder', () {
      final followUp = FollowUpItem(
        id: 'fu_1',
        title: 'Send updated system architecture diagram',
        context: 'Follow-up from Tuesday design review meeting.',
        dueDate: 'Tomorrow',
        commitmentType: CommitmentType.iPromised,
        status: FollowUpStatus.dueToday,
        personName: 'Priya Verma',
        targetRoute: '/follow-ups',
      );

      final text = ShareFormatter.formatFollowUp(followUp);
      expect(text, contains('📌 *I Promised: Send updated system architecture diagram*'));
      expect(text, contains('👤 With: Priya Verma'));
      expect(text, contains('📅 Due: Tomorrow'));
    });

    test('formatAiAnswer formats question, synthesis, and sources', () {
      const source = MemorySource(
        id: 'src_1',
        sourceType: 'Meeting Note',
        icon: Icons.notes,
        personName: 'Vikram Seth',
        personRole: 'Principal Architect',
        company: 'Nexus Corp',
        date: 'Oct 20, 2026',
        excerpt: 'Agreed to adopt Flutter web for desktop kiosk',
      );

      final text = ShareFormatter.formatAiAnswer(
        query: 'What was discussed about Flutter web?',
        answer: 'Vikram confirmed plans to adopt Flutter web for desktop kiosks.',
        sources: [source],
      );

      expect(text, contains('💬 *Query:* "What was discussed about Flutter web?"'));
      expect(text, contains('Vikram confirmed plans to adopt'));
      expect(text, contains('• [Meeting Note] (Vikram Seth · Nexus Corp): "Agreed to adopt Flutter web for desktop kiosk"'));
    });
  });

  group('DestructiveConfirmDialog Widget Tests', () {
    testWidgets('DestructiveConfirmDialog renders correctly and handles Cancel/Confirm', (tester) async {
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await DestructiveConfirmDialog.show(
                    context,
                    title: 'Delete Contact',
                    message: 'Are you sure you want to permanently delete this contact?',
                    confirmLabel: 'Confirm Delete',
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Contact'), findsOneWidget);
      expect(find.text('Are you sure you want to permanently delete this contact?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm Delete'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(dialogResult, isFalse);

      // Open dialog again and tap Confirm Delete
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm Delete'));
      await tester.pumpAndSettle();
      expect(dialogResult, isTrue);
    });
  });

  group('ShareBottomSheet Widget Tests', () {
    testWidgets('ShareBottomSheet renders preview and action buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ShareBottomSheet.show(
                    context,
                    title: 'Share Contact Card',
                    subtitle: 'Anil Sharma · WAGO India',
                    textSummary: '👤 *Anil Sharma*\n💼 VP Engineering',
                    vCardContent: 'BEGIN:VCARD\nFN:Anil Sharma\nEND:VCARD',
                  );
                },
                child: const Text('Open Share Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Share Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Share Contact Card'), findsOneWidget);
      expect(find.text('Anil Sharma · WAGO India'), findsOneWidget);
      expect(find.text('Copy Formatted Summary'), findsOneWidget);
      expect(find.text('Copy vCard Contact (.vcf)'), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);
    });
  });
}
