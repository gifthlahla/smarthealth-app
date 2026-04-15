import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smarthealth/core/constants/app_colors.dart';
import 'package:smarthealth/core/constants/app_strings.dart';
import 'package:smarthealth/core/widgets/confirmation_dialog.dart';
import 'package:smarthealth/features/auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  final _fullNameController = TextEditingController();
  final _membershipController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _membershipController.dispose();
    super.dispose();
  }

  void _startEditing() {
    final user = ref.read(authControllerProvider).value;
    _fullNameController.text = user?.fullName ?? '';
    _membershipController.text = user?.membershipNumber ?? '';
    setState(() => _isEditing = true);
  }

  Future<void> _saveProfile() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
            userId: user.id,
            fullName: _fullNameController.text.trim(),
            membershipNumber: _membershipController.text.trim(),
          );
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.approved,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.rejected,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: AppStrings.logout,
      message: AppStrings.logoutConfirm,
      confirmLabel: AppStrings.logout,
      confirmColor: AppColors.rejected,
      icon: Icons.logout_rounded,
    );

    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: _startEditing,
              icon: const Icon(Icons.edit_rounded),
              tooltip: AppStrings.editProfile,
            )
          else
            TextButton(
              onPressed: () => setState(() => _isEditing = false),
              child: const Text(AppStrings.cancel),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar
            const SizedBox(height: 8),
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _initials(user?.fullName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppColors.darkBackground : AppColors.background,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!_isEditing) ...[
              Text(
                user?.fullName ?? 'User',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (user?.membershipNumber != null &&
                  user!.membershipNumber!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Member: ${user.membershipNumber}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 32),

            // Editable fields
            if (_isEditing) ...[
              TextFormField(
                controller: _fullNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: AppStrings.fullName,
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _membershipController,
                decoration: const InputDecoration(
                  labelText: AppStrings.membershipNumber,
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(AppStrings.save),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Settings section
            if (!_isEditing) ...[
              _buildSettingsSection(context, isDark, [
                _SettingsTile(
                  icon: Icons.person_outline_rounded,
                  label: AppStrings.editProfile,
                  onTap: _startEditing,
                  isDark: isDark,
                ),
                _SettingsTile(
                  icon: Icons.receipt_long_rounded,
                  label: AppStrings.myClaims,
                  onTap: () => context.go('/claims'),
                  isDark: isDark,
                ),
              ]),
              const SizedBox(height: 16),
              _buildSettingsSection(context, isDark, [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  label: AppStrings.about,
                  subtitle: AppStrings.version,
                  onTap: () {},
                  isDark: isDark,
                ),
              ]),
              const SizedBox(height: 16),
              _buildSettingsSection(context, isDark, [
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  label: AppStrings.logout,
                  isDestructive: true,
                  onTap: _handleLogout,
                  isDark: isDark,
                ),
              ]),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
      BuildContext context, bool isDark, List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        children: tiles
            .asMap()
            .entries
            .map((entry) => Column(
                  children: [
                    entry.value,
                    if (entry.key < tiles.length - 1)
                      Divider(
                        height: 1,
                        indent: 56,
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                  ],
                ))
            .toList(),
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool isDark;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AppColors.rejected
        : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary);
    final iconColor = isDestructive
        ? AppColors.rejected
        : AppColors.primary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      trailing: isDestructive
          ? null
          : Icon(
              Icons.chevron_right_rounded,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textTertiary,
            ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
