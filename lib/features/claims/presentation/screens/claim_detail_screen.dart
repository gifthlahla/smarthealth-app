import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smarthealth/core/constants/app_colors.dart';
import 'package:smarthealth/core/widgets/error_widget.dart';
import 'package:smarthealth/features/claims/domain/claim_model.dart';
import 'package:smarthealth/features/claims/presentation/providers/claims_provider.dart';
import 'package:smarthealth/features/claims/presentation/widgets/claim_status_badge.dart';

class ClaimDetailScreen extends ConsumerWidget {
  final String claimId;

  const ClaimDetailScreen({super.key, required this.claimId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimAsync = ref.watch(claimDetailProvider(claimId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Claim Details')),
      body: claimAsync.when(
        data: (claim) => _buildClaimDetail(context, ref, claim, isDark),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorWidgetDisplay(
          message: 'Failed to load claim details',
          onRetry: () => ref.invalidate(claimDetailProvider(claimId)),
        ),
      ),
    );
  }

  Widget _buildClaimDetail(
    BuildContext context,
    WidgetRef ref,
    ClaimModel claim,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            claim.claimType.icon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          claim.claimType.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    ClaimStatusBadge(status: claim.status),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  '\$${claim.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Claim Amount',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Details section
          _buildSectionTitle(context, 'Claim Information'),
          const SizedBox(height: 12),
          _buildDetailCard(context, isDark, [
            _detailRow(
              context,
              'Claim ID',
              claim.id.substring(0, 8).toUpperCase(),
              isDark,
            ),
            _detailRow(context, 'Type', claim.claimType.displayName, isDark),
            _detailRow(
              context,
              'Service Date',
              DateFormat('MMMM dd, yyyy').format(claim.serviceDate),
              isDark,
            ),
            _detailRow(
              context,
              'Submitted',
              DateFormat('MMMM dd, yyyy • h:mm a').format(claim.createdAt),
              isDark,
            ),
            _detailRow(
              context,
              'Last Updated',
              DateFormat('MMMM dd, yyyy • h:mm a').format(claim.updatedAt),
              isDark,
            ),
          ]),

          if (claim.description != null && claim.description!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Description'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
              child: Text(
                claim.description!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],

          // Documents section
          if (claim.documents != null && claim.documents!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionTitle(
              context,
              'Attached Documents (${claim.documents!.length})',
            ),
            const SizedBox(height: 12),
            ...claim.documents!.map(
              (doc) => _buildDocumentTile(context, doc, isDark),
            ),
          ],

          // Status timeline
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Status Timeline'),
          const SizedBox(height: 12),
          _buildStatusTimeline(context, claim.status, isDark),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.headlineSmall);
  }

  Widget _buildDetailCard(
    BuildContext context,
    bool isDark,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _detailRow(
    BuildContext context,
    String label,
    String value,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTile(
    BuildContext context,
    ClaimDocumentModel doc,
    bool isDark,
  ) {
    final isImage = doc.fileType == 'image';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isImage ? AppColors.underReview : AppColors.rejected)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isImage ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
              color: isImage ? AppColors.underReview : AppColors.rejected,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.fileName,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  doc.fileType?.toUpperCase() ?? 'DOCUMENT',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(
            Icons.open_in_new_rounded,
            size: 20,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textTertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(
    BuildContext context,
    ClaimStatus currentStatus,
    bool isDark,
  ) {
    final statuses = ClaimStatus.values;
    final currentIndex = statuses.indexOf(currentStatus);

    // For rejected, show: Pending -> Under Review -> Rejected
    final displayStatuses = currentStatus == ClaimStatus.rejected
        ? [ClaimStatus.pending, ClaimStatus.underReview, ClaimStatus.rejected]
        : statuses;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        children: displayStatuses.asMap().entries.map((entry) {
          final index = entry.key;
          final status = entry.value;
          final isActive = currentStatus == ClaimStatus.rejected
              ? index <= displayStatuses.indexOf(currentStatus)
              : statuses.indexOf(status) <= currentIndex;
          final isLast = index == displayStatuses.length - 1;

          return Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isActive
                          ? status.color.withOpacity(0.15)
                          : (isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.surfaceVariant),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive ? status.color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      isActive ? status.icon : Icons.circle_outlined,
                      size: 16,
                      color: isActive
                          ? status.color
                          : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textTertiary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      status.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isActive
                            ? (isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary)
                            : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textTertiary),
                      ),
                    ),
                  ),
                  if (isActive && status == currentStatus)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: status.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Current',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: status.color,
                        ),
                      ),
                    ),
                ],
              ),
              if (!isLast)
                Container(
                  margin: const EdgeInsets.only(left: 15),
                  width: 2,
                  height: 24,
                  color: isActive
                      ? status.color.withOpacity(0.3)
                      : (isDark ? AppColors.darkBorder : AppColors.border),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
