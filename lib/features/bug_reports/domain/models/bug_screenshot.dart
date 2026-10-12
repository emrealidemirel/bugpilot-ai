class BugScreenshot {
  const BugScreenshot({
    required this.id,
    required this.localPath,
    required this.mimeType,
    this.fileName,
    this.sizeBytes,
  });

  factory BugScreenshot.fromJson(Map<String, dynamic> json) {
    return BugScreenshot(
      id: json['id'] as String,
      localPath: json['localPath'] as String,
      fileName: json['fileName'] as String?,
      mimeType: json['mimeType'] as String,
      sizeBytes: json['sizeBytes'] as int?,
    );
  }

  final String id;
  final String localPath;
  final String? fileName;
  final String mimeType;
  final int? sizeBytes;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'localPath': localPath,
      if (fileName != null) 'fileName': fileName,
      'mimeType': mimeType,
      if (sizeBytes != null) 'sizeBytes': sizeBytes,
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BugScreenshot &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            localPath == other.localPath &&
            fileName == other.fileName &&
            mimeType == other.mimeType &&
            sizeBytes == other.sizeBytes;
  }

  @override
  int get hashCode {
    return Object.hash(id, localPath, fileName, mimeType, sizeBytes);
  }
}
