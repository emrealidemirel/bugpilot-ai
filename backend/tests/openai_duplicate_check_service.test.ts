import { describe, expect, it } from 'vitest';

import { ApiError } from '../src/errors/api_error.js';
import { OpenAiDuplicateCheckService } from '../src/services/openai_bug_analysis_service.js';
import { validDuplicateRequest } from './duplicate_check_request_schema.test.js';
import { validDuplicateOutput } from './duplicate_check_output_schema.test.js';

describe('OpenAiDuplicateCheckService', () => {
  it('sends selected candidates and requests structured output', async () => {
    const client = new FakeOpenAiClient({ output: validDuplicateOutput() });
    const service = new OpenAiDuplicateCheckService({
      client,
      model: 'test-model',
    });

    const output = await service.checkDuplicates(validDuplicateRequest(), {
      requestId: 'req_dup',
    });

    expect(output.matches[0]?.similarity).toBe('likelyDuplicate');
    expect(client.callCount).toBe(1);
    expect(client.lastBody?.model).toBe('test-model');
    expect(client.lastBody?.store).toBe(false);
    expect(client.lastBody?.input as string).toContain('NEW DRAFT BUG');
    expect(client.lastBody?.input as string).toContain('bug-001');
    expect(client.lastBody?.text?.format?.type).toBe('json_schema');
  });

  it('maps invalid parsed output to AI_RESPONSE_INVALID', async () => {
    const service = new OpenAiDuplicateCheckService({
      client: new FakeOpenAiClient({
        output: {
          matches: [{ ...validDuplicateOutput().matches[0]!, confidence: 2 }],
        },
      }),
      model: 'test-model',
    });

    await expect(
      service.checkDuplicates(validDuplicateRequest(), {
        requestId: 'req_invalid',
      }),
    ).rejects.toMatchObject({
      code: 'AI_RESPONSE_INVALID',
      status: 502,
    });
  });

  it('does not wrap existing ApiError instances', async () => {
    const service = new OpenAiDuplicateCheckService({
      client: new FakeOpenAiClient({
        error: new ApiError({
          code: 'SERVICE_UNAVAILABLE',
          status: 503,
          requestId: 'req_service',
        }),
      }),
      model: 'test-model',
    });

    await expect(
      service.checkDuplicates(validDuplicateRequest(), {
        requestId: 'req_service',
      }),
    ).rejects.toMatchObject({
      code: 'SERVICE_UNAVAILABLE',
      requestId: 'req_service',
    });
  });
});

class FakeOpenAiClient {
  constructor({
    output,
    error,
  }: {
    output?: unknown;
    error?: unknown;
  }) {
    this.output = output;
    this.error = error;
  }

  readonly output: unknown;
  readonly error: unknown;
  callCount = 0;
  lastBody: {
    model?: string;
    input?: unknown;
    store?: boolean;
    text?: { format?: { type?: string } };
  } | null = null;

  responses = {
    parse: async (body: {
      model?: string;
      input?: unknown;
      store?: boolean;
      text?: { format?: { type?: string } };
      [key: string]: unknown;
    }) => {
      this.callCount++;
      this.lastBody = body;
      if (this.error) {
        throw this.error;
      }

      return { output_parsed: this.output };
    },
  };
}
