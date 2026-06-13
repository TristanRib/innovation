import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserCollection extends Equatable {
  final String id;
  final String name;
  final List<String> remedyIds;
  final DateTime createdAt;

  const UserCollection({
    required this.id,
    required this.name,
    this.remedyIds = const [],
    required this.createdAt,
  });

  factory UserCollection.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserCollection(
      id: doc.id,
      name: data['name'] as String? ?? '',
      remedyIds: List<String>.from(data['remedyIds'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'remedyIds': remedyIds,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  UserCollection copyWith({String? name, List<String>? remedyIds}) => UserCollection(
        id: id,
        name: name ?? this.name,
        remedyIds: remedyIds ?? this.remedyIds,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, name, remedyIds, createdAt];
}
