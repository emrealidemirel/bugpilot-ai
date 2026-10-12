import { createApp, allowedOriginsFromEnv } from './app.js';
import { loadEnv } from './config/env.js';
import {
  createOpenAiBugAnalysisService,
  createOpenAiDuplicateCheckService,
} from './services/openai_bug_analysis_service.js';

const env = loadEnv();
const app = createApp({
  analysisService: createOpenAiBugAnalysisService({
    apiKey: env.OPENAI_API_KEY,
    model: env.OPENAI_MODEL,
  }),
  duplicateCheckService: createOpenAiDuplicateCheckService({
    apiKey: env.OPENAI_API_KEY,
    model: env.OPENAI_MODEL,
  }),
  allowedOrigins: allowedOriginsFromEnv(env.ALLOWED_ORIGINS),
});

app.listen(env.PORT, () => {
  console.info(`BugPilot backend listening on port ${env.PORT}`);
});
