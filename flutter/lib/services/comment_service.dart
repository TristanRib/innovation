import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/comment.dart';

class CommentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference _commentsOf(String remedyId) =>
      _db.collection('remedies').doc(remedyId).collection('comments');

  Stream<List<Comment>> watchComments(String remedyId) {
    return _commentsOf(remedyId)
        .where('isReported', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Comment.fromFirestore(d, remedyId)).toList());
  }

  Future<Comment> addComment({
    required String remedyId,
    required String authorId,
    required String authorName,
    required String content,
  }) async {
    final id = _uuid.v4();
    final comment = Comment(
      id: id,
      remedyId: remedyId,
      authorId: authorId,
      authorName: authorName,
      content: content,
      createdAt: DateTime.now(),
    );
    await _commentsOf(remedyId).doc(id).set(comment.toFirestore());
    await _db.collection('remedies').doc(remedyId).update({
      'commentCount': FieldValue.increment(1),
    });
    return comment;
  }

  Future<void> deleteComment(String remedyId, String commentId) async {
    await _commentsOf(remedyId).doc(commentId).delete();
    await _db.collection('remedies').doc(remedyId).update({
      'commentCount': FieldValue.increment(-1),
    });
  }

  Future<void> reportComment(String remedyId, String commentId, String reporterId) async {
    await _db.collection('reports').add({
      'reporterId': reporterId,
      'targetType': 'comment',
      'targetId': commentId,
      'remedyId': remedyId,
      'createdAt': Timestamp.now(),
      'isResolved': false,
    });
  }
}
