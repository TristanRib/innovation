import 'package:cloud_firestore/cloud_firestore.dart';

class PublicationSection {
  final String type; // paragraph | heading | bullets | tip | warning | quote
  final String? content;
  final List<String> items;

  const PublicationSection({
    required this.type,
    this.content,
    this.items = const [],
  });

  factory PublicationSection.fromMap(Map<String, dynamic> map) {
    return PublicationSection(
      type: map['type'] as String? ?? 'paragraph',
      content: map['content'] as String?,
      items: List<String>.from(map['items'] as List? ?? []),
    );
  }
}

class Publication {
  final String id;
  final String title;
  final String summary;
  final String? imageUrl;
  final List<String> tags;
  final String authorName;
  final DateTime publishedAt;
  final int readingTimeMinutes;
  final List<PublicationSection> sections;

  const Publication({
    required this.id,
    required this.title,
    required this.summary,
    this.imageUrl,
    this.tags = const [],
    this.authorName = 'Équipe Remedia',
    required this.publishedAt,
    this.readingTimeMinutes = 3,
    this.sections = const [],
  });

  factory Publication.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Publication(
      id: doc.id,
      title: data['title'] as String? ?? '',
      summary: data['summary'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      tags: List<String>.from(data['tags'] as List? ?? []),
      authorName: data['authorName'] as String? ?? 'Équipe Remedia',
      publishedAt: data['publishedAt'] is Timestamp
          ? (data['publishedAt'] as Timestamp).toDate()
          : DateTime.now(),
      readingTimeMinutes: (data['readingTimeMinutes'] as num?)?.toInt() ?? 3,
      sections: (data['sections'] as List? ?? [])
          .map((s) => PublicationSection.fromMap(
              Map<String, dynamic>.from(s as Map)))
          .toList(),
    );
  }
}
