import { describe, expect, it } from 'vitest';

import type { DuplicateCheckRequest } from '../src/schemas/duplicate_check_request_schema.js';
import { duplicateCheckRequestSchema } from '../src/schemas/duplicate_check_request_schema.js';

describe('duplicateCheckRequestSchema', () => {
  it('accepts a valid duplicate check request', () => {
    expect(duplicateCheckRequestSchema.safeParse(validDuplicateRequest()).success).toBe(
      true,
    );
  });

  it('requires candidates but caps them at five', () => {
    expect(
      duplicateCheckRequestSchema.safeParse({
        ...validDuplicateRequest(),
        candidates: [],
      }).success,
    ).toBe(false);

    expect(
      duplicateCheckRequestSchema.safeParse({
        ...validDuplicateRequest(),
        candidates: Array.from({ length: 6 }, (_, index) => ({
          ...validDuplicateRequest().candidates[0],
          id: `bug-${index}`,
        })),
      }).success,
    ).toBe(false);
  });

  it('rejects logs, screenshots, and invalid status values', () => {
    expect(
      duplicateCheckRequestSchema.safeParse({
        ...validDuplicateRequest(),
        bug: {
          ...validDuplicateRequest().bug,
          logs: 'Do not send logs here.',
        },
      }).success,
    ).toBe(false);

    expect(
      duplicateCheckRequestSchema.safeParse({
        ...validDuplicateRequest(),
        candidates: [
          {
            ...validDuplicateRequest().candidates[0],
            screenshot: '/tmp/local.png',
            status: 'done',
          },
        ],
      }).success,
    ).toBe(false);
  });
});

export function validDuplicateRequest(): DuplicateCheckRequest {
  return {
    bug: {
      title: 'Login button stuck loading',
      description: 'The login screen remains loading after valid credentials.',
      expectedBehavior: 'The dashboard should open.',
      actualBehavior: 'The loading indicator remains visible.',
      platform: 'android',
    },
    candidates: [
      {
        id: 'bug-001',
        title: 'Login remains loading',
        description: 'Valid login never reaches dashboard.',
        expectedBehavior: 'The dashboard should open.',
        actualBehavior: 'The login spinner never clears.',
        platform: 'android',
        severity: 'high',
        status: 'open',
      },
    ],
  };
}
