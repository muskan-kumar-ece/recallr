import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:recaller/core/theme/theme.dart';
import 'package:recaller/core/widgets/overlays/qr_bio_sheet.dart';
import 'package:recaller/screens/settings/settings_screen.dart';

void main() {
  tearDown(() {
    RecallrThemeModeController.mode.value = ThemeMode.system;
  });

  test('light and dark themes expose different accessible surface palettes', () {
    final dark = RecallrTheme.darkTheme;
    final light = RecallrTheme.lightTheme;

    expect(dark.brightness, Brightness.dark);
    expect(light.brightness, Brightness.light);
    expect(dark.scaffoldBackgroundColor, isNot(light.scaffoldBackgroundColor));
    expect(dark.extension<RecallrThemeColors>()!.textPrimary, isNot(light.extension<RecallrThemeColors>()!.textPrimary));
    expect(light.colorScheme.onSurface, light.extension<RecallrThemeColors>()!.textPrimary);
  });

  testWidgets('QR identity sheet renders a real QR code and no fake scan action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: RecallrTheme.darkTheme,
        home: const Scaffold(
          body: QrBioSheet(name: 'Test User', email: 'test@example.com'),
        ),
      ),
    );

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Copy Profile Link'), findsOneWidget);
    expect(find.text('Simulate Verified Scan'), findsNothing);
  });

  testWidgets('settings theme selector updates the shared theme preference', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: RecallrTheme.darkTheme,
        darkTheme: RecallrTheme.darkTheme,
        home: const SettingsScreen(),
      ),
    );

    expect(find.byKey(const ValueKey<String>('theme_mode_selector')), findsOneWidget);
    await tester.tap(find.text('Light'));
    await tester.pump();

    expect(RecallrThemeModeController.mode.value, ThemeMode.light);
  });
}
