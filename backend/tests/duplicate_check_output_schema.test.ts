import { describe, expect, it } from 'vitest';

import type { DuplicateCheckOutput } from '../src/schemas/duplicate_check_output_schema.js';
import { duplicateCheckOutputSchema } from '../src/schemas/duplicate_check_output_schema.js';

describe('duplicateCheckOutputSchema', () => {
  it('accepts stable similarity classifications', () => {
    expect(duplicateCheckOutputSchema.safeParse(validDuplicateOutput()).success).toBe(
      true,
    );
  });

  it('rejects invalid enum values and confidence ranges', () => {
    expect(
      duplicateCheckOutputSchema.safeParse({
        matches: [
          {
            ...validDuplicateOutput().matches[0],
            similarity: 'exactDuplicate',
          },
        ],
      }).success,
    ).toBe(false);

    expect(
      duplicateCheckOutputSchema.safeParse({
        matches: [
          {
            ...validDuplicateOutput().matches[0],
            confidence: 1.2,
          },
        ],
      }).success,
    ).toBe(false);
  });
});

export function validDuplicateOutput(): DuplicateCheckOutput {
  return {
    matches: [
      {
        bugId: 'bug-001',
        similarity: 'likelyDuplicate',
        confidence: 0.83,
        reason:
          'Both reports describe the login flow remaining stuck after valid credentials.',
      },
      {
        bugId: 'bug-002',
        similarity: 'related',
        confidence: 0.54,
        reason: 'Both reports affect login but describe different symptoms.',
      },
      {
        bugId: 'bug-003',
        similarity: 'notDuplicate',
        confidence: 0.22,
        reason: 'The reports describe different workflows.',
      },
    ],
  };
}
