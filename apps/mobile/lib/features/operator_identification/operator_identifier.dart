enum OperatorIdentificationStatus { identified, lowConfidence, unknown, manual }

class OperatorLabelProfile {
  OperatorLabelProfile({required this.operatorId, required this.markers})
    : assert(markers.isNotEmpty);

  final String operatorId;
  final List<String> markers;
}

class OperatorIdentificationResult {
  const OperatorIdentificationResult({
    required this.status,
    required this.confidence,
    required this.matchedMarkers,
    this.operatorId,
    this.suggestedOperatorId,
  });

  final OperatorIdentificationStatus status;
  final double confidence;
  final List<String> matchedMarkers;
  final String? operatorId;
  final String? suggestedOperatorId;
}

class OperatorIdentifier {
  const OperatorIdentifier({this.minimumConfidence = 0.66});

  final double minimumConfidence;

  OperatorIdentificationResult identify({
    required String labelText,
    required List<OperatorLabelProfile> profiles,
  }) {
    final normalizedLabel = _normalize(labelText);

    if (normalizedLabel.isEmpty || profiles.isEmpty) {
      return const OperatorIdentificationResult(
        status: OperatorIdentificationStatus.unknown,
        confidence: 0,
        matchedMarkers: [],
      );
    }

    final candidates = profiles.map((profile) {
      final normalizedMarkers = profile.markers
          .map(_normalize)
          .where((marker) => marker.isNotEmpty)
          .toList(growable: false);

      final matches = normalizedMarkers
          .where(normalizedLabel.contains)
          .toList(growable: false);

      final confidence = normalizedMarkers.isEmpty
          ? 0.0
          : matches.length / normalizedMarkers.length;

      return _Candidate(
        operatorId: profile.operatorId,
        confidence: confidence,
        matchedMarkers: matches,
      );
    }).toList();

    candidates.sort(
      (first, second) => second.confidence.compareTo(first.confidence),
    );

    final best = candidates.first;

    if (best.confidence == 0) {
      return const OperatorIdentificationResult(
        status: OperatorIdentificationStatus.unknown,
        confidence: 0,
        matchedMarkers: [],
      );
    }

    final hasEqualCandidate =
        candidates.length > 1 && candidates[1].confidence == best.confidence;

    if (hasEqualCandidate) {
      return OperatorIdentificationResult(
        status: OperatorIdentificationStatus.lowConfidence,
        confidence: best.confidence,
        matchedMarkers: best.matchedMarkers,
      );
    }

    if (best.confidence < minimumConfidence) {
      return OperatorIdentificationResult(
        status: OperatorIdentificationStatus.lowConfidence,
        confidence: best.confidence,
        matchedMarkers: best.matchedMarkers,
        suggestedOperatorId: best.operatorId,
      );
    }

    return OperatorIdentificationResult(
      status: OperatorIdentificationStatus.identified,
      confidence: best.confidence,
      matchedMarkers: best.matchedMarkers,
      operatorId: best.operatorId,
    );
  }

  String _normalize(String value) {
    var normalized = value.toUpperCase();

    const replacements = {
      'Á': 'A',
      'É': 'E',
      'Í': 'I',
      'Ó': 'O',
      'Ú': 'U',
      'Ü': 'U',
      'Ñ': 'N',
    };

    for (final replacement in replacements.entries) {
      normalized = normalized.replaceAll(replacement.key, replacement.value);
    }

    return normalized
        .replaceAll(RegExp(r'[^A-Z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}

class _Candidate {
  const _Candidate({
    required this.operatorId,
    required this.confidence,
    required this.matchedMarkers,
  });

  final String operatorId;
  final double confidence;
  final List<String> matchedMarkers;
}
