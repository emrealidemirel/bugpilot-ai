export const screenshotUploadConfig = {
  fieldName: 'screenshot',
  bugFieldName: 'bug',
  maxSizeBytes: 5 * 1024 * 1024,
  supportedMimeTypes: new Set(['image/jpeg', 'image/png']),
} as const;
