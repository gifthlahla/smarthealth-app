import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smarthealth/features/claims/data/claims_repository.dart';
import 'package:smarthealth/features/claims/domain/claim_model.dart';

class ClaimsRepositoryImpl implements ClaimsRepository {
  final SupabaseClient _supabase;

  ClaimsRepositoryImpl({required SupabaseClient supabase}) : _supabase = supabase;

  @override
  Stream<List<ClaimModel>> getUserClaims(String userId) {
    return _supabase
        .from('claims')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => ClaimModel.fromJson(json)).toList());
  }

  @override
  Future<ClaimModel> getClaimById(String claimId) async {
    try {
      final response = await _supabase
          .from('claims')
          .select('*, claim_documents(*)')
          .eq('id', claimId)
          .single();

      return ClaimModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load claim details: $e');
    }
  }

  @override
  Future<ClaimModel> submitClaim({
    required String userId,
    required ClaimType claimType,
    required double amount,
    required DateTime serviceDate,
    String? description,
    List<String>? documentPaths,
  }) async {
    try {
      final claimData = {
        'user_id': userId,
        'claim_type': claimType.displayName,
        'amount': amount,
        'service_date': serviceDate.toIso8601String().split('T').first,
        'description': description,
      };

      final response = await _supabase
          .from('claims')
          .insert(claimData)
          .select()
          .single();

      final claim = ClaimModel.fromJson(response);

      // Add document references if any
      if (documentPaths != null && documentPaths.isNotEmpty) {
        for (final path in documentPaths) {
          await _supabase.from('claim_documents').insert({
            'claim_id': claim.id,
            'file_name': path.split('/').last,
            'file_path': path,
            'file_type': _getFileType(path),
          });
        }
      }

      return claim;
    } catch (e) {
      throw Exception('Failed to submit claim: $e');
    }
  }

  @override
  Future<String> uploadClaimDocument({
    required String userId,
    required String claimId,
    required File file,
    required String folder,
  }) async {
    try {
      final fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}_${file.path.split(Platform.pathSeparator).last}';
      final filePath = '$folder/$fileName';

      await _supabase.storage.from('claim-documents').upload(filePath, file);

      return filePath;
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  @override
  Future<void> deleteClaim(String claimId) async {
    try {
      await _supabase.from('claims').delete().eq('id', claimId);
    } catch (e) {
      throw Exception('Failed to delete claim: $e');
    }
  }

  @override
  String getPublicUrl(String filePath) {
    return _supabase.storage.from('claim-documents').getPublicUrl(filePath);
  }

  String _getFileType(String path) {
    final extension = path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      return 'image';
    } else if (extension == 'pdf') {
      return 'pdf';
    }
    return 'document';
  }
}
