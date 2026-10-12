import { z } from 'zod';

const duplicateBugBaseSchema = z.object({
  title: z.string().trim().min(1).max(120),
  description: z.string().trim().min(1).max(5000),
  expectedBehavior: z.string().trim().min(1).max(3000),
  actualBehavior: z.string().trim().min(1).max(3000),
  platform: z.enum(['android', 'ios', 'web', 'other']),
}).strict();

export const duplicateCandidateSchema = duplicateBugBaseSchema.extend({
  id: z.string().trim().min(1).max(120),
  severity: z.enum(['critical', 'high', 'medium', 'low']).optional(),
  status: z.enum(['open', 'inProgress', 'resolved', 'closed']),
}).strict();

export const duplicateCheckRequestSchema = z.object({
  bug: duplicateBugBaseSchema,
  candidates: z.array(duplicateCandidateSchema).min(1).max(5),
}).strict();

export type DuplicateCheckRequest = z.infer<typeof duplicateCheckRequestSchema>;
