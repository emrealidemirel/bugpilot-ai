import { z } from 'zod';

export const bugAnalysisPreferencesSchema = z
  .object({
    severity: z.boolean().default(true),
    priority: z.boolean().default(true),
    testCases: z.boolean().default(true),
    rootCause: z.boolean().default(true),
    screenshotAnalysis: z.boolean().default(true),
  })
  .default({
    severity: true,
    priority: true,
    testCases: true,
    rootCause: true,
    screenshotAnalysis: true,
  });

export const bugAnalysisRequestSchema = z.object({
  title: z.string().trim().min(1).max(120),
  description: z.string().trim().min(1).max(5000),
  expectedBehavior: z.string().trim().min(1).max(3000),
  actualBehavior: z.string().trim().min(1).max(3000),
  environment: z.object({
    platform: z.enum(['android', 'ios', 'web', 'other']),
    device: z.string().trim().min(1).max(200).optional(),
    osVersion: z.string().trim().min(1).max(100).optional(),
    appVersion: z.string().trim().min(1).max(100).optional(),
  }),
  preferences: bugAnalysisPreferencesSchema,
  logs: z.string().trim().min(1).max(12000).optional(),
});

export type BugAnalysisRequest = z.infer<typeof bugAnalysisRequestSchema>;
