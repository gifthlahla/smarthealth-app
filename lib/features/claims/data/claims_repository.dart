import 'dart:io';
import 'package:smarthealth/features/claims/domain/claim_model.dart';

abstract class ClaimsRepository {
  Stream<List<ClaimModel>> getUserClaims(String userId);

  Future<List<ClaimModel>> fetchUserClaims(String userId);

  Future<ClaimModel> getClaimById(String claimId);

  Future<ClaimModel> submitClaim({
    required String userId,
    required ClaimType claimType,
    required double amount,
    required DateTime serviceDate,
    String? description,
    List<String>? documentPaths,
  });

  Future<String> uploadClaimDocument({
    required String userId,
    required String claimId,
    required File file,
    required String folder,
  });

  Future<void> deleteClaim(String claimId);

  String getPublicUrl(String filePath);
}
