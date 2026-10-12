import type { ErrorRequestHandler, RequestHandler } from 'express';
import { randomUUID } from 'node:crypto';

import { ApiError } from '../errors/api_error.js';

export const requestIdMiddleware: RequestHandler = (_req, res, next) => {
  res.locals.requestId = randomUUID();
  next();
};

export const errorHandler: ErrorRequestHandler = (error, req, res, _next) => {
  const requestId = (res.locals.requestId as string | undefined) ?? randomUUID();
  const apiError =
    error instanceof ApiError
      ? error
      : new ApiError({
          code: 'UNKNOWN_ERROR',
          status: 500,
          requestId,
        });

  console.error('Request failed', {
    requestId,
    endpoint: `${req.method} ${req.path}`,
    status: apiError.status,
    code: apiError.code,
  });

  res.status(apiError.status).json({
    error: {
      code: apiError.code,
      message: apiError.message,
      requestId,
    },
  });
};
