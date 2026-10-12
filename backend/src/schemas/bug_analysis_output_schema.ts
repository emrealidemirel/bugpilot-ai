import { z } from 'zod';

export const aiTestCaseSchema = z.object({
  id: z.string().trim().min(1),
  type: z.enum(['positive', 'negative', 'edgeCase']),
  title: z.string().trim().min(1),
  given: z.string().trim().min(1),
  when: z.string().trim().min(1),
  then: z.string().trim().min(1),
});

export const bugAnalysisOutputSchema = z.object({
  severity: z.enum(['critical', 'high', 'medium', 'low']).nullable(),
  severityReason: z.string().trim().min(1).nullable(),
  priority: z.enum(['p0', 'p1', 'p2', 'p3']).nullable(),
  priorityReason: z.string().trim().min(1).nullable(),
  reproductionSteps: z.array(z.string().trim().min(1)).min(1).max(8),
  testCases: z.array(aiTestCaseSchema).max(5),
  possibleRootCause: z.string().trim().min(1).nullable(),
  rootCauseConfidence: z.number().min(0).max(1).nullable(),
  missingInformation: z.array(z.string().trim().min(1)),
  qualityScore: z.number().int().min(0).max(100),
}).superRefine((value, ctx) => {
  if ((value.severity === null) !== (value.severityReason === null)) {
    ctx.addIssue({
      code: 'custom',
      path: ['severityReason'],
      message: 'severity and severityReason must both be null or both be set.',
    });
  }

  if ((value.priority === null) !== (value.priorityReason === null)) {
    ctx.addIssue({
      code: 'custom',
      path: ['priorityReason'],
      message: 'priority and priorityReason must both be null or both be set.',
    });
  }

  if (
    (value.possibleRootCause === null) !==
    (value.rootCauseConfidence === null)
  ) {
    ctx.addIssue({
      code: 'custom',
      path: ['rootCauseConfidence'],
      message:
        'possibleRootCause and rootCauseConfidence must both be null or both be set.',
    });
  }
});

export type BugAnalysisOutput = z.infer<typeof bugAnalysisOutputSchema>;
