import OpenAI, {
  APIConnectionTimeoutError,
  APIError,
  RateLimitError,
} from 'openai';
import { zodTextFormat } from 'openai/helpers/zod';

import { ApiError } from '../errors/api_error.js';
import {
  buildBugAnalysisInput,
  BUG_ANALYSIS_INSTRUCTIONS,
} from '../prompts/bug_analysis_prompt.js';
import {
  buildDuplicateCheckInput,
  DUPLICATE_CHECK_INSTRUCTIONS,
} from '../prompts/duplicate_check_prompt.js';
import type { BugAnalysisRequest } from '../schemas/bug_analysis_request_schema.js';
import {
  bugAnalysisOutputSchema,
  type BugAnalysisOutput,
} from '../schemas/bug_analysis_output_schema.js';
import type { DuplicateCheckRequest } from '../schemas/duplicate_check_request_schema.js';
import {
  duplicateCheckOutputSchema,
  type DuplicateCheckOutput,
} from '../schemas/duplicate_check_output_schema.js';

export interface BugAnalysisService {
  analyze(
    bug: BugAnalysisRequest,
    context: { requestId: string; screenshot?: BugScreenshotInput },
  ): Promise<BugAnalysisOutput>;
}

export interface DuplicateCheckService {
  checkDuplicates(
    request: DuplicateCheckRequest,
    context: { requestId: string },
  ): Promise<DuplicateCheckOutput>;
}

export interface BugScreenshotInput {
  buffer: Buffer;
  mimeType: string;
}

interface OpenAiResponsesParser {
  parse(body: unknown): PromiseLike<{ output_parsed: unknown }>;
}

export class OpenAiBugAnalysisService implements BugAnalysisService {
  constructor({
    client,
    model,
  }: {
    client: { responses: OpenAiResponsesParser };
    model: string;
  }) {
    this.client = client;
    this.model = model;
  }

  private readonly client: { responses: OpenAiResponsesParser };
  private readonly model: string;

  async analyze(
    bug: BugAnalysisRequest,
    context: { requestId: string; screenshot?: BugScreenshotInput },
  ): Promise<BugAnalysisOutput> {
    try {
      const startedAt = Date.now();
      const response = await this.client.responses.parse({
        model: this.model as OpenAI.Responses.ResponseCreateParams['model'],
        instructions: BUG_ANALYSIS_INSTRUCTIONS,
        input: buildOpenAiInput(bug, context.screenshot),
        store: false,
        text: {
          format: zodTextFormat(
            bugAnalysisOutputSchema,
            'bug_analysis',
            {
              description: 'Structured software bug report analysis.',
            },
          ),
        },
      });

      const parsed = response.output_parsed;
      if (!parsed) {
        throw new ApiError({
          code: 'AI_RESPONSE_INVALID',
          status: 502,
          requestId: context.requestId,
        });
      }

      const validated = bugAnalysisOutputSchema.safeParse(parsed);
      if (!validated.success) {
        throw new ApiError({
          code: 'AI_RESPONSE_INVALID',
          status: 502,
          requestId: context.requestId,
        });
      }

      console.info('AI analysis completed', {
        requestId: context.requestId,
        durationMs: Date.now() - startedAt,
      });
      return validated.data;
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }

      throw mapOpenAiError(error, context.requestId);
    }
  }
}

export class OpenAiDuplicateCheckService implements DuplicateCheckService {
  constructor({
    client,
    model,
  }: {
    client: { responses: OpenAiResponsesParser };
    model: string;
  }) {
    this.client = client;
    this.model = model;
  }

  private readonly client: { responses: OpenAiResponsesParser };
  private readonly model: string;

  async checkDuplicates(
    request: DuplicateCheckRequest,
    context: { requestId: string },
  ): Promise<DuplicateCheckOutput> {
    try {
      const startedAt = Date.now();
      const response = await this.client.responses.parse({
        model: this.model as OpenAI.Responses.ResponseCreateParams['model'],
        instructions: DUPLICATE_CHECK_INSTRUCTIONS,
        input: buildDuplicateCheckInput(request),
        store: false,
        text: {
          format: zodTextFormat(
            duplicateCheckOutputSchema,
            'duplicate_check',
            {
              description: 'Structured software bug duplicate assessment.',
            },
          ),
        },
      });

      const parsed = response.output_parsed;
      if (!parsed) {
        throw new ApiError({
          code: 'AI_RESPONSE_INVALID',
          status: 502,
          requestId: context.requestId,
        });
      }

      const validated = duplicateCheckOutputSchema.safeParse(parsed);
      if (!validated.success) {
        throw new ApiError({
          code: 'AI_RESPONSE_INVALID',
          status: 502,
          requestId: context.requestId,
        });
      }

      console.info('Duplicate check completed', {
        requestId: context.requestId,
        durationMs: Date.now() - startedAt,
      });
      return validated.data;
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }

      throw mapOpenAiError(error, context.requestId);
    }
  }
}

function buildOpenAiInput(
  bug: BugAnalysisRequest,
  screenshot?: BugScreenshotInput,
): OpenAI.Responses.ResponseCreateParams['input'] {
  const text = buildBugAnalysisInput(bug);
  if (!screenshot) {
    return text;
  }

  return [
    {
      role: 'user',
      content: [
        {
          type: 'input_text',
          text: [
            text,
            '',
            'SCREENSHOT',
            'A user-selected screenshot is attached as additional bug evidence.',
          ].join('\n'),
        },
        {
          type: 'input_image',
          image_url: `data:${screenshot.mimeType};base64,${screenshot.buffer.toString(
            'base64',
          )}`,
          detail: 'high',
        },
      ],
    },
  ];
}

export function createOpenAiBugAnalysisService({
  apiKey,
  model,
}: {
  apiKey: string;
  model: string;
}): OpenAiBugAnalysisService {
  return new OpenAiBugAnalysisService({
    client: new OpenAI({ apiKey }) as unknown as {
      responses: OpenAiResponsesParser;
    },
    model,
  });
}

export function createOpenAiDuplicateCheckService({
  apiKey,
  model,
}: {
  apiKey: string;
  model: string;
}): OpenAiDuplicateCheckService {
  return new OpenAiDuplicateCheckService({
    client: new OpenAI({ apiKey }) as unknown as {
      responses: OpenAiResponsesParser;
    },
    model,
  });
}

function mapOpenAiError(error: unknown, requestId: string): ApiError {
  if (error instanceof RateLimitError) {
    return new ApiError({ code: 'RATE_LIMITED', status: 429, requestId });
  }

  if (error instanceof APIConnectionTimeoutError) {
    return new ApiError({ code: 'REQUEST_TIMEOUT', status: 504, requestId });
  }

  if (error instanceof APIError) {
    const status = error.status;
    if (status === 429) {
      return new ApiError({ code: 'RATE_LIMITED', status: 429, requestId });
    }
    if (status !== undefined && status >= 500) {
      return new ApiError({
        code: 'SERVICE_UNAVAILABLE',
        status: 503,
        requestId,
      });
    }
  }

  return new ApiError({
    code: 'AI_ANALYSIS_FAILED',
    status: 502,
    requestId,
  });
}
