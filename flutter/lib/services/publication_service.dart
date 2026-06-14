import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/publication.dart';

class PublicationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('publications');

  Stream<List<Publication>> watchAll() {
    return _col
        .orderBy('publishedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Publication.fromFirestore(d)).toList());
  }

  Future<Publication?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return Publication.fromFirestore(doc);
  }
}
