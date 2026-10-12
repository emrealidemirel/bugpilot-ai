import { Router } from 'express';

import { AiController } from '../controllers/ai.controller.js';
import { optionalScreenshotUpload } from '../middleware/screenshot_upload.js';
import type {
  BugAnalysisService,
  DuplicateCheckService,
} from '../services/openai_bug_analysis_service.js';

export function createAiRouter(
  analysisService: BugAnalysisService,
  duplicateCheckService: DuplicateCheckService,
): Router {
  const router = Router();
  const controller = new AiController(analysisService, duplicateCheckService);

  router.post('/analyze-bug', optionalScreenshotUpload, controller.analyzeBug);
  router.post('/check-duplicates', controller.checkDuplicates);

  return router;
}
