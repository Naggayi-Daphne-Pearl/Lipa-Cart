import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import '../../providers/auth_provider.dart';
import '../../services/strapi_service.dart';
import '../../services/upload_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../widgets/rider_button.dart';

class RiderKycScreen extends StatefulWidget {
  final bool isRejected;

  const RiderKycScreen({super.key, this.isRejected = false});

  @override
  State<RiderKycScreen> createState() => _RiderKycScreenState();
}

class _RiderKycScreenState extends State<RiderKycScreen> {
  int _currentStep = 0;
  final _identityFormKey = GlobalKey<FormState>();
  final _vehicleFormKey = GlobalKey<FormState>();
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

  // Step 2: Vehicle
  final _licenseNumberController = TextEditingController();
  final _vehicleMakeController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  String _selectedVehicleType = 'Motorcycle';
  final _vehicleTypes = ['Motorcycle', 'Bicycle', 'Car', 'Van'];
  File? _licensePhotoFile;
  XFile? _licensePhotoXFile;

  // Step 3: Payment
  String _selectedPaymentMethod = 'Mobile Money';
  String _selectedMomoProvider = 'MTN Mobile Money';
  final _momoNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountNameController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();

  // Step 4: Contact
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  bool _isLoading = false;
  String? _loadingMessage;

