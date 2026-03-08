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

class ShopperKycScreen extends StatefulWidget {
  final bool isRejected;

  const ShopperKycScreen({super.key, this.isRejected = false});

  @override
  State<ShopperKycScreen> createState() => _ShopperKycScreenState();
}

class _ShopperKycScreenState extends State<ShopperKycScreen> {
  int _currentStep = 0;
  final _identityFormKey = GlobalKey<FormState>();
  final _paymentFormKey = GlobalKey<FormState>();
  final _contactFormKey = GlobalKey<FormState>();

  // Step 1: Identity
  final _idNumberController = TextEditingController();
  File? _idPhotoFile;
  File? _selfiePhotoFile;
  XFile? _idPhotoXFile;
  XFile? _selfiePhotoXFile;
  String _selectedIdType = 'National ID';
  final _idTypes = ['National ID', 'Passport', "Driver's License"];

  // Step 2: Payment
  String _selectedPaymentMethod = 'Mobile Money';
  String _selectedMomoProvider = 'MTN Mobile Money';
  final _momoNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountNameController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();

  // Step 3: Contact
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _idNumberController.dispose();
    _momoNumberController.dispose();
    _bankNameController.dispose();
    _bankAccountNameController.dispose();
    _bankAccountNumberController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
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

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_identityFormKey.currentState!.validate()) return;
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
    } else if (_currentStep == 1) {
      if (!_paymentFormKey.currentState!.validate()) return;
    }
    setState(() => _currentStep++);
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitKyc() async {
    if (!_contactFormKey.currentState!.validate()) return;

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

      // Submit KYC with payment & contact info
      final success = await StrapiService.submitShopperKycFull(
        idNumber: _idNumberController.text,
        idPhotoUrl: idPhotoUrl,
        facePhotoUrl: selfiePhotoUrl,
        mobileMoneyProvider:
            _selectedPaymentMethod == 'Mobile Money' ? _selectedMomoProvider : null,
        mobileMoneyNumber:
            _selectedPaymentMethod == 'Mobile Money' ? _momoNumberController.text : null,
        bankName:
            _selectedPaymentMethod == 'Bank Account' ? _bankNameController.text : null,
        bankAccountName: _selectedPaymentMethod == 'Bank Account'
            ? _bankAccountNameController.text
            : null,
        bankAccountNumber: _selectedPaymentMethod == 'Bank Account'
            ? _bankAccountNumberController.text
            : null,
        emergencyContactName: _emergencyNameController.text.isNotEmpty
            ? _emergencyNameController.text
            : null,
        emergencyContactPhone: _emergencyPhoneController.text.isNotEmpty
            ? _emergencyPhoneController.text
            : null,
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
              // App bar
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
                        if (_currentStep > 0) {
                          _previousStep();
                        } else if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/shopper/home');
                        }
                      },
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      _currentStep == 0
                          ? 'Identity Verification'
                          : _currentStep == 1
                              ? 'Payment Details'
                              : 'Contact Information',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: AppSizes.sm),

                      // Step indicator
                      _StepIndicator(currentStep: _currentStep),
                      const SizedBox(height: AppSizes.lg),

                      // Rejection banner
                      if (widget.isRejected && _currentStep == 0) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSizes.md),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            border: Border.all(color: Colors.red.shade200),
                            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          child: Row(
                            children: [
                              Icon(Iconsax.warning_2,
                                  color: Colors.red.shade600, size: 20),
                              const SizedBox(width: AppSizes.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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

                      // Step content
                      if (_currentStep == 0)
                        _buildIdentityStep(userName)
                      else if (_currentStep == 1)
                        _buildPaymentStep()
                      else
                        _buildContactStep(),

                      const SizedBox(height: AppSizes.lg),

                      // Navigation buttons
                      if (_currentStep < 2) ...[
                        CustomButton(
                          text: 'Continue',
                          onPressed: _nextStep,
                        ),
                      ] else ...[
                        // Review info box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSizes.md),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                            border: Border.all(color: const Color(0xFFFFE082)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Iconsax.clock,
                                  color: Color(0xFFF9A825), size: 20),
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
                        CustomButton(
                          text: 'Submit Verification',
                          isLoading: _isLoading,
                          onPressed: _submitKyc,
                        ),
                      ],
                      const SizedBox(height: AppSizes.xl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──── Step 1: Identity ────

  Widget _buildIdentityStep(String userName) {
    final hasIdPhoto = _idPhotoFile != null || _idPhotoXFile != null;
    final hasSelfie = _selfiePhotoFile != null || _selfiePhotoXFile != null;

    return Form(
      key: _identityFormKey,
      child: Column(
        children: [
          // Security note
          _buildInfoBox(
            icon: Iconsax.shield_tick,
            text: 'Your information is encrypted and stored securely. We only use it for verification.',
            color: AppColors.primary,
            bgColor: AppColors.primary.withValues(alpha: 0.06),
            borderColor: AppColors.primary.withValues(alpha: 0.15),
          ),
          const SizedBox(height: AppSizes.lg),

          // Form card
          _buildFormCard(
            children: [
              // Full Name (read-only)
              _buildFieldLabel('Full Name'),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                initialValue: userName,
                readOnly: true,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: const Icon(Iconsax.user,
                      color: AppColors.primary, size: 20),
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Document type selector
              _buildFieldLabel('Document Type'),
              const SizedBox(height: AppSizes.sm),
              Row(
                children: _idTypes.map((type) {
                  final isSelected = _selectedIdType == type;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: type != _idTypes.last ? 8.0 : 0.0,
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedIdType = type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
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
                                BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          child: Text(
                            type,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelSmall.copyWith(
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
              _buildFieldLabel('$_selectedIdType Number'),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _idNumberController,
                keyboardType: TextInputType.text,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                ],
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Enter your $_selectedIdType number',
                  helperText:
                      'Enter the number exactly as shown on your document',
                  helperStyle: AppTextStyles.caption,
                  prefixIcon: const Icon(Iconsax.card,
                      color: AppColors.primary, size: 20),
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
              _buildFieldLabel('ID Document Photo'),
              const SizedBox(height: 4),
              Text(
                'Upload a clear photo of the front of your ${_selectedIdType.toLowerCase()}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              _buildImageUploadBox(
                hasImage: hasIdPhoto,
                xFile: _idPhotoXFile,
                file: _idPhotoFile,
                onTap: () => _pickImage(true),
                icon: Iconsax.gallery_add,
                label: 'Tap to upload ID photo',
                sublabel: 'JPG, PNG (max 5MB)',
              ),
              const SizedBox(height: AppSizes.lg),

              // Selfie Photo
              _buildFieldLabel('Selfie (Face Photo)'),
              const SizedBox(height: 4),
              Text(
                'Take a selfie in good lighting, facing the camera directly',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              _buildImageUploadBox(
                hasImage: hasSelfie,
                xFile: _selfiePhotoXFile,
                file: _selfiePhotoFile,
                onTap: () => _pickImage(false),
                icon: Iconsax.camera,
                label: 'Tap to take a selfie',
                sublabel: 'Camera will open automatically',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──── Step 2: Payment ────

  Widget _buildPaymentStep() {
    return Form(
      key: _paymentFormKey,
      child: Column(
        children: [
          _buildInfoBox(
            icon: Iconsax.wallet_2,
            text: 'Add your payment details so you can receive earnings from completed orders.',
            color: AppColors.primary,
            bgColor: AppColors.primary.withValues(alpha: 0.06),
            borderColor: AppColors.primary.withValues(alpha: 0.15),
          ),
          const SizedBox(height: AppSizes.lg),

          _buildFormCard(
            children: [
              // Payment method toggle
              _buildFieldLabel('Payment Method'),
              const SizedBox(height: AppSizes.sm),
              Row(
                children: ['Mobile Money', 'Bank Account'].map((method) {
                  final isSelected = _selectedPaymentMethod == method;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: method == 'Mobile Money' ? 8.0 : 0.0,
                      ),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedPaymentMethod = method),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                                BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                method == 'Mobile Money'
                                    ? Iconsax.mobile
                                    : Iconsax.bank,
                                size: 18,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                method,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSizes.lg),

              if (_selectedPaymentMethod == 'Mobile Money') ...[
                // Provider selector
                _buildFieldLabel('Provider'),
                const SizedBox(height: AppSizes.sm),
                Row(
                  children:
                      ['MTN Mobile Money', 'Airtel Money'].map((provider) {
                    final isSelected = _selectedMomoProvider == provider;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: provider == 'MTN Mobile Money' ? 8.0 : 0.0,
                        ),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedMomoProvider = provider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (provider == 'MTN Mobile Money'
                                      ? const Color(0xFFFFF8E1)
                                      : const Color(0xFFFFEBEE))
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? (provider == 'MTN Mobile Money'
                                        ? const Color(0xFFFFCA28)
                                        : const Color(0xFFE53935))
                                    : AppColors.grey300,
                                width: 1.5,
                              ),
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusSm),
                            ),
                            child: Text(
                              provider == 'MTN Mobile Money'
                                  ? 'MTN MoMo'
                                  : 'Airtel Money',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.labelSmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? (provider == 'MTN Mobile Money'
                                        ? const Color(0xFFF9A825)
                                        : const Color(0xFFE53935))
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSizes.lg),

                // Mobile Money Number
                _buildFieldLabel('Mobile Money Number'),
                const SizedBox(height: AppSizes.sm),
                TextFormField(
                  controller: _momoNumberController,
                  keyboardType: TextInputType.phone,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: '0770 000 000',
                    prefixIcon: const Icon(Iconsax.call,
                        color: AppColors.primary, size: 20),
                    prefixText: '+256 ',
                    prefixStyle: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your mobile money number';
                    }
                    if (value.length < 9) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
              ] else ...[
                // Bank Name
                _buildFieldLabel('Bank Name'),
                const SizedBox(height: AppSizes.sm),
                TextFormField(
                  controller: _bankNameController,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Stanbic Bank',
                    prefixIcon:
                        Icon(Iconsax.bank, color: AppColors.primary, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your bank name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.lg),

                // Account Name
                _buildFieldLabel('Account Holder Name'),
                const SizedBox(height: AppSizes.sm),
                TextFormField(
                  controller: _bankAccountNameController,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'Name on the account',
                    prefixIcon:
                        Icon(Iconsax.user, color: AppColors.primary, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the account holder name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.lg),

                // Account Number
                _buildFieldLabel('Account Number'),
                const SizedBox(height: AppSizes.sm),
                TextFormField(
                  controller: _bankAccountNumberController,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'Enter account number',
                    prefixIcon:
                        Icon(Iconsax.card, color: AppColors.primary, size: 20),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your account number';
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ──── Step 3: Contact ────

  Widget _buildContactStep() {
    return Form(
      key: _contactFormKey,
      child: Column(
        children: [
          _buildInfoBox(
            icon: Iconsax.call,
            text: 'Add an emergency contact. This person will be contacted only in case of an emergency during deliveries.',
            color: AppColors.primary,
            bgColor: AppColors.primary.withValues(alpha: 0.06),
            borderColor: AppColors.primary.withValues(alpha: 0.15),
          ),
          const SizedBox(height: AppSizes.lg),

          _buildFormCard(
            children: [
              _buildFieldLabel('Emergency Contact Name'),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _emergencyNameController,
                style: AppTextStyles.bodyLarge,
                decoration: const InputDecoration(
                  hintText: 'Full name of your emergency contact',
                  prefixIcon:
                      Icon(Iconsax.user, color: AppColors.primary, size: 20),
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              _buildFieldLabel('Emergency Contact Phone'),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _emergencyPhoneController,
                keyboardType: TextInputType.phone,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  hintText: '0770 000 000',
                  prefixIcon: const Icon(Iconsax.call,
                      color: AppColors.primary, size: 20),
                  prefixText: '+256 ',
                  prefixStyle: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──── Shared Widgets ────

  Widget _buildFieldLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required String text,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildImageUploadBox({
    required bool hasImage,
    required XFile? xFile,
    required File? file,
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required String sublabel,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          border: Border.all(
            color: hasImage ? AppColors.primary : AppColors.grey300,
            width: hasImage ? 2 : 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          color: hasImage
              ? AppColors.primary.withValues(alpha: 0.04)
              : Colors.grey.shade50,
        ),
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  _buildImagePreview(xFile, file),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusXs),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Iconsax.refresh,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Change',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 28, color: AppColors.primary),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sublabel,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textLight,
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
    final steps = ['Identity', 'Payment', 'Contact'];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
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
                color: isCompleted || isCurrent
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
