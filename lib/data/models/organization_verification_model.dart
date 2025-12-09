import 'package:cloud_firestore/cloud_firestore.dart';

enum VerificationStatus {
  pending,
  approved,
  rejected,
}

class OrganizationVerificationModel {
  final String id;
  final String organizationId;
  final String organizationName;
  final String? organizationPhotoUrl;
  final List<String> documents;
  final VerificationStatus status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
  final String email;
  final String? phoneNumber;

  OrganizationVerificationModel({
    required this.id,
    required this.organizationId,
    required this.organizationName,
    this.organizationPhotoUrl,
    required this.documents,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
    required this.email,
    this.phoneNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organizationId': organizationId,
      'organizationName': organizationName,
      'organizationPhotoUrl': organizationPhotoUrl,
      'documents': documents,
      'status': status.name,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
      'email': email,
      'phoneNumber': phoneNumber,
    };
  }

  factory OrganizationVerificationModel.fromMap(
      Map<String, dynamic> map,
      String id,
      ) {
    return OrganizationVerificationModel(
      id: id,
      organizationId: map['organizationId'] as String,
      organizationName: map['organizationName'] as String,
      organizationPhotoUrl: map['organizationPhotoUrl'] as String?,
      documents: List<String>.from(map['documents'] ?? []),
      status: VerificationStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => VerificationStatus.pending,
      ),
      submittedAt: (map['submittedAt'] as Timestamp).toDate(),
      reviewedAt: map['reviewedAt'] != null
          ? (map['reviewedAt'] as Timestamp).toDate()
          : null,
      reviewedBy: map['reviewedBy'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
      email: map['email'] as String,
      phoneNumber: map['phoneNumber'] as String?,
    );
  }
}
