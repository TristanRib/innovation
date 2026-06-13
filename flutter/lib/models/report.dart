import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportTargetType { remedy, comment, user }

class Report {
  final String id;
  final String reporterId;
  final ReportTargetType targetType;
  final String targetId;
  final String reason;
  final DateTime createdAt;
  final bool isResolved;

  const Report({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.createdAt,
    this.isResolved = false,
  });

  Map<String, dynamic> toFirestore() => {
        'reporterId': reporterId,
        'targetType': targetType.name,
        'targetId': targetId,
        'reason': reason,
        'createdAt': Timestamp.fromDate(createdAt),
        'isResolved': isResolved,
      };
}
