import 'package:flutter/painting.dart';

class AiAnalysis {
  final String evidenceLevel;
  final List<String> provenBenefits;
  final List<String> contraindications;
  final List<String> drugInteractions;
  final int safetyScore;
  final String summary;
  final DateTime generatedAt;

  const AiAnalysis({
    required this.evidenceLevel,
    required this.provenBenefits,
    required this.contraindications,
    this.drugInteractions = const [],
    required this.safetyScore,
    required this.summary,
    required this.generatedAt,
  });

  factory AiAnalysis.fromMap(Map<String, dynamic> map) {
    return AiAnalysis(
      evidenceLevel: map['evidenceLevel'] as String? ?? 'Inconnu',
      provenBenefits: List<String>.from(map['provenBenefits'] as List? ?? []),
      contraindications: List<String>.from(map['contraindications'] as List? ?? []),
      drugInteractions: List<String>.from(map['drugInteractions'] as List? ?? []),
      safetyScore: (map['safetyScore'] as num?)?.toInt() ?? 3,
      summary: map['summary'] as String? ?? '',
      generatedAt: map['generatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['generatedAt'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'evidenceLevel': evidenceLevel,
        'provenBenefits': provenBenefits,
        'contraindications': contraindications,
        'drugInteractions': drugInteractions,
        'safetyScore': safetyScore,
        'summary': summary,
        'generatedAt': generatedAt.millisecondsSinceEpoch,
      };

  Color get evidenceColor {
    switch (evidenceLevel) {
      case 'Bien documenté':
        return const Color(0xFF4CAF50);
      case 'Limité':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  Color get safetyColor {
    if (safetyScore >= 4) return const Color(0xFF4CAF50);
    if (safetyScore == 3) return const Color(0xFFFF9800);
    return const Color(0xFFD32F2F);
  }
}
