import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final String id;
  final String remedyId;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final bool isReported;

  const Comment({
    required this.id,
    required this.remedyId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.isReported = false,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc, String remedyId) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      remedyId: remedyId,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Anonyme',
      content: data['content'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isReported: data['isReported'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'authorId': authorId,
        'authorName': authorName,
        'content': content,
        'createdAt': Timestamp.fromDate(createdAt),
        'isReported': isReported,
      };

  @override
  List<Object?> get props => [id, content, createdAt];
}
