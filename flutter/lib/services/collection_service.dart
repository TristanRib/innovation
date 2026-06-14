import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/user_collection.dart';

const kFavoritesCollectionId = 'favoris';

class CollectionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference _col(String uid) =>
      _db.collection('users').doc(uid).collection('collections');

  Stream<List<UserCollection>> watchCollections(String uid) => _col(uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => UserCollection.fromFirestore(d)).toList());

  Future<UserCollection> create(String uid, String name) async {
    final id = _uuid.v4();
    final col = UserCollection(id: id, name: name, createdAt: DateTime.now());
    await _col(uid).doc(id).set(col.toFirestore());
    return col;
  }

  Future<void> addRemedy(String uid, String collectionId, String remedyId) async {
    await _col(uid).doc(collectionId).update({
      'remedyIds': FieldValue.arrayUnion([remedyId]),
    });
  }

  Future<void> removeRemedy(String uid, String collectionId, String remedyId) async {
    await _col(uid).doc(collectionId).update({
      'remedyIds': FieldValue.arrayRemove([remedyId]),
    });
  }

  Future<void> delete(String uid, String collectionId) async {
    await _col(uid).doc(collectionId).delete();
  }

  Future<void> toggleFavorite(String uid, String remedyId, bool add) async {
    final doc = _col(uid).doc(kFavoritesCollectionId);
    final snap = await doc.get();
    if (!snap.exists) {
      await doc.set({
        'name': 'Favoris',
        'remedyIds': add ? [remedyId] : [],
        'createdAt': Timestamp.now(),
      });
    } else {
      await doc.update({
        'remedyIds': add
            ? FieldValue.arrayUnion([remedyId])
            : FieldValue.arrayRemove([remedyId]),
      });
    }
  }
}
