import { describe, expect, it } from 'vitest';

import { bugAnalysisRequestSchema } from '../src/schemas/bug_analysis_request_schema.js';

describe('bugAnalysisRequestSchema', () => {
  it('accepts a valid request', () => {
    const result = bugAnalysisRequestSchema.safeParse(validRequest());

    expect(result.success).toBe(true);
  });

  it('rejects missing title and empty description', () => {
    expect(
      bugAnalysisRequestSchema.safeParse({
        ...validRequest(),
        title: undefined,
      }).success,
    ).toBe(false);

    expect(
      bugAnalysisRequestSchema.safeParse({
        ...validRequest(),
        description: '',
      }).success,
    ).toBe(false);
  });

  it('rejects invalid platform and excessive lengths', () => {
    expect(
      bugAnalysisRequestSchema.safeParse({
        ...validRequest(),
        environment: { platform: 'desktop' },
      }).success,
    ).toBe(false);

    expect(
      bugAnalysisRequestSchema.safeParse({
        ...validRequest(),
        title: 'x'.repeat(121),
      }).success,
    ).toBe(false);
  });

  it('accepts omitted optional fields and logs within limit', () => {
    expect(
      bugAnalysisRequestSchema.safeParse({
        ...validRequest(),
        environment: { platform: 'android' },
        logs: 'x'.repeat(12000),
      }).success,
    ).toBe(true);
  });

  it('defaults omitted preferences to enabled and accepts explicit booleans', () => {
    const defaulted = bugAnalysisRequestSchema.parse(validRequest());

    expect(defaulted.preferences).toEqual({
      severity: true,
      priority: true,
      testCases: true,
      rootCause: true,
      screenshotAnalysis: true,
    });

    const result = bugAnalysisRequestSchema.safeParse({
      ...validRequest(),
      preferences: {
        severity: false,
        priority: true,
        testCases: false,
        rootCause: false,
        screenshotAnalysis: false,
      },
    });

    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.preferences.severity).toBe(false);
      expect(result.data.preferences.testCases).toBe(false);
      expect(result.data.preferences.screenshotAnalysis).toBe(false);
    }
  });
});

function validRequest() {
  return {
    title: 'Login button stuck loading',
    description: 'The login screen remains loading after valid credentials.',
    expectedBehavior: 'The dashboard should open.',
    actualBehavior: 'The loading indicator remains visible.',
    environment: {
      platform: 'android',
      device: 'Pixel 9',
      osVersion: 'Android 16',
      appVersion: '1.0.0',
    },
    logs: 'Stack trace',
  };
}
