import 'package:flutter/material.dart';
import 'package:smarthealth/core/constants/app_colors.dart';

enum ClaimStatus {
  pending,
  underReview,
  approved,
  rejected,
  paid;

  String get displayName {
    switch (this) {
      case ClaimStatus.pending:
        return 'Pending';
      case ClaimStatus.underReview:
        return 'Under Review';
      case ClaimStatus.approved:
        return 'Approved';
      case ClaimStatus.rejected:
        return 'Rejected';
      case ClaimStatus.paid:
        return 'Paid';
    }
  }

  Color get color {
    switch (this) {
      case ClaimStatus.pending:
        return AppColors.pending;
      case ClaimStatus.underReview:
        return AppColors.underReview;
      case ClaimStatus.approved:
        return AppColors.approved;
      case ClaimStatus.rejected:
        return AppColors.rejected;
      case ClaimStatus.paid:
        return AppColors.paid;
    }
  }

  IconData get icon {
    switch (this) {
      case ClaimStatus.pending:
        return Icons.schedule_rounded;
      case ClaimStatus.underReview:
        return Icons.preview_rounded;
      case ClaimStatus.approved:
        return Icons.check_circle_rounded;
      case ClaimStatus.rejected:
        return Icons.cancel_rounded;
      case ClaimStatus.paid:
        return Icons.payments_rounded;
    }
  }

  static ClaimStatus fromString(String value) {
    return ClaimStatus.values.firstWhere(
      (e) => e.displayName.toLowerCase() == value.toLowerCase(),
      orElse: () => ClaimStatus.pending,
    );
  }
}

enum ClaimType {
  gpVisit,
  specialist,
  medicine,
  pathology,
  hospital,
  dental;

  String get displayName {
    switch (this) {
      case ClaimType.gpVisit:
        return 'GP Visit';
      case ClaimType.specialist:
        return 'Specialist';
      case ClaimType.medicine:
        return 'Medicine';
      case ClaimType.pathology:
        return 'Pathology';
      case ClaimType.hospital:
        return 'Hospital';
      case ClaimType.dental:
        return 'Dental';
    }
  }

  IconData get icon {
    switch (this) {
      case ClaimType.gpVisit:
        return Icons.local_hospital_rounded;
      case ClaimType.specialist:
        return Icons.medical_services_rounded;
      case ClaimType.medicine:
        return Icons.medication_rounded;
      case ClaimType.pathology:
        return Icons.biotech_rounded;
      case ClaimType.hospital:
        return Icons.apartment_rounded;
      case ClaimType.dental:
        return Icons.health_and_safety_rounded;
    }
  }

  static ClaimType fromString(String value) {
    final normalized = value.toLowerCase().replaceAll(' ', '');
    return ClaimType.values.firstWhere(
      (e) => e.displayName.toLowerCase().replaceAll(' ', '') == normalized,
      orElse: () => ClaimType.gpVisit,
    );
  }
}

class ClaimDocumentModel {
  final String id;
  final String claimId;
  final String fileName;
  final String filePath;
  final String? fileType;
  final DateTime uploadedAt;

  ClaimDocumentModel({
    required this.id,
    required this.claimId,
    required this.fileName,
    required this.filePath,
    this.fileType,
    required this.uploadedAt,
  });

  factory ClaimDocumentModel.fromJson(Map<String, dynamic> json) {
    return ClaimDocumentModel(
      id: json['id'],
      claimId: json['claim_id'],
      fileName: json['file_name'],
      filePath: json['file_path'],
      fileType: json['file_type'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'claim_id': claimId,
      'file_name': fileName,
      'file_path': filePath,
      'file_type': fileType,
    };
  }
}

class ClaimModel {
  final String id;
  final String userId;
  final ClaimType claimType;
  final double amount;
  final DateTime serviceDate;
  final String? description;
  final ClaimStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ClaimDocumentModel>? documents;

  ClaimModel({
    required this.id,
    required this.userId,
    required this.claimType,
    required this.amount,
    required this.serviceDate,
    this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.documents,
  });

  factory ClaimModel.fromJson(Map<String, dynamic> json) {
    return ClaimModel(
      id: json['id'],
      userId: json['user_id'],
      claimType: ClaimType.fromString(json['claim_type'] ?? 'GP Visit'),
      amount: (json['amount'] as num).toDouble(),
      serviceDate: DateTime.parse(json['service_date']),
      description: json['description'],
      status: ClaimStatus.fromString(json['status'] ?? 'Pending'),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      documents: json['claim_documents'] != null
          ? (json['claim_documents'] as List)
              .map((doc) => ClaimDocumentModel.fromJson(doc))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'claim_type': claimType.displayName,
      'amount': amount,
      'service_date': serviceDate.toIso8601String().split('T').first,
      'description': description,
      'status': status.displayName,
    };
  }
}
