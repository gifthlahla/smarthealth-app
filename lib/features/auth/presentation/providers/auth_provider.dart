import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smarthealth/features/auth/data/auth_repository.dart';
import 'package:smarthealth/features/auth/data/auth_repository_impl.dart';
import 'package:smarthealth/features/auth/domain/user_model.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(supabase: ref.watch(supabaseClientProvider));
});

final authStateProvider = StreamProvider<UserModel?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserModel?>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository: authRepository);
});

class AuthController extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _authRepository;

  AuthController({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        final user = await _authRepository.getCurrentUser(currentUser.id);
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? membershipNumber,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        membershipNumber: membershipNumber,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? membershipNumber,
  }) async {
    try {
      await _authRepository.updateProfile(
        userId: userId,
        fullName: fullName,
        membershipNumber: membershipNumber,
      );
      // Refresh user data
      final updatedUser = await _authRepository.getCurrentUser(userId);
      state = AsyncValue.data(updatedUser);
    } catch (e, st) {
      // Don't change the auth state for profile update errors, just rethrow
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    await _authRepository.resetPassword(email);
  }
}
