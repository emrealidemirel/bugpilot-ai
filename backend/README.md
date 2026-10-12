# BugPilot AI Backend

## Development

```sh
npm install
cp .env.example .env
npm run dev
```

Required environment:

- `OPENAI_API_KEY`
- `OPENAI_MODEL`, defaults to `gpt-5.6-terra`
- `PORT`, defaults to `3000`
- `ALLOWED_ORIGINS`, optional comma-separated CORS origins

The backend exposes:

- `GET /health`
- `POST /api/v1/ai/analyze-bug`

`/health` does not call OpenAI.

`POST /api/v1/ai/analyze-bug` accepts either JSON bug-report data or
`multipart/form-data` with a `bug` JSON field and one optional `screenshot`
image. Screenshot uploads are memory-only, limited to PNG/JPEG under 5 MB, and
are not retained by the backend after the AI request completes.

## Validation

```sh
npm run build
npm test
```

Do not commit `.env` or real API keys. The backend intentionally logs request IDs, endpoint names, duration, and error categories, but not full bug descriptions, logs, prompts, or provider responses.
