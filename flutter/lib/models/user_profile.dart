import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String uid;
  final String email;
  final String pseudo;
  final List<String> favoriteRemedyIds;
  final int createdRemediesCount;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.pseudo,
    this.favoriteRemedyIds = const [],
    this.createdRemediesCount = 0,
    required this.createdAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      pseudo: data['pseudo'] as String? ?? 'Anonyme',
      favoriteRemedyIds: List<String>.from(data['favoriteRemedyIds'] as List? ?? []),
      createdRemediesCount: data['createdRemediesCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'pseudo': pseudo,
        'favoriteRemedyIds': favoriteRemedyIds,
        'createdRemediesCount': createdRemediesCount,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  UserProfile copyWith({
    String? pseudo,
    List<String>? favoriteRemedyIds,
    int? createdRemediesCount,
  }) =>
      UserProfile(
        uid: uid,
        email: email,
        pseudo: pseudo ?? this.pseudo,
        favoriteRemedyIds: favoriteRemedyIds ?? this.favoriteRemedyIds,
        createdRemediesCount: createdRemediesCount ?? this.createdRemediesCount,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [uid, pseudo, favoriteRemedyIds, createdRemediesCount];
}
