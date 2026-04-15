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

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';

      // Still loading auth state
      if (authState.isLoading) return null;

      // Not logged in, force to auth routes
      if (!isLoggedIn && !isAuthRoute) return '/login';

      // Logged in, redirect away from auth routes
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
