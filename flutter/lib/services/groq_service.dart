import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config.dart';
import '../models/remedy.dart';
import '../models/ai_analysis.dart';

class GroqService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<AiAnalysis> analyzeRemedy(Remedy remedy, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _loadCached(remedy.id);
      if (cached != null) return cached;
    }

    final analysis = await _callGroq(remedy);
    try {
      await _saveToCache(remedy.id, analysis);
    } catch (_) {
      // Cache write failed (permissions or network) — return analysis anyway
    }
    return analysis;
  }

  Stream<AiAnalysis?> watchRemedyAnalysis(String remedyId) {
    return _db
        .collection('remedy_analyses')
        .doc(remedyId)
        .snapshots()
        .map((doc) => doc.exists
            ? AiAnalysis.fromMap(Map<String, dynamic>.from(doc.data()!))
            : null);
  }

  Future<AiAnalysis?> _loadCached(String remedyId) async {
    final doc = await _db.collection('remedy_analyses').doc(remedyId).get();
    if (!doc.exists) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    final generatedAt = DateTime.fromMillisecondsSinceEpoch(data['generatedAt'] as int);
    if (DateTime.now().difference(generatedAt).inDays > 30) return null;
    return AiAnalysis.fromMap(data);
  }

  Future<void> _saveToCache(String remedyId, AiAnalysis analysis) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    await _db.collection('remedy_analyses').doc(remedyId).set(analysis.toMap());
  }

  Future<AiAnalysis> _callGroq(Remedy remedy) async {
    final prompt = _buildPrompt(remedy);

    final response = await http.post(
      Uri.parse(AppConfig.groqBaseUrl),
      headers: {
        'Authorization': 'Bearer ${AppConfig.groqApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': AppConfig.groqModel,
        'messages': [
          {
            'role': 'system',
            'content':
                'Tu es un expert en phytothérapie et médecine traditionnelle. '
                'Tu analyses des remèdes naturels de façon scientifique et factuelle. '
                'Tu réponds UNIQUEMENT en JSON valide, sans markdown, sans texte avant ou après.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.3,
        'max_tokens': 800,
        'response_format': {'type': 'json_object'},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Groq API error ${response.statusCode}: ${response.body}');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final content = body['choices'][0]['message']['content'] as String;
    final json = jsonDecode(content) as Map<String, dynamic>;
    return AiAnalysis.fromMap({...json, 'generatedAt': DateTime.now().millisecondsSinceEpoch});
  }

  String _buildPrompt(Remedy remedy) {
    return '''
Analyse ce remède naturel de façon scientifique et objective.

Remède : ${remedy.title}
Description : ${remedy.description}
Ingrédients : ${remedy.ingredients.join(', ')}
Méthode : ${remedy.method}
Catégories : ${remedy.tags.join(', ')}

Réponds avec exactement ce JSON (aucun texte en dehors) :
{
  "evidenceLevel": "Bien documenté" | "Limité" | "Anecdotique",
  "provenBenefits": ["effet prouvé 1 (source)", "effet prouvé 2 (source)"],
  "contraindications": ["contre-indication 1", "contre-indication 2"],
  "safetyScore": 1 à 5 (5 = très sûr),
  "summary": "Résumé factuel en 2-3 phrases claires"
}

Règles :
- Cite des études ou sources reconnues quand disponibles (ex: "Cochrane 2020")
- Si peu de preuves, indique "Anecdotique" honnêtement
- Mentionne les interactions médicamenteuses importantes
- Sois concis mais précis
- NE répète pas que ce n'est pas un avis médical (c'est déjà affiché dans l'app)
''';
  }
}
