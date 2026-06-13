import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Remedy extends Equatable {
  final String id;
  final String title;
  final String description;
  final List<String> ingredients;
  final String method;
  final List<String> tags;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final double averageRating;
  final int ratingCount;
  final int commentCount;
  final String? imageUrl;
  final bool isReported;
  final bool isPrivate;
  final bool authorIsPremium;

  const Remedy({
    required this.id,
    required this.title,
    required this.description,
    required this.ingredients,
    required this.method,
    required this.tags,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.commentCount = 0,
    this.imageUrl,
    this.isReported = false,
    this.isPrivate = false,
    this.authorIsPremium = false,
  });

  factory Remedy.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Remedy(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      ingredients: List<String>.from(data['ingredients'] as List? ?? []),
      method: data['method'] as String? ?? '',
      tags: List<String>.from(data['tags'] as List? ?? []),
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Anonyme',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: data['ratingCount'] as int? ?? 0,
      commentCount: data['commentCount'] as int? ?? 0,
      imageUrl: data['imageUrl'] as String?,
      isReported: data['isReported'] as bool? ?? false,
      isPrivate: data['isPrivate'] as bool? ?? false,
      authorIsPremium: data['authorIsPremium'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'ingredients': ingredients,
        'method': method,
        'tags': tags,
        'authorId': authorId,
        'authorName': authorName,
        'createdAt': Timestamp.fromDate(createdAt),
        'averageRating': averageRating,
        'ratingCount': ratingCount,
        'commentCount': commentCount,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'isReported': isReported,
        'isPrivate': isPrivate,
        'authorIsPremium': authorIsPremium,
      };

  Remedy copyWith({
    double? averageRating,
    int? ratingCount,
    int? commentCount,
    String? imageUrl,
  }) =>
      Remedy(
        id: id,
        title: title,
        description: description,
        ingredients: ingredients,
        method: method,
        tags: tags,
        authorId: authorId,
        authorName: authorName,
        createdAt: createdAt,
        averageRating: averageRating ?? this.averageRating,
        ratingCount: ratingCount ?? this.ratingCount,
        commentCount: commentCount ?? this.commentCount,
        imageUrl: imageUrl ?? this.imageUrl,
        isReported: isReported,
        isPrivate: isPrivate,
        authorIsPremium: authorIsPremium,
      );

  @override
  List<Object?> get props => [
        id, title, description, authorId, tags, createdAt,
        averageRating, ratingCount, commentCount, isReported,
        isPrivate, authorIsPremium,
      ];
}
