import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smarthealth/core/constants/app_colors.dart';
import 'package:smarthealth/core/constants/app_strings.dart';
import 'package:smarthealth/core/widgets/empty_state_widget.dart';
import 'package:smarthealth/core/widgets/error_widget.dart';
import 'package:smarthealth/core/widgets/loading_shimmer.dart';
import 'package:smarthealth/features/auth/presentation/providers/auth_provider.dart';
import 'package:smarthealth/features/claims/presentation/providers/claims_provider.dart';
import 'package:smarthealth/features/claims/presentation/widgets/claim_card.dart';

class ClaimsListScreen extends ConsumerWidget {
  const ClaimsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final userId = authState.value?.id ?? '';
    final claimsAsync = ref.watch(userClaimsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.myClaims),
        centerTitle: true,
      ),
      body: claimsAsync.when(
        data: (claims) {
          if (claims.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.receipt_long_outlined,
              title: AppStrings.noClaims,
              message: AppStrings.noClaimsMessage,
              actionLabel: AppStrings.newClaim,
              onAction: () => context.push('/submit-claim'),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(userClaimsProvider(userId));
              // Wait for the new data to load
              await ref.read(userClaimsProvider(userId).future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              itemCount: claims.length,
              itemBuilder: (context, index) {
                final claim = claims[index];
                return ClaimCard(
                  claim: claim,
                  onTap: () => context.push('/claim/${claim.id}'),
                );
              },
            ),
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: 5,
          itemBuilder: (context, index) => const SkeletonClaimCard(),
        ),
        error: (error, stack) => ErrorWidgetDisplay(
          message: 'Failed to load claims',
          onRetry: () => ref.invalidate(userClaimsProvider(userId)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'newClaim',
        onPressed: () => context.push('/submit-claim'),
        icon: const Icon(Icons.add_rounded),
        label: const Text(AppStrings.newClaim),
      ),
    );
  }
}
