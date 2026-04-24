import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smarthealth/features/auth/presentation/providers/auth_provider.dart';
import 'package:smarthealth/features/auth/presentation/screens/login_screen.dart';
import 'package:smarthealth/features/auth/presentation/screens/register_screen.dart';
import 'package:smarthealth/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:smarthealth/features/home/presentation/screens/home_screen.dart';
import 'package:smarthealth/features/claims/presentation/screens/claims_list_screen.dart';
import 'package:smarthealth/features/claims/presentation/screens/claim_detail_screen.dart';
import 'package:smarthealth/features/claims/presentation/screens/submit_claim_screen.dart';
import 'package:smarthealth/features/profile/presentation/screens/profile_screen.dart';
import 'package:smarthealth/core/constants/app_colors.dart';

/// A ChangeNotifier that bridges Riverpod auth state to GoRouter's
/// refreshListenable. This way GoRouter is created ONCE and only
/// re-evaluates its redirect when auth state actually changes.
class AuthNotifier extends ChangeNotifier {
  final Ref _ref;
  bool _isLoggedIn = false;
  bool _isLoading = true;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  AuthNotifier(this._ref) {
    // Listen to auth state changes and notify GoRouter
    _ref.listen<AsyncValue>(authControllerProvider, (prev, next) {
      final wasLoggedIn = _isLoggedIn;
      final wasLoading = _isLoading;

      _isLoading = next.isLoading;
      _isLoggedIn = !next.isLoading && next.value != null;

      // Only notify if something actually changed
      if (wasLoggedIn != _isLoggedIn || wasLoading != _isLoading) {
        notifyListeners();
      }
    });

    // Set initial state from current auth
    final current = _ref.read(authControllerProvider);
    _isLoading = current.isLoading;
    _isLoggedIn = !current.isLoading && current.value != null;
  }
}

final _authNotifierProvider = Provider<AuthNotifier>((ref) {
  return AuthNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  // Read once — the GoRouter is only created once
  final authNotifier = ref.watch(_authNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authNotifier, // Re-evaluates redirect on auth changes
    redirect: (context, state) {
      final isLoggedIn = authNotifier.isLoggedIn;
      final isLoading = authNotifier.isLoading;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';

      // Still loading — don't redirect, stay where you are
      if (isLoading) return null;

      // Not logged in → go to login
      if (!isLoggedIn && !isAuthRoute) return '/login';

      // Logged in and on an auth page → go to home
      if (isLoggedIn && isAuthRoute) return '/home';

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main app with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/claims',
                builder: (context, state) => const ClaimsListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Detail routes (outside bottom nav)
      GoRoute(
        path: '/claim/:id',
        builder: (context, state) => ClaimDetailScreen(
          claimId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/submit-claim',
        builder: (context, state) => const SubmitClaimScreen(),
      ),
    ],
  );
});

class _MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _MainScaffold({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
          indicatorColor: AppColors.primary.withOpacity(0.12),
          height: 65,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primary),
              label: 'Claims',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
