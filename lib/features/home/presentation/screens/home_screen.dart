import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smarthealth/core/constants/app_colors.dart';

import 'package:smarthealth/core/widgets/loading_shimmer.dart';
import 'package:smarthealth/features/auth/presentation/providers/auth_provider.dart';
import 'package:smarthealth/features/claims/domain/claim_model.dart';
import 'package:smarthealth/features/claims/presentation/providers/claims_provider.dart';
import 'package:smarthealth/features/claims/presentation/widgets/claim_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;
    final userId = user?.id ?? '';
    final claimsAsync = ref.watch(userClaimsProvider(userId));


    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.fullName ?? 'User',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => context.go('/profile'),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _initials(user?.fullName),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Stats row
                      claimsAsync.when(
                        data: (claims) => _buildStatsRow(context, claims),
                        loading: () => _buildStatsRowLoading(),
                        error: (_, __) => _buildStatsRow(context, []),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Quick actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.add_circle_rounded,
                      label: 'New Claim',
                      color: AppColors.primary,
                      onTap: () => context.push('/submit-claim'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.receipt_long_rounded,
                      label: 'All Claims',
                      color: AppColors.secondary,
                      onTap: () => context.go('/claims'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      color: AppColors.paid,
                      onTap: () => context.go('/profile'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recent claims header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Claims',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextButton(
                    onPressed: () => context.go('/claims'),
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
          ),

          // Recent claims list
          claimsAsync.when(
            data: (claims) {
              if (claims.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.receipt_long_outlined,
                            size: 40,
                            color: AppColors.primary.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No claims yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Submit your first claim to get started',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final recentClaims = claims.take(5).toList();
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return ClaimCard(
                      claim: recentClaims[index],
                      onTap: () =>
                          context.push('/claim/${recentClaims[index].id}'),
                    );
                  },
                  childCount: recentClaims.length,
                ),
              );
            },
            loading: () => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const SkeletonClaimCard(),
                childCount: 3,
              ),
            ),
            error: (error, stack) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Failed to load claims',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 👋';
    if (hour < 17) return 'Good Afternoon 👋';
    return 'Good Evening 👋';
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Widget _buildStatsRow(BuildContext context, List<ClaimModel> claims) {
    final pending = claims.where((c) => c.status == ClaimStatus.pending).length;
    final totalAmount = claims
        .where((c) => c.status == ClaimStatus.approved || c.status == ClaimStatus.paid)
        .fold<double>(0, (sum, c) => sum + c.amount);

    return Row(
      children: [
        _StatChip(
          label: 'Total Claims',
          value: '${claims.length}',
          icon: Icons.receipt_rounded,
        ),
        const SizedBox(width: 8),
        _StatChip(
          label: 'Pending',
          value: '$pending',
          icon: Icons.schedule_rounded,
        ),
        const SizedBox(width: 8),
        _StatChip(
          label: 'Approved',
          value: '\$${totalAmount.toStringAsFixed(0)}',
          icon: Icons.check_circle_rounded,
        ),
      ],
    );
  }

  Widget _buildStatsRowLoading() {
    return Row(
      children: List.generate(
        3,
        (_) => Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.7), size: 16),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
