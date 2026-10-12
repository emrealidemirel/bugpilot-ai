import request from 'supertest';
import { describe, expect, it } from 'vitest';

import { createApp } from '../src/app.js';
import { ApiError } from '../src/errors/api_error.js';
import type { BugAnalysisRequest } from '../src/schemas/bug_analysis_request_schema.js';
import type { BugAnalysisOutput } from '../src/schemas/bug_analysis_output_schema.js';
import type { DuplicateCheckRequest } from '../src/schemas/duplicate_check_request_schema.js';
import type { DuplicateCheckOutput } from '../src/schemas/duplicate_check_output_schema.js';
import type {
  BugAnalysisService,
  DuplicateCheckService,
} from '../src/services/openai_bug_analysis_service.js';
import { validOutput } from './bug_analysis_output_schema.test.js';

describe('POST /api/v1/ai/analyze-bug', () => {
  it('returns HTTP 200 and expected response shape on success', async () => {
    const service = new FakeAnalysisService({ output: validOutput() });
    const app = createApp({ analysisService: service, duplicateCheckService: new FakeDuplicateCheckService() });

    const response = await request(app)
      .post('/api/v1/ai/analyze-bug')
      .send(validRequest())
      .expect(200);

    expect(response.body.analysis.severity).toBe('high');
    expect(response.body.analysis.testCases).toHaveLength(1);
    expect(response.body.meta.requestId).toEqual(expect.any(String));
    expect(service.callCount).toBe(1);
  });

  it('accepts multipart bug data with one PNG screenshot', async () => {
    const service = new FakeAnalysisService({ output: validOutput() });
    const app = createApp({ analysisService: service, duplicateCheckService: new FakeDuplicateCheckService() });

    const response = await request(app)
      .post('/api/v1/ai/analyze-bug')
      .field('bug', JSON.stringify(validRequest()))
      .attach('screenshot', Buffer.from('png'), {
        filename: 'screenshot.png',
        contentType: 'image/png',
      })
      .expect(200);

    expect(response.body.analysis.severity).toBe('high');
    expect(service.callCount).toBe(1);
    expect(service.lastScreenshot?.mimeType).toBe('image/png');
    expect(service.lastScreenshot?.buffer).toBeInstanceOf(Buffer);
  });

  it('accepts multipart bug data with one JPEG screenshot', async () => {
    const service = new FakeAnalysisService({ output: validOutput() });
    const app = createApp({ analysisService: service, duplicateCheckService: new FakeDuplicateCheckService() });

    await request(app)
      .post('/api/v1/ai/analyze-bug')
      .field('bug', JSON.stringify(validRequest()))
      .attach('screenshot', Buffer.from('jpeg'), {
        filename: 'screenshot.jpg',
        contentType: 'image/jpeg',
      })
      .expect(200);

    expect(service.lastScreenshot?.mimeType).toBe('image/jpeg');
  });

  it('does not pass uploaded screenshots to analysis when screenshot analysis is disabled', async () => {
    const service = new FakeAnalysisService({ output: validOutput() });
    const app = createApp({
      analysisService: service,
      duplicateCheckService: new FakeDuplicateCheckService(),
    });

    await request(app)
      .post('/api/v1/ai/analyze-bug')
      .field(
        'bug',
        JSON.stringify({
          ...validRequest(),
          preferences: {
            severity: true,
            priority: true,
            testCases: true,
            rootCause: true,
            screenshotAnalysis: false,
          },
        }),
      )
      .attach('screenshot', Buffer.from('png'), {
        filename: 'screenshot.png',
        contentType: 'image/png',
      })
      .expect(200);

    expect(service.lastBug?.preferences.screenshotAnalysis).toBe(false);
    expect(service.lastScreenshot).toBeUndefined();
  });

  it('returns 400 for oversized screenshots', async () => {
    const app = createApp({
      analysisService: new FakeAnalysisService({ output: validOutput() }),
      duplicateCheckService: new FakeDuplicateCheckService(),
    });

    const response = await request(app)
      .post('/api/v1/ai/analyze-bug')
      .field('bug', JSON.stringify(validRequest()))
      .attach('screenshot', Buffer.alloc(5 * 1024 * 1024 + 1), {
        filename: 'large.png',
        contentType: 'image/png',
      })
      .expect(400);

    expect(response.body.error.code).toBe('INVALID_REQUEST');
  });

  it('returns 400 for unsupported screenshot MIME types', async () => {
    const app = createApp({
      analysisService: new FakeAnalysisService({ output: validOutput() }),
      duplicateCheckService: new FakeDuplicateCheckService(),
    });

    const response = await request(app)
      .post('/api/v1/ai/analyze-bug')
      .field('bug', JSON.stringify(validRequest()))
      .attach('screenshot', Buffer.from('<svg />'), {
        filename: 'screenshot.svg',
        contentType: 'image/svg+xml',
      })
      .expect(400);

    expect(response.body.error.code).toBe('INVALID_REQUEST');
  });

  it('returns 400 for multiple screenshot files', async () => {
    const app = createApp({
      analysisService: new FakeAnalysisService({ output: validOutput() }),
      duplicateCheckService: new FakeDuplicateCheckService(),
    });

    const response = await request(app)
      .post('/api/v1/ai/analyze-bug')
      .field('bug', JSON.stringify(validRequest()))
      .attach('screenshot', Buffer.from('first'), {
        filename: 'first.png',
        contentType: 'image/png',
      })
      .attach('screenshot', Buffer.from('second'), {
        filename: 'second.png',
        contentType: 'image/png',
      })
      .expect(400);

    expect(response.body.error.code).toBe('INVALID_REQUEST');
  });

  it('returns 400 for invalid input', async () => {
    const app = createApp({
      analysisService: new FakeAnalysisService({ output: validOutput() }),
      duplicateCheckService: new FakeDuplicateCheckService(),
    });

    const response = await request(app)
      .post('/api/v1/ai/analyze-bug')
      .send({ ...validRequest(), title: '' })
      .expect(400);

    expect(response.body.error.code).toBe('INVALID_REQUEST');
    expect(response.body.error.requestId).toEqual(expect.any(String));
  });

  it('maps rate limit, unavailable, and invalid AI output errors', async () => {
    await expectError(
      new ApiError({ code: 'RATE_LIMITED', status: 429 }),
      429,
      'RATE_LIMITED',
    );
    await expectError(
      new ApiError({ code: 'SERVICE_UNAVAILABLE', status: 503 }),
      503,
      'SERVICE_UNAVAILABLE',
    );
    await expectError(
      new ApiError({ code: 'AI_RESPONSE_INVALID', status: 502 }),
      502,
      'AI_RESPONSE_INVALID',
    );
  });
});

