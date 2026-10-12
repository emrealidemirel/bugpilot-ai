enum DuplicateSimilarity { likelyDuplicate, related, notDuplicate }

extension DuplicateSimilarityPresentation on DuplicateSimilarity {
  String get label {
    return switch (this) {
      DuplicateSimilarity.likelyDuplicate => 'Possible Duplicate',
      DuplicateSimilarity.related => 'Related',
      DuplicateSimilarity.notDuplicate => 'Not Duplicate',
    };
  }

  String get jsonValue {
    return switch (this) {
      DuplicateSimilarity.likelyDuplicate => 'likelyDuplicate',
      DuplicateSimilarity.related => 'related',
      DuplicateSimilarity.notDuplicate => 'notDuplicate',
    };
  }
}

DuplicateSimilarity duplicateSimilarityFromJson(String value) {
  return switch (value) {
    'likelyDuplicate' => DuplicateSimilarity.likelyDuplicate,
    'related' => DuplicateSimilarity.related,
    'notDuplicate' => DuplicateSimilarity.notDuplicate,
    _ => throw ArgumentError.value(
      value,
      'value',
      'Unknown duplicate similarity',
    ),
  };
}

class DuplicateMatch {
  const DuplicateMatch({
    required this.bugId,
    required this.similarity,
    required this.confidence,
    required this.reason,
  });

  factory DuplicateMatch.fromJson(Map<String, dynamic> json) {
    return DuplicateMatch(
      bugId: _requiredString(json, 'bugId'),
      similarity: duplicateSimilarityFromJson(
        _requiredString(json, 'similarity'),
      ),
      confidence: _requiredDouble(json, 'confidence'),
      reason: _requiredString(json, 'reason'),
    );
  }

  final String bugId;
  final DuplicateSimilarity similarity;
  final double confidence;
  final String reason;

  Map<String, dynamic> toJson() {
    return {
      'bugId': bugId,
      'similarity': similarity.jsonValue,
      'confidence': confidence,
      'reason': reason,
    };
  }
}

class DuplicateCheckResult {
  DuplicateCheckResult({required List<DuplicateMatch> matches})
    : matches = List.unmodifiable(matches);

  factory DuplicateCheckResult.fromJson(Map<String, dynamic> json) {
    final matchesJson = json['matches'];
    if (matchesJson is! List) {
      throw const FormatException(
        'Duplicate check response is missing matches.',
      );
    }

    return DuplicateCheckResult(
      matches: matchesJson.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Invalid duplicate match item.');
        }
        return DuplicateMatch.fromJson(item);
      }).toList(),
    );
  }

  final List<DuplicateMatch> matches;

  Map<String, dynamic> toJson() {
    return {'matches': matches.map((match) => match.toJson()).toList()};
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }

  return value;
}

double _requiredDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num) {
    throw FormatException('$key must be a number.');
  }

  final doubleValue = value.toDouble();
  if (doubleValue < 0 || doubleValue > 1) {
    throw FormatException('$key must be between 0.0 and 1.0.');
  }

  return doubleValue;
}
