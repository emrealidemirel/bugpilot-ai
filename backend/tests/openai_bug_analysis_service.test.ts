import { RateLimitError } from 'openai';
import { describe, expect, it } from 'vitest';

import { ApiError } from '../src/errors/api_error.js';
import { OpenAiBugAnalysisService } from '../src/services/openai_bug_analysis_service.js';
import { validOutput } from './bug_analysis_output_schema.test.js';

describe('OpenAiBugAnalysisService', () => {
  it('sends bug information and requests structured output', async () => {
    const client = new FakeOpenAiClient({ output: validOutput() });
    const service = new OpenAiBugAnalysisService({
      client,
      model: 'test-model',
    });

    const output = await service.analyze(validRequest(), {
      requestId: 'req_test',
    });

    expect(output.severity).toBe('high');
    expect(client.callCount).toBe(1);
    expect(client.lastBody?.model).toBe('test-model');
    expect(client.lastBody?.store).toBe(false);
    expect(client.lastBody?.input as string).toContain('BUG TITLE');
    expect(client.lastBody?.input as string).toContain(
      'Login button stuck loading',
    );
    expect(client.lastBody?.text?.format?.type).toBe('json_schema');
  });

  it('sends text and image input when a screenshot is provided', async () => {
    const client = new FakeOpenAiClient({ output: validOutput() });
    const service = new OpenAiBugAnalysisService({
      client,
      model: 'test-model',
    });

    await service.analyze(validRequest(), {
      requestId: 'req_image',
      screenshot: {
        buffer: Buffer.from('image-bytes'),
        mimeType: 'image/png',
      },
    });

    expect(Array.isArray(client.lastBody?.input)).toBe(true);
    const input = client.lastBody?.input as Array<{
      role: string;
      content: Array<Record<string, string>>;
    }>;
    expect(input[0]!.content[0]).toMatchObject({
      type: 'input_text',
    });
    expect(input[0]!.content[1]).toMatchObject({
      type: 'input_image',
      detail: 'high',
    });
    expect(input[0]!.content[1]!.image_url).toContain(
      'data:image/png;base64,',
    );
  });

  it('includes disabled preferences in the model input', async () => {
    const client = new FakeOpenAiClient({
      output: {
        ...validOutput(),
        severity: null,
        severityReason: null,
        testCases: [],
        possibleRootCause: null,
        rootCauseConfidence: null,
      },
    });
    const service = new OpenAiBugAnalysisService({
      client,
      model: 'test-model',
    });

    await service.analyze(
      {
        ...validRequest(),
        preferences: {
          severity: false,
          priority: true,
          testCases: false,
          rootCause: false,
          screenshotAnalysis: false,
        },
      },
      { requestId: 'req_prefs' },
    );

    expect(client.lastBody?.input as string).toContain(
      'Severity suggestion: disabled',
    );
    expect(client.lastBody?.input as string).toContain(
      'Test case generation: disabled',
    );
    expect(client.lastBody?.input as string).toContain(
      'Screenshot analysis: disabled',
    );
  });

  it('maps missing parsed output to AI_RESPONSE_INVALID', async () => {
    const service = new OpenAiBugAnalysisService({
      client: new FakeOpenAiClient({ output: null }),
      model: 'test-model',
    });

    await expect(
      service.analyze(validRequest(), { requestId: 'req_invalid' }),
    ).rejects.toMatchObject({
      code: 'AI_RESPONSE_INVALID',
      status: 502,
      requestId: 'req_invalid',
    });
  });

  it('maps invalid parsed output to AI_RESPONSE_INVALID', async () => {
    const service = new OpenAiBugAnalysisService({
      client: new FakeOpenAiClient({
        output: { ...validOutput(), rootCauseConfidence: 2 },
      }),
      model: 'test-model',
    });

    await expect(
      service.analyze(validRequest(), { requestId: 'req_invalid' }),
    ).rejects.toMatchObject({
      code: 'AI_RESPONSE_INVALID',
      status: 502,
    });
  });

  it('maps provider rate limit failures', async () => {
    const service = new OpenAiBugAnalysisService({
      client: new FakeOpenAiClient({
        error: new RateLimitError(429, {}, 'Rate limited', new Headers()),
      }),
      model: 'test-model',
    });

    await expect(
      service.analyze(validRequest(), { requestId: 'req_rate' }),
    ).rejects.toMatchObject({
      code: 'RATE_LIMITED',
      status: 429,
    });
  });

  it('does not wrap existing ApiError instances', async () => {
    const service = new OpenAiBugAnalysisService({
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
      service.analyze(validRequest(), { requestId: 'req_service' }),
    ).rejects.toMatchObject({
      code: 'SERVICE_UNAVAILABLE',
      requestId: 'req_service',
    });
  });
});

function validRequest() {
  return {
    title: 'Login button stuck loading',
    description: 'The login screen remains loading after valid credentials.',
    expectedBehavior: 'The dashboard should open.',
    actualBehavior: 'The loading indicator remains visible.',
    environment: {
      platform: 'android' as const,
      device: 'Pixel 9',
      appVersion: '1.0.0',
    },
    preferences: {
      severity: true,
      priority: true,
      testCases: true,
      rootCause: true,
      screenshotAnalysis: true,
    },
    logs: 'Stack trace',
  };
}

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