async function expectError(error: ApiError, status: number, code: string) {
  const app = createApp({
    analysisService: new FakeAnalysisService({ error }),
    duplicateCheckService: new FakeDuplicateCheckService(),
  });

  const response = await request(app)
    .post('/api/v1/ai/analyze-bug')
    .send(validRequest())
    .expect(status);

  expect(response.body.error.code).toBe(code);
  expect(response.body.error.requestId).toEqual(expect.any(String));
}

function validRequest() {
  return {
    title: 'Login button stuck loading',
    description: 'The login screen remains loading after valid credentials.',
    expectedBehavior: 'The dashboard should open.',
    actualBehavior: 'The loading indicator remains visible.',
    environment: {
      platform: 'android',
      device: 'Pixel 9',
      appVersion: '1.0.0',
    },
    logs: 'Stack trace',
  };
}

class FakeAnalysisService implements BugAnalysisService {
  constructor({
    output,
    error,
  }: {
    output?: BugAnalysisOutput;
    error?: ApiError;
  }) {
    this.output = output;
    this.error = error;
  }

  readonly output?: BugAnalysisOutput;
  readonly error?: ApiError;
  callCount = 0;
  lastBug: BugAnalysisRequest | null = null;
  lastScreenshot: { buffer: Buffer; mimeType: string } | undefined;

  async analyze(
    bug: BugAnalysisRequest,
    context: { screenshot?: { buffer: Buffer; mimeType: string } } = {},
  ): Promise<BugAnalysisOutput> {
    this.callCount++;
    this.lastBug = bug;
    this.lastScreenshot = context.screenshot;
    if (this.error) {
      throw this.error;
    }

    return this.output!;
  }
}

class FakeDuplicateCheckService implements DuplicateCheckService {
  async checkDuplicates(
    _request: DuplicateCheckRequest,
  ): Promise<DuplicateCheckOutput> {
    return { matches: [] };
  }
}
