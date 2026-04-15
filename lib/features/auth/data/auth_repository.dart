import 'package:smarthealth/features/auth/domain/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? membershipNumber,
  });

  Future<void> signOut();

  Future<UserModel?> getCurrentUser(String userId);

  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? membershipNumber,
    String? avatarUrl,
  });

  Future<void> resetPassword(String email);

  Stream<UserModel?> get authStateChanges;
}
