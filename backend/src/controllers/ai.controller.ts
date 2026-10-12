import type { Request, Response, NextFunction } from 'express';

import { ApiError } from '../errors/api_error.js';
import { screenshotUploadConfig } from '../config/screenshot_upload.js';
import { bugAnalysisRequestSchema } from '../schemas/bug_analysis_request_schema.js';
import { duplicateCheckRequestSchema } from '../schemas/duplicate_check_request_schema.js';
import type {
  BugAnalysisService,
  DuplicateCheckService,
} from '../services/openai_bug_analysis_service.js';

export class AiController {
  constructor(
    private readonly analysisService: BugAnalysisService,
    private readonly duplicateCheckService: DuplicateCheckService,
  ) {}

  analyzeBug = async (req: Request, res: Response, next: NextFunction) => {
    const requestId = res.locals.requestId as string;
    const startedAt = Date.now();
    const body = parseRequestBody(req);
    if (body instanceof ApiError) {
      return next(body);
    }

    const parsed = bugAnalysisRequestSchema.safeParse(body);

    if (!parsed.success) {
      return next(
        new ApiError({
          code: 'INVALID_REQUEST',
          status: 400,
          requestId,
        }),
      );
    }

    try {
      const analysis = await this.analysisService.analyze(parsed.data, {
        requestId,
        screenshot: parsed.data.preferences.screenshotAnalysis && req.file
          ? {
              buffer: req.file.buffer,
              mimeType: req.file.mimetype,
            }
          : undefined,
      });
      console.info('Request completed', {
        requestId,
        endpoint: 'POST /api/v1/ai/analyze-bug',
        durationMs: Date.now() - startedAt,
      });

      return res.status(200).json({
        analysis,
        meta: {
          requestId,
          processingTimeMs: Date.now() - startedAt,
        },
      });
    } catch (error) {
      return next(error);
    }
  };

  checkDuplicates = async (req: Request, res: Response, next: NextFunction) => {
    const requestId = res.locals.requestId as string;
    const startedAt = Date.now();
    const parsed = duplicateCheckRequestSchema.safeParse(req.body);

    if (!parsed.success) {
      return next(
        new ApiError({
          code: 'INVALID_REQUEST',
          status: 400,
          requestId,
        }),
      );
    }

    try {
      const result = await this.duplicateCheckService.checkDuplicates(
        parsed.data,
        { requestId },
      );
      console.info('Request completed', {
        requestId,
        endpoint: 'POST /api/v1/ai/check-duplicates',
        durationMs: Date.now() - startedAt,
      });

      return res.status(200).json({
        ...result,
        meta: {
          requestId,
          processingTimeMs: Date.now() - startedAt,
        },
      });
    } catch (error) {
      return next(error);
    }
  };
}

function parseRequestBody(req: Request): unknown {
  if (!req.is('multipart/form-data')) {
    return req.body;
  }

  const rawBug = req.body[screenshotUploadConfig.bugFieldName];
  if (typeof rawBug !== 'string') {
    return new ApiError({
      code: 'INVALID_REQUEST',
      status: 400,
    });
  }

  try {
    return JSON.parse(rawBug) as unknown;
  } catch {
    return new ApiError({
      code: 'INVALID_REQUEST',
      status: 400,
    });
  }
}
