import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smarthealth/features/auth/data/auth_repository.dart';
import 'package:smarthealth/features/auth/domain/user_model.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabase;

  AuthRepositoryImpl({required SupabaseClient supabase}) : _supabase = supabase;

  @override
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return await getCurrentUser(response.user!.id);
      }
      return null;
    } on AuthApiException catch (e) {
      throw AuthException(_mapAuthError(e.message));
    } catch (e) {
      throw AuthException('An unexpected error occurred. Please try again.');
    }
  }

  @override
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? membershipNumber,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user != null) {
        // Update profile with membership number if provided
        if (membershipNumber != null && membershipNumber.isNotEmpty) {
          await _supabase
              .from('profiles')
              .update({'membership_number': membershipNumber})
              .eq('id', response.user!.id);
        }

        return await getCurrentUser(response.user!.id);
      }
      return null;
    } on AuthApiException catch (e) {
      throw AuthException(_mapAuthError(e.message));
    } catch (e) {
      throw AuthException('An unexpected error occurred. Please try again.');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw AuthException('Failed to sign out. Please try again.');
    }
  }

  @override
  Future<UserModel?> getCurrentUser(String userId) async {
    try {
      if (userId.isEmpty) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      final user = _supabase.auth.currentUser;

      return UserModel(
        id: response['id'],
        email: user?.email ?? '',
        fullName: response['full_name'],
        membershipNumber: response['membership_number'],
        avatarUrl: response['avatar_url'],
        createdAt: DateTime.parse(response['created_at']),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? membershipNumber,
    String? avatarUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (fullName != null) updates['full_name'] = fullName;
      if (membershipNumber != null) updates['membership_number'] = membershipNumber;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      await _supabase.from('profiles').update(updates).eq('id', userId);
    } catch (e) {
      throw AuthException('Failed to update profile. Please try again.');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthApiException catch (e) {
      throw AuthException(_mapAuthError(e.message));
    } catch (e) {
      throw AuthException('Failed to send reset email. Please try again.');
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.asyncMap((event) async {
      final user = event.session?.user;
      if (user != null) {
        return await getCurrentUser(user.id);
      }
      return null;
    });
  }

  String _mapAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials') || lower.contains('invalid_credentials')) {
      return 'Invalid email or password. Please check your credentials.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Please verify your email address before signing in.';
    }
    if (lower.contains('user already registered')) {
      return 'An account with this email already exists.';
    }
    if (lower.contains('password')) {
      return 'Password must be at least 6 characters long.';
    }
    if (lower.contains('rate limit')) {
      return 'Too many attempts. Please try again later.';
    }
    return message;
  }
}
