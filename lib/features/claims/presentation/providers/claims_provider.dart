import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smarthealth/features/claims/data/claims_repository.dart';
import 'package:smarthealth/features/claims/data/claims_repository_impl.dart';
import 'package:smarthealth/features/claims/domain/claim_model.dart';

final claimsRepositoryProvider = Provider<ClaimsRepository>((ref) {
  return ClaimsRepositoryImpl(supabase: Supabase.instance.client);
});

/// Uses a direct DB query (not stream) so data is always fresh.
/// Invalidate this provider to refetch from the database.
final userClaimsProvider =
    FutureProvider.family<List<ClaimModel>, String>((ref, userId) async {
  if (userId.isEmpty) return [];
  final claimsRepository = ref.watch(claimsRepositoryProvider);
  return claimsRepository.fetchUserClaims(userId);
});

final claimDetailProvider =
    FutureProvider.family<ClaimModel, String>((ref, claimId) async {
  final claimsRepository = ref.watch(claimsRepositoryProvider);
  return await claimsRepository.getClaimById(claimId);
});

final claimsControllerProvider =
    StateNotifierProvider<ClaimsController, AsyncValue<void>>((ref) {
  final claimsRepository = ref.watch(claimsRepositoryProvider);
  return ClaimsController(claimsRepository: claimsRepository, ref: ref);
});

class ClaimsController extends StateNotifier<AsyncValue<void>> {
  final ClaimsRepository _claimsRepository;
  final Ref _ref;

  ClaimsController({required ClaimsRepository claimsRepository, required Ref ref})
      : _claimsRepository = claimsRepository,
        _ref = ref,
        super(const AsyncValue.data(null));

  Future<ClaimModel?> submitClaim({
    required String userId,
    required ClaimType claimType,
    required double amount,
    required DateTime serviceDate,
    String? description,
    List<File>? documents,
  }) async {
    state = const AsyncValue.loading();
    try {
      List<String> documentPaths = [];

      if (documents != null && documents.isNotEmpty) {
        for (final file in documents) {
          final path = await _claimsRepository.uploadClaimDocument(
            userId: userId,
            claimId: 'temp',
            file: file,
            folder: 'receipts',
          );
          documentPaths.add(path);
        }
      }

      final claim = await _claimsRepository.submitClaim(
        userId: userId,
        claimType: claimType,
        amount: amount,
        serviceDate: serviceDate,
        description: description,
        documentPaths: documentPaths,
      );

      state = const AsyncValue.data(null);

      // Force refresh the claims list so it updates immediately
      _ref.invalidate(userClaimsProvider(userId));

      return claim;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> deleteClaim(String claimId, String userId) async {
    try {
      await _claimsRepository.deleteClaim(claimId);

      // Force refresh the claims list after deletion
      _ref.invalidate(userClaimsProvider(userId));

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Manually refresh claims for a user (e.g. on pull-to-refresh)
  void refreshClaims(String userId) {
    _ref.invalidate(userClaimsProvider(userId));
  }
}