  static const _draftKey = 'rider_kyc_draft';

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final step = prefs.getInt('${_draftKey}_step');
    if (step != null && mounted) {
      setState(() {
        _currentStep = step;
        _idNumberController.text = prefs.getString('${_draftKey}_idNumber') ?? '';
        _selectedIdType = prefs.getString('${_draftKey}_idType') ?? 'National ID';
        _licenseNumberController.text = prefs.getString('${_draftKey}_license') ?? '';
        _vehicleMakeController.text = prefs.getString('${_draftKey}_make') ?? '';
        _vehiclePlateController.text = prefs.getString('${_draftKey}_plate') ?? '';
        _selectedVehicleType = prefs.getString('${_draftKey}_vehicleType') ?? 'Motorcycle';
        _momoNumberController.text = prefs.getString('${_draftKey}_momo') ?? '';
        _selectedPaymentMethod = prefs.getString('${_draftKey}_payMethod') ?? 'Mobile Money';
        _emergencyNameController.text = prefs.getString('${_draftKey}_emergName') ?? '';
        _emergencyPhoneController.text = prefs.getString('${_draftKey}_emergPhone') ?? '';
      });
    }
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('${_draftKey}_step', _currentStep);
    prefs.setString('${_draftKey}_idNumber', _idNumberController.text);
    prefs.setString('${_draftKey}_idType', _selectedIdType);
    prefs.setString('${_draftKey}_license', _licenseNumberController.text);
    prefs.setString('${_draftKey}_make', _vehicleMakeController.text);
    prefs.setString('${_draftKey}_plate', _vehiclePlateController.text);
    prefs.setString('${_draftKey}_vehicleType', _selectedVehicleType);
    prefs.setString('${_draftKey}_momo', _momoNumberController.text);
    prefs.setString('${_draftKey}_payMethod', _selectedPaymentMethod);
    prefs.setString('${_draftKey}_emergName', _emergencyNameController.text);
    prefs.setString('${_draftKey}_emergPhone', _emergencyPhoneController.text);
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_draftKey));
    for (final k in keys) {
      prefs.remove(k);
    }
  }

  @override
  void dispose() {
    _idNumberController.dispose();
    _licenseNumberController.dispose();
    _vehicleMakeController.dispose();
    _vehiclePlateController.dispose();
    _momoNumberController.dispose();
    _bankNameController.dispose();
    _bankAccountNameController.dispose();
    _bankAccountNumberController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: type == 'selfie' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          switch (type) {
            case 'id':
              _idPhotoXFile = pickedFile;
              if (!kIsWeb) _idPhotoFile = File(pickedFile.path);
              break;
            case 'selfie':
              _selfiePhotoXFile = pickedFile;
              if (!kIsWeb) _selfiePhotoFile = File(pickedFile.path);
              break;
            case 'license':
              _licensePhotoXFile = pickedFile;
              if (!kIsWeb) _licensePhotoFile = File(pickedFile.path);
              break;
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
      if (!_vehicleFormKey.currentState!.validate()) return;
    } else if (_currentStep == 2) {
      if (!_paymentFormKey.currentState!.validate()) return;
    }
    setState(() => _currentStep++);
    _saveDraft();
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitKyc() async {
    if (!_contactFormKey.currentState!.validate()) return;

    setState(() { _isLoading = true; _loadingMessage = 'Uploading ID photo...'; });

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Not authenticated. Please log in again.');
      }

      // Upload photos through Strapi → Cloudinary
      final String? idPhotoUrl;
      final String? selfiePhotoUrl;
      String? licensePhotoUrl;

      if (kIsWeb) {
        final idBytes = await _idPhotoXFile!.readAsBytes();
        idPhotoUrl = await UploadService.uploadImageBytes(
          idBytes,
          _idPhotoXFile!.name,
          token,
        );

        if (mounted) setState(() { _loadingMessage = 'Uploading selfie...'; });
        final selfieBytes = await _selfiePhotoXFile!.readAsBytes();
        selfiePhotoUrl = await UploadService.uploadImageBytes(
          selfieBytes,
          _selfiePhotoXFile!.name,
          token,
        );
        if (_licensePhotoXFile != null) {
          if (mounted) setState(() { _loadingMessage = 'Uploading license photo...'; });
          final licenseBytes = await _licensePhotoXFile!.readAsBytes();
          licensePhotoUrl = await UploadService.uploadImageBytes(
            licenseBytes,
            _licensePhotoXFile!.name,
            token,
          );
        }
      } else {
        idPhotoUrl = await UploadService.uploadImage(_idPhotoFile!, token);
        if (mounted) setState(() { _loadingMessage = 'Uploading selfie...'; });
        selfiePhotoUrl = await UploadService.uploadImage(_selfiePhotoFile!, token);
        if (_licensePhotoFile != null) {
          if (mounted) setState(() { _loadingMessage = 'Uploading license photo...'; });
          licensePhotoUrl = await UploadService.uploadImage(_licensePhotoFile!, token);
        }
      }

      if (idPhotoUrl == null || selfiePhotoUrl == null) {
        throw Exception('Failed to upload photos');
      }

      if (mounted) setState(() { _loadingMessage = 'Submitting verification...'; });

      // Submit KYC
      final success = await StrapiService.submitRiderKycFull(
        idNumber: _idNumberController.text,
        idPhotoUrl: idPhotoUrl,
        facePhotoUrl: selfiePhotoUrl,
        vehicleType: _selectedVehicleType,
        licenseNumber: _licenseNumberController.text,
        vehicleMake: _vehicleMakeController.text.isNotEmpty
            ? _vehicleMakeController.text
            : null,
        vehiclePlate: _vehiclePlateController.text.isNotEmpty
            ? _vehiclePlateController.text
            : null,
        licensePhotoUrl: licensePhotoUrl,
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
        _clearDraft();
        authProvider.updateKycStatus('pending_review');
        context.go('/rider/pending-approval');
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
        setState(() { _isLoading = false; _loadingMessage = null; });
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
    final userName = authProvider.user?.name ?? 'Rider';

    final stepTitles = [
      'Identity Verification',
      'Vehicle Details',
      'Payment Details',
      'Contact Information',
    ];

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
                        }
                      },
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      stepTitles[_currentStep],
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
                      _RiderStepIndicator(currentStep: _currentStep),
                      const SizedBox(height: AppSizes.lg),

                      // Rejection banner
                      if (widget.isRejected && _currentStep == 0) ...[
                        Builder(builder: (context) {
                          final rejectionReason = context.read<AuthProvider>().user?.kycRejectionReason;
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSizes.md),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red.shade200),
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusSm),
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
                                        rejectionReason ?? 'Please review your documents and try again.',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: Colors.red.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: AppSizes.lg),
                      ],

                      // Step content
                      if (_currentStep == 0)
                        _buildIdentityStep(userName)
                      else if (_currentStep == 1)
                        _buildVehicleStep()
                      else if (_currentStep == 2)
                        _buildPaymentStep()
                      else
                        _buildContactStep(),

                      const SizedBox(height: AppSizes.lg),

                      // Navigation buttons
                      if (_currentStep < 3) ...[
                        RiderButton.primary(
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
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusSm),
                            border:
                                Border.all(color: const Color(0xFFFFE082)),
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
                        RiderButton.primary(
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
                        Text(_loadingMessage ?? 'Processing...', style: const TextStyle(fontSize: 16)),
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
    final hasIdPhoto = _idPhotoFile != null || _idPhotoXFile != null;
    final hasSelfie = _selfiePhotoFile != null || _selfiePhotoXFile != null;

    return Form(
      key: _identityFormKey,
      child: Column(
        children: [
          _buildInfoBox(
            icon: Iconsax.shield_tick,
            text:
                'Your information is encrypted and stored securely. We only use it for verification.',
            color: AppColors.primary,
            bgColor: AppColors.primary.withValues(alpha: 0.06),
            borderColor: AppColors.primary.withValues(alpha: 0.15),
          ),
          const SizedBox(height: AppSizes.lg),

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
                onTap: () => _pickImage('id'),
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
                onTap: () => _pickImage('selfie'),
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

  // ──── Step 2: Vehicle ────

  Widget _buildVehicleStep() {
    final hasLicensePhoto =
        _licensePhotoFile != null || _licensePhotoXFile != null;

    return Form(
      key: _vehicleFormKey,
      child: Column(
        children: [
          _buildInfoBox(
            icon: Iconsax.truck,
            text:
                'Provide your vehicle and driving license details for delivery verification.',
            color: AppColors.primary,
            bgColor: AppColors.primary.withValues(alpha: 0.06),
            borderColor: AppColors.primary.withValues(alpha: 0.15),
          ),
          const SizedBox(height: AppSizes.lg),

          _buildFormCard(
            children: [
              // Vehicle Type
              _buildFieldLabel('Vehicle Type'),
              const SizedBox(height: AppSizes.sm),
              Row(
                children: _vehicleTypes.map((type) {
                  final isSelected = _selectedVehicleType == type;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: type != _vehicleTypes.last ? 6.0 : 0.0,
                      ),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedVehicleType = type),
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
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSizes.lg),

              // Vehicle Make / Model
              _buildFieldLabel('Vehicle Make / Model'),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _vehicleMakeController,
                style: AppTextStyles.bodyLarge,
                decoration: const InputDecoration(
                  hintText: 'e.g. Honda CBR, Toyota Hiace',
                  prefixIcon: Icon(Iconsax.truck,
                      color: AppColors.primary, size: 20),
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Number Plate
              _buildFieldLabel('Number Plate'),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _vehiclePlateController,
                textCapitalization: TextCapitalization.characters,
                style: AppTextStyles.bodyLarge,
                decoration: const InputDecoration(
                  hintText: 'e.g. UAB 123X',
                  prefixIcon: Icon(Iconsax.hashtag,
                      color: AppColors.primary, size: 20),
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Driving License Number
              _buildFieldLabel('Driving License Number'),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _licenseNumberController,
                keyboardType: TextInputType.text,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                ],
                style: AppTextStyles.bodyLarge,
                decoration: const InputDecoration(
                  hintText: 'Enter your license number',
                  prefixIcon: Icon(Iconsax.card,
                      color: AppColors.primary, size: 20),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your license number';
                  }
                  if (value.length < 5) {
                    return 'License number is too short';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.lg),

              // License Photo
              _buildFieldLabel('Driving License Photo (Optional)'),
              const SizedBox(height: 4),
              Text(
                'Upload a clear photo of your driving license',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              _buildImageUploadBox(
                hasImage: hasLicensePhoto,
                xFile: _licensePhotoXFile,
                file: _licensePhotoFile,
                onTap: () => _pickImage('license'),
                icon: Iconsax.gallery_add,
                label: 'Tap to upload license photo',
                sublabel: 'JPG, PNG (max 5MB)',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──── Step 3: Payment ────

  Widget _buildPaymentStep() {
    return Form(
      key: _paymentFormKey,
      child: Column(
        children: [
          _buildInfoBox(
            icon: Iconsax.wallet_2,
            text:
                'Add your payment details so you can receive earnings from completed deliveries.',
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
                          onTap: () => setState(
                              () => _selectedMomoProvider = provider),
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

  // ──── Step 4: Contact ────

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

class _RiderStepIndicator extends StatelessWidget {
  final int currentStep;

  const _RiderStepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = ['Identity', 'Vehicle', 'Payment', 'Contact'];

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
