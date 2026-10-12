import type { RequestHandler } from 'express';
import multer from 'multer';

import { screenshotUploadConfig } from '../config/screenshot_upload.js';
import { ApiError } from '../errors/api_error.js';

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: screenshotUploadConfig.maxSizeBytes,
    files: 1,
  },
  fileFilter: (_req, file, callback) => {
    if (!screenshotUploadConfig.supportedMimeTypes.has(file.mimetype)) {
      callback(
        new ApiError({
          code: 'INVALID_REQUEST',
          status: 400,
          message: 'This screenshot format is not supported.',
        }),
      );
      return;
    }

    callback(null, true);
  },
}).single(screenshotUploadConfig.fieldName);

export const optionalScreenshotUpload: RequestHandler = (req, res, next) => {
  if (!req.is('multipart/form-data')) {
    next();
    return;
  }

  upload(req, res, (error) => {
    if (!error) {
      next();
      return;
    }

    const requestId = res.locals.requestId as string | undefined;
    if (error instanceof ApiError) {
      next(
        new ApiError({
          code: error.code,
          status: error.status,
          message: error.message,
          requestId,
        }),
      );
      return;
    }

    if (error instanceof multer.MulterError) {
      next(
        new ApiError({
          code: 'INVALID_REQUEST',
          status: 400,
          message:
            error.code === 'LIMIT_FILE_SIZE'
              ? 'Screenshot is too large. Please choose an image smaller than 5 MB.'
              : 'Only one screenshot image may be uploaded.',
          requestId,
        }),
      );
      return;
    }

    next(error);
  });
};
