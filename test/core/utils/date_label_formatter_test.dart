import 'package:bugpilot_ai/core/utils/date_label_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats recent date labels deterministically', () {
    final now = DateTime(2026, 8, 19, 12);

    expect(formatRecentDateLabel(DateTime(2026, 8, 19, 8), now: now), 'Today');
    expect(
      formatRecentDateLabel(DateTime(2026, 8, 18, 23), now: now),
      'Yesterday',
    );
    expect(
      formatRecentDateLabel(DateTime(2026, 8, 17, 10), now: now),
      'Aug 17',
    );
  });
}
