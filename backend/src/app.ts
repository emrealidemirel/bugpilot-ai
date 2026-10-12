import cors from 'cors';
import express from 'express';

import { allowedOriginsFromEnv } from './config/env.js';
import { createAiRouter } from './routes/ai.routes.js';
import type {
  BugAnalysisService,
  DuplicateCheckService,
} from './services/openai_bug_analysis_service.js';
import { errorHandler, requestIdMiddleware } from './middleware/error_handler.js';

export function createApp({
  analysisService,
  duplicateCheckService,
  allowedOrigins = [],
}: {
  analysisService: BugAnalysisService;
  duplicateCheckService: DuplicateCheckService;
  allowedOrigins?: string[];
}) {
  const app = express();

  app.use(
    cors(
      allowedOrigins.length === 0
        ? undefined
        : {
            origin: allowedOrigins,
          },
    ),
  );
  app.use(express.json({ limit: '75kb' }));
  app.use(requestIdMiddleware);

  app.get('/health', (_req, res) => {
    res.json({ status: 'ok' });
  });

  app.use('/api/v1/ai', createAiRouter(analysisService, duplicateCheckService));
  app.use(errorHandler);

  return app;
}

export { allowedOriginsFromEnv };
