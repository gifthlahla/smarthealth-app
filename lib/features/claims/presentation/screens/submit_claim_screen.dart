import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:smarthealth/core/constants/app_colors.dart';
import 'package:smarthealth/core/constants/app_strings.dart';
import 'package:smarthealth/core/utils/validators.dart';
import 'package:smarthealth/features/auth/presentation/providers/auth_provider.dart';
import 'package:smarthealth/features/claims/domain/claim_model.dart';
import 'package:smarthealth/features/claims/presentation/providers/claims_provider.dart';

class SubmitClaimScreen extends ConsumerStatefulWidget {
  const SubmitClaimScreen({super.key});

  @override
  ConsumerState<SubmitClaimScreen> createState() => _SubmitClaimScreenState();
}

class _SubmitClaimScreenState extends ConsumerState<SubmitClaimScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  ClaimType _selectedClaimType = ClaimType.gpVisit;
  DateTime _selectedDate = DateTime.now();
  final List<File> _selectedDocuments = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() => _selectedDocuments.add(File(image.path)));
    }
  }

  Future<void> _pickCamera() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() => _selectedDocuments.add(File(image.path)));
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        _selectedDocuments.addAll(
          result.files
              .where((f) => f.path != null)
              .map((f) => File(f.path!)),
        );
      });
    }
  }

  void _showDocumentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Add Document',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              _buildOptionTile(
                icon: Icons.photo_library_rounded,
                label: 'Choose from Gallery',
                color: AppColors.underReview,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              _buildOptionTile(
                icon: Icons.camera_alt_rounded,
                label: 'Take a Photo',
                color: AppColors.approved,
                onTap: () {
                  Navigator.pop(context);
                  _pickCamera();
                },
              ),
              _buildOptionTile(
                icon: Icons.file_present_rounded,
                label: 'Browse Files (PDF)',
                color: AppColors.rejected,
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = ref.read(authControllerProvider).value?.id;
    if (userId == null) return;

    setState(() => _isSubmitting = true);

    try {
      final claim = await ref.read(claimsControllerProvider.notifier).submitClaim(
            userId: userId,
            claimType: _selectedClaimType,
            amount: double.parse(_amountController.text),
            serviceDate: _selectedDate,
            description: _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
            documents: _selectedDocuments.isNotEmpty ? _selectedDocuments : null,
          );

      if (claim != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.claimSubmitted),
            backgroundColor: AppColors.approved,
          ),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit claim. Please try again.'),
            backgroundColor: AppColors.rejected,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.rejected,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.submitClaim),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Claim Type Selection
              Text(
                AppStrings.claimType,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ClaimType.values.map((type) {
                  final isSelected = _selectedClaimType == type;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedClaimType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.1)
                            : (isDark ? AppColors.darkSurface : AppColors.surface),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkBorder : AppColors.border),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            type.icon,
                            size: 18,
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            type.displayName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: AppStrings.amount,
                  prefixIcon: Icon(Icons.attach_money_rounded),
                  prefixText: '\$ ',
                ),
                validator: Validators.amount,
              ),
              const SizedBox(height: 16),

              // Service Date
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: AppStrings.serviceDate,
                      prefixIcon: const Icon(Icons.calendar_today_rounded),
                      hintText: DateFormat('MMM dd, yyyy').format(_selectedDate),
                    ),
                    controller: TextEditingController(
                      text: DateFormat('MMM dd, yyyy').format(_selectedDate),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: '${AppStrings.description} (Optional)',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(Icons.description_outlined),
                  ),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // Documents section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.documents,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton.icon(
                    onPressed: _showDocumentOptions,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_selectedDocuments.isEmpty)
                GestureDetector(
                  onTap: _showDocumentOptions,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceVariant.withOpacity(0.5)
                          : AppColors.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 36,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to upload receipts or reports',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'JPG, PNG, PDF • Max 10MB',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: _selectedDocuments.asMap().entries.map((entry) {
                    final index = entry.key;
                    final file = entry.value;
                    final fileName = file.path.split(Platform.pathSeparator).last;
                    final isImage = ['jpg', 'jpeg', 'png', 'gif']
                        .contains(fileName.split('.').last.toLowerCase());

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
                              color: (isImage
                                      ? AppColors.underReview
                                      : AppColors.rejected)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: isImage
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      file,
                                      fit: BoxFit.cover,
                                      width: 44,
                                      height: 44,
                                    ),
                                  )
                                : Icon(
                                    Icons.picture_as_pdf_rounded,
                                    color: AppColors.rejected,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              fileName,
                              style: Theme.of(context).textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: AppColors.rejected,
                            ),
                            onPressed: () {
                              setState(() => _selectedDocuments.removeAt(index));
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(AppStrings.submitting),
                          ],
                        )
                      : const Text(AppStrings.submitClaim),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
