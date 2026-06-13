import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/remedy.dart';

enum RemediaSortBy { newest, topRated, mostCommented }

const kPageSize = 12;

class RemedyPage {
  final List<Remedy> items;
  final DocumentSnapshot? cursor;
  const RemedyPage({required this.items, this.cursor});
}

class RemedyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference get _collection => _db.collection('remedies');

  Stream<List<Remedy>> watchRemedies({
    String? tag,
    RemediaSortBy sortBy = RemediaSortBy.newest,
  }) {
    Query query = _collection.where('isReported', isEqualTo: false);
    if (tag != null && tag.isNotEmpty) {
      query = query.where('tags', arrayContains: tag);
    }
    switch (sortBy) {
      case RemediaSortBy.topRated:
        query = query.orderBy('averageRating', descending: true);
        break;
      case RemediaSortBy.mostCommented:
        query = query.orderBy('commentCount', descending: true);
        break;
      case RemediaSortBy.newest:
        query = query.orderBy('createdAt', descending: true);
        break;
    }
    return query.snapshots().map((snap) =>
        snap.docs.map((d) => Remedy.fromFirestore(d)).where((r) => !r.isPrivate).toList());
  }

  Future<RemedyPage> fetchPage({
    String? tag,
    RemediaSortBy sortBy = RemediaSortBy.newest,
    DocumentSnapshot? cursor,
  }) async {
    Query query = _collection.where('isReported', isEqualTo: false);
    if (tag != null && tag.isNotEmpty) {
      query = query.where('tags', arrayContains: tag);
    }
    switch (sortBy) {
      case RemediaSortBy.topRated:
        query = query.orderBy('averageRating', descending: true);
        break;
      case RemediaSortBy.mostCommented:
        query = query.orderBy('commentCount', descending: true);
        break;
      case RemediaSortBy.newest:
        query = query.orderBy('createdAt', descending: true);
        break;
    }
    if (cursor != null) query = query.startAfterDocument(cursor);
    final snap = await query.limit(kPageSize).get();
    return RemedyPage(
      items: snap.docs
          .map((d) => Remedy.fromFirestore(d))
          .where((r) => !r.isPrivate)
          .toList(),
      cursor: snap.docs.isNotEmpty ? snap.docs.last : null,
    );
  }

  Future<List<Remedy>> search(String query) async {
    final lower = query.toLowerCase();
    final snap = await _collection
        .where('isReported', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    return snap.docs
        .map((d) => Remedy.fromFirestore(d))
        .where((r) =>
            r.title.toLowerCase().contains(lower) ||
            r.description.toLowerCase().contains(lower) ||
            r.tags.any((t) => t.toLowerCase().contains(lower)))
        .toList();
  }

  Future<List<Remedy>> getRemediesForTags({required List<String> tags}) async {
    if (tags.isEmpty) return [];
    final snap = await _collection
        .where('tags', arrayContainsAny: tags.take(10).toList())
        .limit(100)
        .get();
    return snap.docs
        .map((d) => Remedy.fromFirestore(d))
        .where((r) => !r.isPrivate && !r.isReported)
        .toList();
  }

  Future<Remedy> createRemedy({
    required String title,
    required String description,
    required List<String> ingredients,
    required String method,
    required List<String> tags,
    required String authorId,
    required String authorName,
    bool isPrivate = false,
    bool authorIsPremium = false,
  }) async {
    final id = _uuid.v4();
    final remedy = Remedy(
      id: id,
      title: title,
      description: description,
      ingredients: ingredients,
      method: method,
      tags: tags,
      authorId: authorId,
      authorName: authorName,
      createdAt: DateTime.now(),
      isPrivate: isPrivate,
      authorIsPremium: authorIsPremium,
    );
    await _collection.doc(id).set(remedy.toFirestore());

    await _db.collection('users').doc(authorId).update({
      'createdRemediesCount': FieldValue.increment(1),
    });

    return remedy;
  }

  Future<void> rateRemedy(String remedyId, String userId, int stars) async {
    final ratingRef = _collection.doc(remedyId).collection('ratings').doc(userId);
    final remedyRef = _collection.doc(remedyId);

    await _db.runTransaction((tx) async {
      final existing = await tx.get(ratingRef);
      final remedySnap = await tx.get(remedyRef);
      final remedy = Remedy.fromFirestore(remedySnap);

      int newCount;
      double newSum;

      if (existing.exists) {
        final oldStars = existing.data()?['stars'] as int? ?? 0;
        newCount = remedy.ratingCount;
        newSum = (remedy.averageRating * remedy.ratingCount) - oldStars + stars;
      } else {
        newCount = remedy.ratingCount + 1;
        newSum = (remedy.averageRating * remedy.ratingCount) + stars;
      }

      final newAvg = newCount > 0 ? newSum / newCount : 0.0;

      tx.set(ratingRef, {'stars': stars, 'userId': userId});
      tx.update(remedyRef, {
        'averageRating': newAvg,
        'ratingCount': newCount,
      });
    });
  }

  Future<int?> getUserRating(String remedyId, String userId) async {
    final doc = await _collection.doc(remedyId).collection('ratings').doc(userId).get();
    if (!doc.exists) return null;
    return doc.data()?['stars'] as int?;
  }

  Future<void> toggleFavorite(String userId, String remedyId, bool isFavorite) async {
    await _db.collection('users').doc(userId).update({
      'favoriteRemedyIds': isFavorite
          ? FieldValue.arrayUnion([remedyId])
          : FieldValue.arrayRemove([remedyId]),
    });
  }

  Future<List<Remedy>> getFavorites(List<String> ids) async {
    if (ids.isEmpty) return [];
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      chunks.add(ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10));
    }
    final results = <Remedy>[];
    for (final chunk in chunks) {
      final snap = await _collection.where(FieldPath.documentId, whereIn: chunk).get();
      results.addAll(snap.docs.map((d) => Remedy.fromFirestore(d)));
    }
    return results;
  }

  Future<List<Remedy>> getUserRemedies(String userId) async {
    final snap = await _collection
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => Remedy.fromFirestore(d)).toList();
  }

  Future<Remedy?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Remedy.fromFirestore(doc);
  }

  Future<void> updateRemedy(Remedy remedy) async {
    await _collection.doc(remedy.id).update({
      'title': remedy.title,
      'description': remedy.description,
      'ingredients': remedy.ingredients,
      'method': remedy.method,
      'tags': remedy.tags,
      'isPrivate': remedy.isPrivate,
    });
  }

  Future<void> reportRemedy(String remedyId, String reporterId, String reason) async {
    await _db.collection('reports').add({
      'reporterId': reporterId,
      'targetType': 'remedy',
      'targetId': remedyId,
      'reason': reason,
      'createdAt': Timestamp.now(),
      'isResolved': false,
    });
  }
}
