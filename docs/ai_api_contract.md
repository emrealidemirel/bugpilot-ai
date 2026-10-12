# AI Analysis API Contract

## Endpoint

`POST /api/v1/ai/analyze-bug`

Accepts one Bug Report and returns one AI Analysis. The Flutter app must not send provider-specific AI settings such as model names, prompts, temperature, token limits, or API keys.

`POST /api/v1/ai/check-duplicates`

Accepts one draft Bug Report plus a small set of locally selected candidate bug
summaries and returns advisory similarity classifications. Flutter must perform
local candidate selection first and must not send the full local bug database.

## Request Body

```json
{
  "title": "Login button stuck loading",
  "description": "The login screen remains in a loading state after valid credentials are submitted.",
  "expectedBehavior": "The user should be redirected to the dashboard.",
  "actualBehavior": "The loading indicator remains visible indefinitely.",
  "environment": {
    "platform": "android",
    "device": "Pixel 9",
    "osVersion": "Android 16",
    "appVersion": "1.0.0"
  },
  "preferences": {
    "severity": true,
    "priority": true,
    "testCases": true,
    "rootCause": true,
    "screenshotAnalysis": true
  },
  "logs": "POST /auth/login returned 200, navigation callback not invoked."
}
```

Required fields: `title`, `description`, `expectedBehavior`, `actualBehavior`, `environment.platform`.

Optional fields: `environment.device`, `environment.osVersion`,
`environment.appVersion`, `preferences`, `logs`. Optional values are omitted
when unknown. The backend should enforce request-size limits, especially for
`logs`.

When `preferences` is omitted, all preference fields default to `true` for
backwards compatibility. Flutter must not send UI-only settings such as theme,
default environment values, provider model names, prompts, token limits, or API
keys.

AI preference fields:

- `severity`: ask AI to recommend severity
- `priority`: ask AI to recommend priority
- `testCases`: ask AI to generate QA test cases
- `rootCause`: ask AI to generate a possible root-cause hypothesis and confidence
- `screenshotAnalysis`: allow an uploaded screenshot to be included in AI input

Validation limits:

- `title`: max 120 characters
- `description`: max 5000 characters
- `expectedBehavior`: max 3000 characters
- `actualBehavior`: max 3000 characters
- `environment.device`: max 200 characters
- `environment.osVersion`: max 100 characters
- `environment.appVersion`: max 100 characters
- `logs`: max 12000 characters

## Optional Screenshot Upload

Text-only bug analysis continues to use `application/json` with the body above.

When a user attaches a screenshot, Flutter sends `multipart/form-data` to the
same endpoint:

- `bug`: JSON string containing the same request body shown above
- `screenshot`: optional image file

If `preferences.screenshotAnalysis` is `false`, Flutter should omit the
`screenshot` file from the AI request even when the bug report keeps a local
screenshot attachment. The backend also ignores an uploaded screenshot when this
preference is `false`.

Screenshot limits:

- exactly zero or one `screenshot` file
- supported MIME types: `image/png`, `image/jpeg`
- maximum size: 5 MB
- screenshots are used only for the current AI analysis request

The backend validates upload MIME type and size, keeps the image in memory, and
does not permanently store screenshot files. Saved screenshots are persisted
locally by the Flutter app in app-controlled storage; the domain model stores
only lightweight local attachment metadata, never Base64 image data or provider
file IDs.

## Success Response

```json
{
  "analysis": {
    "severity": "high",
    "severityReason": "The issue blocks an important user flow.",
    "priority": "p1",
    "priorityReason": "The issue should be addressed quickly.",
    "reproductionSteps": [
      "Open the application",
      "Navigate to the login screen",
      "Enter valid credentials",
      "Tap Login",
      "Observe the loading state"
    ],
    "testCases": [
      {
        "id": "TC-01",
        "type": "positive",
        "title": "Valid login completes successfully",
        "given": "A registered user is on the login screen",
        "when": "Valid credentials are submitted",
        "then": "The user should reach the dashboard"
      }
    ],
    "possibleRootCause": "The loading state may not be reset after the asynchronous authentication call completes.",
    "rootCauseConfidence": 0.72,
    "missingInformation": [
      "Device model was not provided."
    ],
    "qualityScore": 82
  },
  "meta": {
    "requestId": "optional-request-id",
    "model": "optional-backend-owned-model-label",
    "processingTimeMs": 1240
  }
}
```

