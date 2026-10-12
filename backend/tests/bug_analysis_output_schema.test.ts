import { describe, expect, it } from 'vitest';

import type { BugAnalysisOutput } from '../src/schemas/bug_analysis_output_schema.js';
import { bugAnalysisOutputSchema } from '../src/schemas/bug_analysis_output_schema.js';

describe('bugAnalysisOutputSchema', () => {
  it('accepts valid structured output', () => {
    expect(bugAnalysisOutputSchema.safeParse(validOutput()).success).toBe(true);
  });

  it('rejects invalid enum values', () => {
    expect(
      bugAnalysisOutputSchema.safeParse({
        ...validOutput(),
        severity: 'blocker',
      }).success,
    ).toBe(false);
    expect(
      bugAnalysisOutputSchema.safeParse({
        ...validOutput(),
        priority: 'p9',
      }).success,
    ).toBe(false);
    expect(
      bugAnalysisOutputSchema.safeParse({
        ...validOutput(),
        testCases: [{ ...validOutput().testCases[0], type: 'happyPath' }],
      }).success,
    ).toBe(false);
  });

  it('rejects confidence and score outside valid ranges', () => {
    expect(
      bugAnalysisOutputSchema.safeParse({
        ...validOutput(),
        rootCauseConfidence: -0.1,
      }).success,
    ).toBe(false);
    expect(
      bugAnalysisOutputSchema.safeParse({
        ...validOutput(),
        rootCauseConfidence: 1.1,
      }).success,
    ).toBe(false);
    expect(
      bugAnalysisOutputSchema.safeParse({
        ...validOutput(),
        qualityScore: -1,
      }).success,
    ).toBe(false);
    expect(
      bugAnalysisOutputSchema.safeParse({
        ...validOutput(),
        qualityScore: 101,
      }).success,
    ).toBe(false);
  });

  it('accepts deterministic disabled sections', () => {
    expect(
      bugAnalysisOutputSchema.safeParse({
        ...validOutput(),
        severity: null,
        severityReason: null,
        priority: null,
        priorityReason: null,
        testCases: [],
        possibleRootCause: null,
        rootCauseConfidence: null,
      }).success,
    ).toBe(true);
  });

  it('rejects mismatched nullable section pairs', () => {
    expect(
      bugAnalysisOutputSchema.safeParse({
        ...validOutput(),
        severity: null,
      }).success,
    ).toBe(false);
    expect(
      bugAnalysisOutputSchema.safeParse({
        ...validOutput(),
        possibleRootCause: null,
      }).success,
    ).toBe(false);
  });
});

export function validOutput(): BugAnalysisOutput {
  return {
    severity: 'high',
    severityReason: 'The issue blocks a core workflow.',
    priority: 'p1',
    priorityReason: 'The issue should be addressed quickly.',
    reproductionSteps: ['Open the app', 'Submit valid credentials'],
    testCases: [
      {
        id: 'TC-01',
        type: 'positive',
        title: 'Valid login completes successfully',
        given: 'A registered user is on the login screen',
        when: 'Valid credentials are submitted',
        then: 'The user should reach the dashboard',
      },
    ],
    possibleRootCause:
      'A possible cause is that loading state is not reset after authentication.',
    rootCauseConfidence: 0.72,
    missingInformation: ['Network conditions were not provided.'],
    qualityScore: 82,
  };
}
