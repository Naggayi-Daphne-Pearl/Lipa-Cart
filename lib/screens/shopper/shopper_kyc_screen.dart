import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'dart:convert';
import 'dart:io';

import '../../providers/auth_provider.dart';
import '../../services/strapi_service.dart';
import '../../services/upload_service.dart';
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
  File? _idBackPhotoFile;
  File? _selfiePhotoFile;
  XFile? _idPhotoXFile;
  XFile? _idBackPhotoXFile;
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
  String? _loadingMessage;
  bool _isHydrating = true;
  String? _kycStatus;
  String? _existingIdFrontUrl;
  String? _existingIdBackUrl;
  String? _existingSelfieUrl;

  bool get _isKycApproved => _kycStatus == 'approved';

  String _draftStorageKey() {
    final user = context.read<AuthProvider>().user;
    final id = user?.id ?? user?.documentId ?? 'anonymous';
    return 'shopper_kyc_draft_$id';
  }

  Map<String, dynamic> _currentDraft() {
    return {
      'current_step': _currentStep,
      'id_number': _idNumberController.text,
      'id_type': _selectedIdType,
      'payment_method': _selectedPaymentMethod,
      'momo_provider': _selectedMomoProvider,
      'momo_number': _momoNumberController.text,
      'bank_name': _bankNameController.text,
      'bank_account_name': _bankAccountNameController.text,
      'bank_account_number': _bankAccountNumberController.text,
      'emergency_contact_name': _emergencyNameController.text,
      'emergency_contact_phone': _emergencyPhoneController.text,
      'id_front_url': _existingIdFrontUrl,
      'id_back_url': _existingIdBackUrl,
      'selfie_url': _existingSelfieUrl,
      'saved_at': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _persistDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftStorageKey(), jsonEncode(_currentDraft()));
  }

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftStorageKey());
    if (raw == null || raw.isEmpty) return;

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return;

    setState(() {
      _currentStep = (decoded['current_step'] as num?)?.toInt() ?? _currentStep;
      _idNumberController.text = (decoded['id_number'] ?? '').toString();
      final idType = (decoded['id_type'] ?? '').toString();
      if (_idTypes.contains(idType)) _selectedIdType = idType;
      _selectedPaymentMethod =
          (decoded['payment_method'] ?? _selectedPaymentMethod).toString();
      _selectedMomoProvider =
          (decoded['momo_provider'] ?? _selectedMomoProvider).toString();
      _momoNumberController.text = (decoded['momo_number'] ?? '').toString();
      _bankNameController.text = (decoded['bank_name'] ?? '').toString();
      _bankAccountNameController.text =
          (decoded['bank_account_name'] ?? '').toString();
      _bankAccountNumberController.text =
          (decoded['bank_account_number'] ?? '').toString();
      _emergencyNameController.text =
          (decoded['emergency_contact_name'] ?? '').toString();
      _emergencyPhoneController.text =
          (decoded['emergency_contact_phone'] ?? '').toString();
      _existingIdFrontUrl = (decoded['id_front_url'] as String?) ?? _existingIdFrontUrl;
      _existingIdBackUrl = (decoded['id_back_url'] as String?) ?? _existingIdBackUrl;
      _existingSelfieUrl = (decoded['selfie_url'] as String?) ?? _existingSelfieUrl;
    });
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftStorageKey());
  }

  String? _pickProfileUrl(Map<String, dynamic> profile, List<String> keys) {
    for (final key in keys) {
      final value = profile[key];
      if (value is String && value.trim().startsWith('http')) return value.trim();
      if (value is Map<String, dynamic>) {
        final direct = value['url'];
        if (direct is String && direct.startsWith('http')) return direct;
        final attrs = value['attributes'];
        if (attrs is Map<String, dynamic>) {
          final nested = attrs['url'];
          if (nested is String && nested.startsWith('http')) return nested;
        }
      }
    }
    return null;
  }

  Future<void> _hydrateExistingKyc() async {
    try {
      await _restoreDraft();

      final auth = context.read<AuthProvider>();
      final token = auth.token;
      final user = auth.user;
      if (token == null || user == null) {
        if (mounted) setState(() => _isHydrating = false);
        return;
      }

      final profile = await StrapiService.getMyShopperKycData(
        token: token,
        shopperId: user.shopperId,
        userId: user.id,
        userDocumentId: user.documentId,
        phone: user.phoneNumber,
        email: user.email,
      );

      if (!mounted) return;

      if (profile != null && profile.isNotEmpty) {
        final status =
            (profile['kyc_status'] ?? profile['kycStatus'] ?? user.kycStatus)
                ?.toString();
        final shouldHydrate = status == 'pending_review' ||
            status == 'more_info_requested' ||
            status == 'rejected' ||
            status == 'approved';

        if (shouldHydrate) {
          setState(() {
            _kycStatus = status;
            final idNumber = (profile['id_number'] ?? '').toString();
            if (idNumber.isNotEmpty) _idNumberController.text = idNumber;

            final idType = (profile['id_type'] ?? '').toString();
            if (_idTypes.contains(idType)) _selectedIdType = idType;

            final momoNumber =
                (profile['mobile_money_number'] ?? '').toString();
            if (momoNumber.isNotEmpty) _momoNumberController.text = momoNumber;

            final bankName = (profile['bank_name'] ?? '').toString();
            if (bankName.isNotEmpty) _bankNameController.text = bankName;

            final bankAccountName =
                (profile['bank_account_name'] ?? '').toString();
            if (bankAccountName.isNotEmpty) {
              _bankAccountNameController.text = bankAccountName;
            }

            final bankAccountNumber =
                (profile['bank_account_number'] ?? '').toString();
            if (bankAccountNumber.isNotEmpty) {
              _bankAccountNumberController.text = bankAccountNumber;
            }

            final emergencyName =
                (profile['emergency_contact_name'] ?? '').toString();
            if (emergencyName.isNotEmpty) {
              _emergencyNameController.text = emergencyName;
            }

            final emergencyPhone =
                (profile['emergency_contact_phone'] ?? '').toString();
            if (emergencyPhone.isNotEmpty) {
              _emergencyPhoneController.text = emergencyPhone;
            }

            final momoProvider =
                (profile['mobile_money_provider'] ?? '').toString();
            if (momoProvider.isNotEmpty) {
              _selectedPaymentMethod = 'Mobile Money';
              _selectedMomoProvider = momoProvider;
            } else if (_bankNameController.text.isNotEmpty ||
                _bankAccountNumberController.text.isNotEmpty) {
              _selectedPaymentMethod = 'Bank Account';
            }

            _existingIdFrontUrl = _pickProfileUrl(profile, [
              'idFrontUrl',
              'id_front_url',
              'id_photo_url',
              'id_photo',
            ]);
            _existingIdBackUrl = _pickProfileUrl(profile, [
              'idBackUrl',
              'id_back_url',
              'id_back_photo_url',
            ]);
            _existingSelfieUrl = _pickProfileUrl(profile, [
              'selfieUrl',
              'selfie_url',
              'face_photo_url',
              'face_photo',
            ]);
          });
        }
      } else {
        setState(() {
          _kycStatus = user.kycStatus;
        });
      }

      await _persistDraft();
    } finally {
      if (mounted) setState(() => _isHydrating = false);
    }
  }

  void _attachDraftListeners() {
    _idNumberController.addListener(_persistDraft);
    _momoNumberController.addListener(_persistDraft);
    _bankNameController.addListener(_persistDraft);
    _bankAccountNameController.addListener(_persistDraft);
    _bankAccountNumberController.addListener(_persistDraft);
    _emergencyNameController.addListener(_persistDraft);
    _emergencyPhoneController.addListener(_persistDraft);
  }

  @override
  void initState() {
    super.initState();
    _attachDraftListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrateExistingKyc();
    });
  }

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

  Future<void> _pickImage(String type) async {
    if (_isKycApproved) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: type == 'selfie' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          if (type == 'idFront') {
            _idPhotoXFile = pickedFile;
            if (!kIsWeb) _idPhotoFile = File(pickedFile.path);
            _existingIdFrontUrl = null;
          } else if (type == 'selfie') {
            _selfiePhotoXFile = pickedFile;
            if (!kIsWeb) _selfiePhotoFile = File(pickedFile.path);
            _existingSelfieUrl = null;
          } else {
            _idBackPhotoXFile = pickedFile;
            if (!kIsWeb) _idBackPhotoFile = File(pickedFile.path);
            _existingIdBackUrl = null;
          }
        });
        await _persistDraft();
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
    if (_isKycApproved) return;

    if (_currentStep == 0) {
      if (!_identityFormKey.currentState!.validate()) return;
      final hasIdPhoto =
        (kIsWeb ? _idPhotoXFile != null : _idPhotoFile != null) ||
        (_existingIdFrontUrl?.isNotEmpty == true);
      final hasIdBack =
        (kIsWeb ? _idBackPhotoXFile != null : _idBackPhotoFile != null) ||
        (_existingIdBackUrl?.isNotEmpty == true);
      final hasSelfie =
        (kIsWeb ? _selfiePhotoXFile != null : _selfiePhotoFile != null) ||
        (_existingSelfieUrl?.isNotEmpty == true);
      if (!hasIdPhoto || !hasIdBack || !hasSelfie) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !hasIdPhoto && !hasIdBack && !hasSelfie
                  ? 'Please upload ID front, ID back, and selfie'
                  : !hasIdPhoto
                  ? 'Please upload your ID document photo'
                  : !hasIdBack
                  ? 'Please upload the back of your ID document'
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
    _persistDraft();
  }

  void _previousStep() {
    if (_isKycApproved) return;
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _persistDraft();
    }
  }

  Future<void> _submitKyc() async {
    if (_isKycApproved) return;
    if (!_contactFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Uploading ID photo...';
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Not authenticated. Please log in again.');
      }

      // Keep existing URLs when shopper does not replace a document.
      String? idPhotoUrl = _existingIdFrontUrl;
      String? idBackPhotoUrl = _existingIdBackUrl;
      String? selfiePhotoUrl = _existingSelfieUrl;

      if (kIsWeb) {
        if (_idPhotoXFile != null) {
          final idBytes = await _idPhotoXFile!.readAsBytes();
          idPhotoUrl = await UploadService.uploadImageBytes(
            idBytes,
            _idPhotoXFile!.name,
            token,
          );
        }

        if (mounted) {
          setState(() {
            _loadingMessage = 'Uploading ID back photo...';
          });
        }
        if (_idBackPhotoXFile != null) {
          final idBackBytes = await _idBackPhotoXFile!.readAsBytes();
          idBackPhotoUrl = await UploadService.uploadImageBytes(
            idBackBytes,
            _idBackPhotoXFile!.name,
            token,
          );
        }

        if (mounted) {
          setState(() {
            _loadingMessage = 'Uploading selfie...';
          });
        }
        if (_selfiePhotoXFile != null) {
          final selfieBytes = await _selfiePhotoXFile!.readAsBytes();
          selfiePhotoUrl = await UploadService.uploadImageBytes(
            selfieBytes,
            _selfiePhotoXFile!.name,
            token,
          );
        }
      } else {
        if (_idPhotoFile != null) {
          idPhotoUrl = await UploadService.uploadImage(_idPhotoFile!, token);
        }
        if (mounted) {
          setState(() {
            _loadingMessage = 'Uploading ID back photo...';
          });
        }
        if (_idBackPhotoFile != null) {
          idBackPhotoUrl = await UploadService.uploadImage(
            _idBackPhotoFile!,
            token,
          );
        }
        if (mounted) {
          setState(() {
            _loadingMessage = 'Uploading selfie...';
          });
        }
        if (_selfiePhotoFile != null) {
          selfiePhotoUrl = await UploadService.uploadImage(
            _selfiePhotoFile!,
            token,
          );
        }
      }

      if (idPhotoUrl == null ||
          idBackPhotoUrl == null ||
          selfiePhotoUrl == null) {
        throw Exception('Failed to upload photos');
      }

      if (mounted)
        setState(() {
          _loadingMessage = 'Submitting verification...';
        });

      // Submit KYC with payment & contact info
      final success = await StrapiService.submitShopperKycFull(
        idNumber: _idNumberController.text,
        idPhotoUrl: idPhotoUrl,
        idBackUrl: idBackPhotoUrl,
        facePhotoUrl: selfiePhotoUrl,
        mobileMoneyProvider: _selectedPaymentMethod == 'Mobile Money'
            ? _selectedMomoProvider
            : null,
        mobileMoneyNumber: _selectedPaymentMethod == 'Mobile Money'
            ? _momoNumberController.text
            : null,
        bankName: _selectedPaymentMethod == 'Bank Account'
            ? _bankNameController.text
            : null,
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
        setState(() {
          _existingIdFrontUrl = idPhotoUrl;
          _existingIdBackUrl = idBackPhotoUrl;
          _existingSelfieUrl = selfiePhotoUrl;
          _kycStatus = 'pending_review';
        });
        await _clearDraft();
        authProvider.updateKycStatus('pending_review');
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
        setState(() {
          _isLoading = false;
          _loadingMessage = null;
        });
      }
    }
  }

  Widget _buildImagePreview(XFile? xFile, File? file) {
    if (kIsWeb && xFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        child: FutureBuilder<Uint8List>(
          future: xFile.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
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
      body: Stack(
        children: [
          Container(
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
                      child: _isHydrating
                          ? const Padding(
                              padding: EdgeInsets.only(top: 48),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: AppSizes.sm),

                          // Step indicator
                          _StepIndicator(currentStep: _currentStep),
                          const SizedBox(height: AppSizes.lg),

                          // Rejection banner
                          if (widget.isRejected && _currentStep == 0) ...[
                            Builder(
                              builder: (context) {
                                final rejectionReason = context
                                    .read<AuthProvider>()
                                    .user
                                    ?.kycRejectionReason;
                                return Container(
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
                                              style: AppTextStyles.labelLarge
                                                  .copyWith(
                                                    color: Colors.red.shade700,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              rejectionReason ??
                                                  'Please review your documents and try again.',
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                    color: Colors.red.shade600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: AppSizes.lg),
                          ],

                          if (_isKycApproved) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSizes.md),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Iconsax.lock, color: AppColors.primary),
                                  const SizedBox(width: AppSizes.sm),
                                  Expanded(
                                    child: Text(
                                      'KYC is approved. Editing is disabled.',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSizes.lg),
                          ],

                          // Step content
                          AbsorbPointer(
                            absorbing: _isKycApproved,
                            child: _currentStep == 0
                                ? _buildIdentityStep(userName)
                                : _currentStep == 1
                                ? _buildPaymentStep()
                                : _buildContactStep(),
                          ),

                          const SizedBox(height: AppSizes.lg),

                          // Navigation buttons
                          if (_currentStep < 2) ...[
                            CustomButton(
                              text: 'Continue',
                              onPressed: _isKycApproved ? null : _nextStep,
                            ),
                          ] else ...[
                            // Review info box
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
                            CustomButton(
                              text: _isKycApproved
                                  ? 'Already Approved'
                                  : 'Submit Verification',
                              isLoading: _isLoading,
                              onPressed: _isKycApproved ? null : _submitKyc,
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
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          _loadingMessage ?? 'Processing...',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ──── Step 1: Identity ────

  Widget _buildIdentityStep(String userName) {
    final hasIdPhoto =
      _idPhotoFile != null || _idPhotoXFile != null || _existingIdFrontUrl != null;
    final hasIdBack =
      _idBackPhotoFile != null || _idBackPhotoXFile != null || _existingIdBackUrl != null;
    final hasSelfie =
      _selfiePhotoFile != null || _selfiePhotoXFile != null || _existingSelfieUrl != null;

    return Form(
      key: _identityFormKey,
      child: Column(
        children: [
          // Security note
          _buildInfoBox(
            icon: Iconsax.shield_tick,
            text:
                'Your information is encrypted and stored securely. We only use it for verification.',
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
                  prefixIcon: const Icon(
                    Iconsax.user,
                    color: AppColors.primary,
                    size: 20,
                  ),
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
                        onTap: () {
                          setState(() => _selectedIdType = type);
                          _persistDraft();
                        },
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
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusSm,
                            ),
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
                existingUrl: _existingIdFrontUrl,
                onTap: () => _pickImage('idFront'),
                icon: Iconsax.gallery_add,
                label: hasIdPhoto || _existingIdFrontUrl != null
                    ? 'Replace ID photo'
                    : 'Tap to upload ID photo',
                sublabel: 'JPG, PNG (max 5MB)',
              ),
              const SizedBox(height: AppSizes.lg),

              // ID Back Photo
              _buildFieldLabel('ID Back Photo'),
              const SizedBox(height: 4),
              Text(
                'Upload a clear photo of the back of your ${_selectedIdType.toLowerCase()}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              _buildImageUploadBox(
                hasImage: hasIdBack,
                xFile: _idBackPhotoXFile,
                file: _idBackPhotoFile,
                existingUrl: _existingIdBackUrl,
                onTap: () => _pickImage('idBack'),
                icon: Iconsax.gallery_add,
                label: hasIdBack || _existingIdBackUrl != null
                    ? 'Replace ID back photo'
                    : 'Tap to upload ID back photo',
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
                existingUrl: _existingSelfieUrl,
                onTap: () => _pickImage('selfie'),
                icon: Iconsax.camera,
                label: hasSelfie || _existingSelfieUrl != null
                    ? 'Replace selfie'
                    : 'Tap to take a selfie',
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
            text:
                'Add your payment details so you can receive earnings from completed orders.',
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
                        onTap: () {
                          setState(() {
                            _selectedPaymentMethod = method;
                            if (method == 'Mobile Money') {
                              _bankNameController.clear();
                              _bankAccountNameController.clear();
                              _bankAccountNumberController.clear();
                            } else {
                              _momoNumberController.clear();
                            }
                          });
                          _persistDraft();
                        },
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
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusSm,
                            ),
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
                  children: ['MTN Mobile Money', 'Airtel Money'].map((
                    provider,
                  ) {
                    final isSelected = _selectedMomoProvider == provider;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: provider == 'MTN Mobile Money' ? 8.0 : 0.0,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedMomoProvider = provider);
                            _persistDraft();
                          },
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
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusSm,
                              ),
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
                    prefixIcon: const Icon(
                      Iconsax.call,
                      color: AppColors.primary,
                      size: 20,
                    ),
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
                    prefixIcon: Icon(
                      Iconsax.bank,
                      color: AppColors.primary,
                      size: 20,
                    ),
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
                    prefixIcon: Icon(
                      Iconsax.user,
                      color: AppColors.primary,
                      size: 20,
                    ),
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
                    prefixIcon: Icon(
                      Iconsax.card,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
            text:
                'Add an emergency contact. This person will be contacted only in case of an emergency during deliveries.',
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
                  prefixIcon: Icon(
                    Iconsax.user,
                    color: AppColors.primary,
                    size: 20,
                  ),
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
                  prefixIcon: const Icon(
                    Iconsax.call,
                    color: AppColors.primary,
                    size: 20,
                  ),
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
        style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
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
    required String? existingUrl,
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required String sublabel,
  }) {
    final hasExistingRemote = existingUrl != null && existingUrl.isNotEmpty;
    final shouldShowImage = hasImage || hasExistingRemote;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          border: Border.all(
            color: shouldShowImage ? AppColors.primary : AppColors.grey300,
            width: shouldShowImage ? 2 : 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          color: shouldShowImage
              ? AppColors.primary.withValues(alpha: 0.04)
              : Colors.grey.shade50,
        ),
        child: shouldShowImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    _buildImagePreview(xFile, file)
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      child: Image.network(
                        existingUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade100,
                          alignment: Alignment.center,
                          child: Text(
                            'Preview unavailable',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(AppSizes.radiusXs),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Iconsax.refresh,
                            color: Colors.white,
                            size: 14,
                          ),
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
