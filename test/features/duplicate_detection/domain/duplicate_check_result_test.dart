import 'package:bugpilot_ai/models/duplicate_check_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DuplicateCheckResult', () {
    test('parses stable similarity values', () {
      final result = DuplicateCheckResult.fromJson({
        'matches': [
          {
            'bugId': 'bug-001',
            'similarity': 'likelyDuplicate',
            'confidence': 0.83,
            'reason': 'Both describe login loading.',
          },
          {
            'bugId': 'bug-002',
            'similarity': 'related',
            'confidence': 0.58,
            'reason': 'Both affect login.',
          },
          {
            'bugId': 'bug-003',
            'similarity': 'notDuplicate',
            'confidence': 0.2,
            'reason': 'Different symptom.',
          },
        ],
      });

      expect(result.matches[0].similarity, DuplicateSimilarity.likelyDuplicate);
      expect(result.matches[1].similarity, DuplicateSimilarity.related);
      expect(result.matches[2].similarity, DuplicateSimilarity.notDuplicate);
      expect(result.matches[0].confidence, 0.83);
      expect(result.matches[0].reason, 'Both describe login loading.');
    });

    test('rejects invalid similarity values', () {
      expect(
        () => DuplicateCheckResult.fromJson({
          'matches': [
            {
              'bugId': 'bug-001',
              'similarity': 'exactDuplicate',
              'confidence': 0.83,
              'reason': 'Nope.',
            },
          ],
        }),
        throwsArgumentError,
      );
    });

    test('rejects confidence outside the valid range', () {
      expect(
        () => DuplicateCheckResult.fromJson({
          'matches': [
            {
              'bugId': 'bug-001',
              'similarity': 'related',
              'confidence': 1.2,
              'reason': 'Nope.',
            },
          ],
        }),
        throwsFormatException,
      );
    });
  });
}
