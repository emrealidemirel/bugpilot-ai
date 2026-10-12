import { z } from 'zod';

export const duplicateMatchSchema = z.object({
  bugId: z.string().trim().min(1),
  similarity: z.enum(['likelyDuplicate', 'related', 'notDuplicate']),
  confidence: z.number().min(0).max(1),
  reason: z.string().trim().min(1).max(300),
});

export const duplicateCheckOutputSchema = z.object({
  matches: z.array(duplicateMatchSchema).max(5),
});

export type DuplicateCheckOutput = z.infer<typeof duplicateCheckOutputSchema>;
