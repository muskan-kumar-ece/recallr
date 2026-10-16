import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaller/core/security/security.dart';

void main() {
  group('Phase 13F-01: Input Sanitizer & Validation Unit Tests', () {
    test('1. Null-byte removal and control char stripping in sanitizeQuery', () {
      const maliciousQuery = 'What did\x00 I discuss\x07 with\x1B Priya\x7F?';
      final clean = InputSanitizer.sanitizeQuery(maliciousQuery);
      expect(clean, equals('What did I discuss with Priya ?'));
      expect(clean.contains('\x00'), isFalse);
      expect(clean.contains('\x07'), isFalse);
      expect(clean.contains('\x1B'), isFalse);
    });

    test('2. Query length bounding enforces max 500 characters', () {
      final hugeQuery = 'A' * 1000;
      final clean = InputSanitizer.sanitizeQuery(hugeQuery, maxLength: 500);
      expect(clean.length, equals(500));
    });

    test('3. Multiline text sanitization preserves valid newlines and tabs while stripping control chars', () {
      const multilineText = "Line 1: Meeting notes\r\n\t* Item 1\x00\n\t* Item 2\x0C\nSummary completed.";
      final clean = InputSanitizer.sanitizeText(multilineText);
      expect(clean, contains('Line 1: Meeting notes\n\t* Item 1\n\t* Item 2\nSummary completed.'));
      expect(clean.contains('\x00'), isFalse);
      expect(clean.contains('\x0C'), isFalse);
    });

    test('4. Name sanitization handles unicode, diacritics, and international names gracefully', () {
      const internationalName = "  Dr. François O'Connor-Müller \x00\x08 ";
      final clean = InputSanitizer.sanitizeName(internationalName);
      expect(clean, equals("Dr. François O'Connor-Müller"));
    });

    test('5. Email normalization lowercases valid emails and rejects malformed inputs', () {
      expect(InputSanitizer.sanitizeEmail('  Priya.Sharma@Microsoft.COM \x00 '), equals('priya.sharma@microsoft.com'));
      expect(InputSanitizer.sanitizeEmail('invalid-email-no-at.com'), isNull);
      expect(InputSanitizer.sanitizeEmail('@missing-user.com'), isNull);
      expect(InputSanitizer.sanitizeEmail('missing-domain@'), isNull);
      expect(InputSanitizer.sanitizeEmail(''), isNull);
      expect(InputSanitizer.sanitizeEmail(null), isNull);
    });

    test('6. Phone normalization filters invalid characters and validates plausible lengths', () {
      expect(InputSanitizer.sanitizePhone('+1 (555) 234-5678'), equals('+1 (555) 234-5678'));
      expect(InputSanitizer.sanitizePhone('+91 98765 43210'), equals('+91 98765 43210'));
      expect(InputSanitizer.sanitizePhone('123'), isNull); // Too short
      expect(InputSanitizer.sanitizePhone('abc-invalid-phone'), isNull);
      expect(InputSanitizer.sanitizePhone(null), isNull);
    });

    test('7. Storage path validation rejects path traversal, backslashes, and cross-UID injection', () {
      const expectedUid = 'usr_abc_123';
      
      // Valid path
      expect(InputSanitizer.isValidStoragePath('users/usr_abc_123/captures/cap_101/original.jpg', expectedUid), isTrue);

      // Path traversal attempts
      expect(InputSanitizer.isValidStoragePath('users/usr_abc_123/captures/../cap_101/original.jpg', expectedUid), isFalse);
      expect(InputSanitizer.isValidStoragePath('users/usr_abc_123/captures/cap_101/../../etc/passwd', expectedUid), isFalse);

      // Wrong UID injection
      expect(InputSanitizer.isValidStoragePath('users/usr_attacker/captures/cap_101/original.jpg', expectedUid), isFalse);

      // Double slash or backslash
      expect(InputSanitizer.isValidStoragePath('users/usr_abc_123//captures/cap_101/original.jpg', expectedUid), isFalse);
      expect(InputSanitizer.isValidStoragePath('users\\usr_abc_123\\captures\\cap_101\\original.jpg', expectedUid), isFalse);
    });
  });

  group('Phase 13F-01: Environment Configuration & Log Redaction Tests', () {
    test('8. EnvironmentConfig supports development, staging, and production environments', () {
      expect(AppEnvironment.fromEnvironment('dev'), equals(AppEnvironment.development));
      expect(AppEnvironment.fromEnvironment('staging'), equals(AppEnvironment.staging));
      expect(AppEnvironment.fromEnvironment('prod'), equals(AppEnvironment.production));
    });

    test('9. EnvironmentConfig.sanitizeForLog redacts sensitive credentials and tokens', () {
      const logWithApiKey = 'Error connecting with key AIzaSyA123456789012345678901234567890B to provider';
      final cleanApiKey = EnvironmentConfig.sanitizeForLog(logWithApiKey);
      expect(cleanApiKey, contains('[REDACTED_API_KEY]'));
      expect(cleanApiKey, isNot(contains('AIzaSy')));

      const logWithToken = 'Authorization failed for Header: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.t-ID';
      final cleanToken = EnvironmentConfig.sanitizeForLog(logWithToken);
      expect(cleanToken, contains('Bearer [REDACTED_TOKEN]'));

      const logWithPath = 'Fetched media from users/usr_secret_uid_1234567890/captures/cap_1';
      final cleanPath = EnvironmentConfig.sanitizeForLog(logWithPath);
      expect(cleanPath, contains('users/[REDACTED_UID]/'));
    });

    test('10. Repository code audit: Zero hardcoded Gemini API keys across AI service layers', () {
      final aiDir = Directory('lib/services/ai');
      final dartFiles = aiDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        expect(
          content.contains(RegExp(r'AIza[0-9A-Za-z\-_]{30,}')),
          isFalse,
          reason: 'Hardcoded API key detected in ${file.path}',
        );
        expect(
          content.contains('GEMINI_API_KEY ='),
          isFalse,
          reason: 'Hardcoded GEMINI_API_KEY assignment in ${file.path}',
        );
      }
    });
  });
}