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
import { validDuplicateRequest } from './duplicate_check_request_schema.test.js';
import { validDuplicateOutput } from './duplicate_check_output_schema.test.js';

describe('POST /api/v1/ai/check-duplicates', () => {
  it('returns HTTP 200 and expected response shape on success', async () => {
    const duplicateService = new FakeDuplicateCheckService({
      output: validDuplicateOutput(),
    });
    const app = createApp({
      analysisService: new FakeAnalysisService(),
      duplicateCheckService: duplicateService,
    });

    const response = await request(app)
      .post('/api/v1/ai/check-duplicates')
      .send(validDuplicateRequest())
      .expect(200);

    expect(response.body.matches[0].similarity).toBe('likelyDuplicate');
    expect(response.body.meta.requestId).toEqual(expect.any(String));
    expect(duplicateService.callCount).toBe(1);
    expect(duplicateService.lastRequest?.candidates).toHaveLength(1);
  });

  it('returns 400 for invalid input', async () => {
    const app = createApp({
      analysisService: new FakeAnalysisService(),
      duplicateCheckService: new FakeDuplicateCheckService({
        output: validDuplicateOutput(),
      }),
    });

    const response = await request(app)
      .post('/api/v1/ai/check-duplicates')
      .send({ ...validDuplicateRequest(), candidates: [] })
      .expect(400);

    expect(response.body.error.code).toBe('INVALID_REQUEST');
  });

  it('maps service errors', async () => {
    const app = createApp({
      analysisService: new FakeAnalysisService(),
      duplicateCheckService: new FakeDuplicateCheckService({
        error: new ApiError({ code: 'RATE_LIMITED', status: 429 }),
      }),
    });

    const response = await request(app)
      .post('/api/v1/ai/check-duplicates')
      .send(validDuplicateRequest())
      .expect(429);

    expect(response.body.error.code).toBe('RATE_LIMITED');
  });
});

class FakeAnalysisService implements BugAnalysisService {
  async analyze(_bug: BugAnalysisRequest): Promise<BugAnalysisOutput> {
    return validOutput();
  }
}

class FakeDuplicateCheckService implements DuplicateCheckService {
  constructor({
    output,
    error,
  }: {
    output?: DuplicateCheckOutput;
    error?: ApiError;
  } = {}) {
    this.output = output;
    this.error = error;
  }

  readonly output?: DuplicateCheckOutput;
  readonly error?: ApiError;
  callCount = 0;
  lastRequest: DuplicateCheckRequest | null = null;

  async checkDuplicates(
    request: DuplicateCheckRequest,
  ): Promise<DuplicateCheckOutput> {
    this.callCount++;
    this.lastRequest = request;
    if (this.error) {
      throw this.error;
    }

    return this.output ?? { matches: [] };
  }
}
