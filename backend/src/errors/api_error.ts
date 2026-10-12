export type ApiErrorCode =
  | 'INVALID_REQUEST'
  | 'AI_ANALYSIS_FAILED'
  | 'AI_RESPONSE_INVALID'
  | 'RATE_LIMITED'
  | 'SERVICE_UNAVAILABLE'
  | 'REQUEST_TIMEOUT'
  | 'UNKNOWN_ERROR';

const defaultMessages: Record<ApiErrorCode, string> = {
  INVALID_REQUEST: 'Some bug report information is invalid.',
  AI_ANALYSIS_FAILED: 'Something went wrong while analyzing this bug report.',
  AI_RESPONSE_INVALID: 'The AI returned an invalid analysis. Please try again.',
  RATE_LIMITED: 'AI analysis is temporarily busy.',
  SERVICE_UNAVAILABLE: 'AI analysis is temporarily unavailable.',
  REQUEST_TIMEOUT: 'The analysis took too long. Please try again.',
  UNKNOWN_ERROR: 'Something went wrong while analyzing this bug report.',
};

export class ApiError extends Error {
  readonly code: ApiErrorCode;
  readonly status: number;
  readonly requestId?: string;

  constructor({
    code,
    status,
    message = defaultMessages[code],
    requestId,
  }: {
    code: ApiErrorCode;
    status: number;
    message?: string;
    requestId?: string;
  }) {
    super(message);
    this.name = 'ApiError';
    this.code = code;
    this.status = status;
    this.requestId = requestId;
  }
}
