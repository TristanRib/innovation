import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String uid;
  final String email;
  final String pseudo;
  final int createdRemediesCount;
  final DateTime createdAt;
  final bool isPremium;
  final List<String> followedTags;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.pseudo,
    this.createdRemediesCount = 0,
    required this.createdAt,
    this.isPremium = false,
    this.followedTags = const [],
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      pseudo: data['pseudo'] as String? ?? 'Anonyme',
      createdRemediesCount: data['createdRemediesCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPremium: data['isPremium'] as bool? ?? false,
      followedTags: List<String>.from(data['followedTags'] as List? ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'pseudo': pseudo,
        'createdRemediesCount': createdRemediesCount,
        'createdAt': Timestamp.fromDate(createdAt),
        'isPremium': isPremium,
        'followedTags': followedTags,
      };

  UserProfile copyWith({
    String? pseudo,
    int? createdRemediesCount,
    bool? isPremium,
    List<String>? followedTags,
  }) =>
      UserProfile(
        uid: uid,
        email: email,
        pseudo: pseudo ?? this.pseudo,
        createdRemediesCount: createdRemediesCount ?? this.createdRemediesCount,
        createdAt: createdAt,
        isPremium: isPremium ?? this.isPremium,
        followedTags: followedTags ?? this.followedTags,
      );

  @override
  List<Object?> get props => [uid, pseudo, email, createdRemediesCount, createdAt, isPremium, followedTags];
}
