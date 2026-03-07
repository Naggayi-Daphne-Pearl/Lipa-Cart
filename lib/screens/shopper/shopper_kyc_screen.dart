import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';

import '../../providers/auth_provider.dart';
import '../../services/strapi_service.dart';
import '../../services/imgbb_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/app_loading_indicator.dart';

class ShopperKycScreen extends StatefulWidget {
  final bool isRejected;

  const ShopperKycScreen({super.key, this.isRejected = false});

  @override
  State<ShopperKycScreen> createState() => _ShopperKycScreenState();
}

class _ShopperKycScreenState extends State<ShopperKycScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idNumberController = TextEditingController();
  File? _idPhotoFile;
  File? _selfiePhotoFile;
  XFile? _idPhotoXFile;
  XFile? _selfiePhotoXFile;
  bool _isLoading = false;
  String _selectedIdType = 'National ID';

  final _idTypes = ['National ID', 'Passport', "Driver's License"];

  @override
  void dispose() {
    _idNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isIdPhoto) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: isIdPhoto ? ImageSource.gallery : ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          if (isIdPhoto) {
            _idPhotoXFile = pickedFile;
            if (!kIsWeb) _idPhotoFile = File(pickedFile.path);
          } else {
            _selfiePhotoXFile = pickedFile;
            if (!kIsWeb) _selfiePhotoFile = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _submitKyc() async {
    if (!_formKey.currentState!.validate()) return;

    final hasIdPhoto = kIsWeb ? _idPhotoXFile != null : _idPhotoFile != null;
    final hasSelfie =
        kIsWeb ? _selfiePhotoXFile != null : _selfiePhotoFile != null;

    if (!hasIdPhoto || !hasSelfie) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !hasIdPhoto && !hasSelfie
                ? 'Please upload both ID photo and selfie'
                : !hasIdPhoto
                    ? 'Please upload your ID document photo'
                    : 'Please take a selfie photo',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Not authenticated. Please log in again.');
      }

      // Upload photos to ImgBB
      final String? idPhotoUrl;
      final String? selfiePhotoUrl;
      if (kIsWeb) {
        final idBytes = await _idPhotoXFile!.readAsBytes();
        final selfieBytes = await _selfiePhotoXFile!.readAsBytes();
        idPhotoUrl = await ImgBBService.uploadImageBytes(
          idBytes,
          _idPhotoXFile!.name,
        );
        selfiePhotoUrl = await ImgBBService.uploadImageBytes(
          selfieBytes,
          _selfiePhotoXFile!.name,
        );
      } else {
        idPhotoUrl = await ImgBBService.uploadImage(_idPhotoFile!);
        selfiePhotoUrl = await ImgBBService.uploadImage(_selfiePhotoFile!);
      }

      if (idPhotoUrl == null || selfiePhotoUrl == null) {
        throw Exception('Failed to upload photos');
      }

      // Submit KYC
      final success = await StrapiService.submitShopperKyc(
        idNumber: _idNumberController.text,
        idPhotoUrl: idPhotoUrl,
        facePhotoUrl: selfiePhotoUrl,
        token: token,
      );

      if (success && mounted) {
        context.go('/shopper/pending-approval');
      } else if (mounted) {
        throw Exception('Failed to submit KYC');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildImagePreview(XFile? xFile, File? file) {
    if (kIsWeb && xFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        child: Image.network(
          xFile.path,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else if (file != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        child: Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final userName = authProvider.user?.name ?? 'Shopper';
    final hasIdPhoto = _idPhotoFile != null || _idPhotoXFile != null;
    final hasSelfie = _selfiePhotoFile != null || _selfiePhotoXFile != null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F5E9),
              Color(0xFFF1F8E9),
              Color(0xFFFAFAFA),
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar with back button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: AppSizes.xs,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Iconsax.arrow_left),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        }
                      },
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      'Identity Verification',
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: AppSizes.sm),

                        // Step indicator
                        _StepIndicator(currentStep: widget.isRejected ? 0 : 1),
                        const SizedBox(height: AppSizes.lg),

                        // Rejection banner
                        if (widget.isRejected) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSizes.md),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(
                                color: Colors.red.shade200,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusSm,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Iconsax.warning_2,
                                  color: Colors.red.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSizes.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Application Rejected',
                                        style: AppTextStyles.labelLarge.copyWith(
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Please review your documents and try again.',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: Colors.red.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSizes.lg),
                        ],

                        // Security note
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSizes.md),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusSm,
                            ),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.shield_tick,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: AppSizes.sm),
                              Expanded(
                                child: Text(
                                  'Your information is encrypted and stored securely. We only use it for verification.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.lg),

                        // Form card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSizes.lg),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusLg,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.06,
                                ),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Full Name (read-only)
                              Text(
                                'Full Name',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSizes.sm),
                              TextFormField(
                                initialValue: userName,
                                readOnly: true,
                                style: AppTextStyles.bodyLarge,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  prefixIcon: const Icon(
                                    Iconsax.user,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSizes.lg),

                              // Document type selector
                              Text(
                                'Document Type',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSizes.sm),
                              Row(
                                children: _idTypes.map((type) {
                                  final isSelected = _selectedIdType == type;
                                  return Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right:
                                            type != _idTypes.last ? 8.0 : 0.0,
                                      ),
                                      child: GestureDetector(
                                        onTap: () => setState(
                                          () => _selectedIdType = type,
                                        ),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.primary
                                                : Colors.transparent,
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.grey300,
                                              width: 1.5,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(
                                              AppSizes.radiusSm,
                                            ),
                                          ),
                                          child: Text(
                                            type,
                                            textAlign: TextAlign.center,
                                            style: AppTextStyles.labelSmall
                                                .copyWith(
                                              color: isSelected
                                                  ? Colors.white
                                                  : AppColors.textPrimary,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: AppSizes.lg),

                              // ID Number
                              Text(
                                '$_selectedIdType Number',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSizes.sm),
                              TextFormField(
                                controller: _idNumberController,
                                keyboardType: TextInputType.text,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z0-9]'),
                                  ),
                                ],
                                style: AppTextStyles.bodyLarge,
                                decoration: InputDecoration(
                                  hintText:
                                      'Enter your $_selectedIdType number',
                                  helperText:
                                      'Enter the number exactly as shown on your document',
                                  helperStyle: AppTextStyles.caption,
                                  prefixIcon: const Icon(
                                    Iconsax.card,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your ID number';
                                  }
                                  if (value.length < 5) {
                                    return 'ID number is too short';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSizes.lg),

                              // ID Document Photo
                              Text(
                                'ID Document Photo',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Upload a clear photo of the front of your ${_selectedIdType.toLowerCase()}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSizes.sm),
                              GestureDetector(
                                onTap: () => _pickImage(true),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: double.infinity,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: hasIdPhoto
                                          ? AppColors.primary
                                          : AppColors.grey300,
                                      width: hasIdPhoto ? 2 : 1.5,
                                      strokeAlign:
                                          BorderSide.strokeAlignInside,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusSm,
                                    ),
                                    color: hasIdPhoto
                                        ? AppColors.primary
                                            .withValues(alpha: 0.04)
                                        : Colors.grey.shade50,
                                  ),
                                  child: hasIdPhoto
                                      ? Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            _buildImagePreview(
                                              _idPhotoXFile,
                                              _idPhotoFile,
                                            ),
                                            Positioned(
                                              bottom: 8,
                                              right: 8,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    AppSizes.radiusXs,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Iconsax.refresh,
                                                      color: Colors.white,
                                                      size: 14,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Change',
                                                      style: AppTextStyles
                                                          .caption
                                                          .copyWith(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Iconsax.gallery_add,
                                                  size: 28,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Tap to upload ID photo',
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'JPG, PNG (max 5MB)',
                                                style: AppTextStyles.caption
                                                    .copyWith(
                                                  color: AppColors.textLight,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: AppSizes.lg),

                              // Selfie Photo
                              Text(
                                'Selfie (Face Photo)',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Take a selfie in good lighting, facing the camera directly',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSizes.sm),
                              GestureDetector(
                                onTap: () => _pickImage(false),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: double.infinity,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: hasSelfie
                                          ? AppColors.primary
                                          : AppColors.grey300,
                                      width: hasSelfie ? 2 : 1.5,
                                      strokeAlign:
                                          BorderSide.strokeAlignInside,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusSm,
                                    ),
                                    color: hasSelfie
                                        ? AppColors.primary
                                            .withValues(alpha: 0.04)
                                        : Colors.grey.shade50,
                                  ),
                                  child: hasSelfie
                                      ? Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            _buildImagePreview(
                                              _selfiePhotoXFile,
                                              _selfiePhotoFile,
                                            ),
                                            Positioned(
                                              bottom: 8,
                                              right: 8,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    AppSizes.radiusXs,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Iconsax.refresh,
                                                      color: Colors.white,
                                                      size: 14,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Change',
                                                      style: AppTextStyles
                                                          .caption
                                                          .copyWith(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Iconsax.camera,
                                                  size: 28,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Tap to take a selfie',
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Camera will open automatically',
                                                style: AppTextStyles.caption
                                                    .copyWith(
                                                  color: AppColors.textLight,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.lg),

                        // Review timeline info box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSizes.md),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusSm,
                            ),
                            border: Border.all(
                              color: const Color(0xFFFFE082),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Iconsax.clock,
                                color: Color(0xFFF9A825),
                                size: 20,
                              ),
                              const SizedBox(width: AppSizes.sm),
                              Expanded(
                                child: Text(
                                  'Your documents will be reviewed within 24-48 hours. You\'ll be notified once approved.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: const Color(0xFF795548),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.lg),

                        // Submit button
                        CustomButton(
                          text: 'Submit Verification',
                          isLoading: _isLoading,
                          onPressed: _submitKyc,
                        ),
                        const SizedBox(height: AppSizes.xl),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = ['Sign Up', 'Verify Identity', 'Start Earning'];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepBefore = index ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              color: stepBefore < currentStep
                  ? AppColors.primary
                  : AppColors.grey300,
            ),
          );
        }

        final stepIndex = index ~/ 2;
        final isCompleted = stepIndex < currentStep;
        final isCurrent = stepIndex == currentStep;

        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.primary
                    : isCurrent
                        ? AppColors.primary
                        : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted || isCurrent
                      ? AppColors.primary
                      : AppColors.grey300,
                  width: 2,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text(
                        '${stepIndex + 1}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isCurrent
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              steps[stepIndex],
              style: AppTextStyles.caption.copyWith(
                color: isCompleted || isCurrent
                    ? AppColors.primaryDark
                    : AppColors.textLight,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        );
      }),
    );
  }
}