Metadata is optional and must not be required for core Flutter behavior.

When a preference disables a generated section, the response remains
deterministic:

- severity disabled: `severity: null`, `severityReason: null`
- priority disabled: `priority: null`, `priorityReason: null`
- test cases disabled: `testCases: []`
- root cause disabled: `possibleRootCause: null`, `rootCauseConfidence: null`

`reproductionSteps`, `missingInformation`, and `qualityScore` are always
generated.

## Error Response

```json
{
  "error": {
    "code": "AI_ANALYSIS_FAILED",
    "message": "The bug report could not be analyzed.",
    "requestId": "optional-request-id"
  }
}
```

Supported error codes:

- `INVALID_REQUEST`
- `AI_ANALYSIS_FAILED`
- `AI_RESPONSE_INVALID`
- `RATE_LIMITED`
- `SERVICE_UNAVAILABLE`
- `REQUEST_TIMEOUT`
- `NETWORK_ERROR` (client-side Flutter connectivity/configuration failure)
- `UNKNOWN_ERROR`

The backend returns all errors in the standard error shape above. Flutter may also map local connectivity failures to client-side `NETWORK_ERROR`.

Example rate-limit response:

```json
{
  "error": {
    "code": "RATE_LIMITED",
    "message": "AI analysis is temporarily busy.",
    "requestId": "optional-request-id"
  }
}
```

Security notes: production deployments should add authentication and origin hardening. Users should avoid pasting secrets such as API keys, passwords, access tokens, or authorization headers into bug logs. Future work should add redaction before sending logs for AI Analysis.
Screenshots may also contain sensitive information; users should review selected
images before sending them for AI analysis.

## Duplicate Check Request

```json
{
  "bug": {
    "title": "Login button stuck loading",
    "description": "The login screen remains in a loading state after valid credentials are submitted.",
    "expectedBehavior": "The user should be redirected to the dashboard.",
    "actualBehavior": "The loading indicator remains visible indefinitely.",
    "platform": "android"
  },
  "candidates": [
    {
      "id": "bug-001",
      "title": "Login remains loading",
      "description": "Valid login never reaches the dashboard.",
      "expectedBehavior": "The dashboard should open.",
      "actualBehavior": "The login spinner never clears.",
      "platform": "android",
      "severity": "high",
      "status": "open"
    }
  ]
}
```

Candidate limits:

- `candidates`: 1 to 5 items
- Flutter should normally send only the top local candidates, ranked by local similarity

Duplicate check intentionally omits screenshots, local file paths, logs, test
cases, root-cause hypotheses, and local metadata.

## Duplicate Check Response

```json
{
  "matches": [
    {
      "bugId": "bug-001",
      "similarity": "likelyDuplicate",
      "confidence": 0.83,
      "reason": "Both reports describe the login flow remaining stuck after valid credentials are submitted."
    }
  ],
  "meta": {
    "requestId": "optional-request-id",
    "processingTimeMs": 620
  }
}
```

The confidence value is an AI heuristic between `0.0` and `1.0`, not a
calibrated probability. Flutter should treat duplicate detection as advisory,
filter `notDuplicate` matches from the user-facing review, and always allow the
user to continue creating the new report.

## Enum Values

Severity: `critical`, `high`, `medium`, `low`

Priority: `p0`, `p1`, `p2`, `p3`

Test Case Type: `positive`, `negative`, `edgeCase`

Platform: `android`, `ios`, `web`, `other`

Duplicate similarity: `likelyDuplicate`, `related`, `notDuplicate`

## Validation Expectations

`rootCauseConfidence` must be either `null` or between `0.0` and `1.0`.

`qualityScore` must be between `0` and `100`.

Generated text fields must be non-empty when present. `reproductionSteps` must
contain at least one item. `testCases` may be empty only when test-case
generation is disabled.
