import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/routing/deep_link_manager.dart';
import 'package:recaller/core/routing/recallr_routes.dart';

void main() {
  group('RecallrRoutes Tests', () {
    test('parametric path generators format correctly', () {
      expect(RecallrRoutes.personPath('abc123'), '/person/abc123');
      expect(RecallrRoutes.companyPath('cmp456'), '/company/cmp456');
      expect(RecallrRoutes.eventPath('evt789'), '/event/evt789');
      expect(RecallrRoutes.filePath('fil101'), '/file/fil101');
      expect(RecallrRoutes.interactionPath('int202'), '/interaction/int202');
      expect(RecallrRoutes.followUpPath('fol303'), '/follow-up/fol303');
    });

    test('primary routes match contracts', () {
      expect(RecallrRoutes.home, '/home');
      expect(RecallrRoutes.people, '/people');
      expect(RecallrRoutes.ask, '/ask');
      expect(RecallrRoutes.activity, '/activity');
      expect(RecallrRoutes.capture, '/capture');
      expect(RecallrRoutes.auth, '/auth');
      expect(RecallrRoutes.settings, '/settings');
    });
  });

  group('DeepLinkManager Tests', () {
    final dlm = DeepLinkManager();

    setUp(() {
      dlm.consumePendingPath(); // clean state
    });

    test('ignores root and auth paths as pending deep links', () {
      dlm.setPendingPath('/');
      expect(dlm.pendingPath, isNull);

      dlm.setPendingPath('/auth');
      expect(dlm.pendingPath, isNull);

      dlm.setPendingPath('/home');
      expect(dlm.pendingPath, isNull);
    });

    test('records and consumes parametric deep-link path correctly', () {
      dlm.setPendingPath('/person/abc123');
      expect(dlm.pendingPath, '/person/abc123');

      final consumed = dlm.consumePendingPath();
      expect(consumed, '/person/abc123');
      expect(dlm.pendingPath, isNull);
    });
  });
}