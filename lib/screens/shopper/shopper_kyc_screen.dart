import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../providers/auth_provider.dart';
import '../../services/strapi_service.dart';
import '../../services/imgbb_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class ShopperKycScreen extends StatefulWidget {
  final bool isRejected;

  const ShopperKycScreen({super.key, this.isRejected = false});

  @override
  State<ShopperKycScreen> createState() => _ShopperKycScreenState();
}

class _ShopperKycScreenState extends State<ShopperKycScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idNumberController;
  File? _idPhotoFile;
  File? _selfiePhotoFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _idNumberController = TextEditingController();
  }

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
            _idPhotoFile = File(pickedFile.path);
          } else {
            _selfiePhotoFile = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _submitKyc() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idPhotoFile == null || _selfiePhotoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload both ID photo and selfie')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;
      final shopperId = authProvider.user?.shopperId;

      if (token == null || shopperId == null) {
        throw Exception('Missing authentication data');
      }

      // Upload photos to ImgBB
      final idPhotoUrl = await ImgBBService.uploadImage(_idPhotoFile!);
      final selfiePhotoUrl = await ImgBBService.uploadImage(_selfiePhotoFile!);

      if (idPhotoUrl == null || selfiePhotoUrl == null) {
        throw Exception('Failed to upload photos');
      }

      // Submit KYC
      final success = await StrapiService.submitShopperKyc(
        shopperId: shopperId,
        idNumber: _idNumberController.text,
        idPhotoUrl: idPhotoUrl,
        facePhotoUrl: selfiePhotoUrl,
        token: token,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KYC submitted successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        context.go('/shopper/pending-approval');
      } else if (mounted) {
        throw Exception('Failed to submit KYC');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final userName = authProvider.user?.name ?? 'Shopper';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Identity'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rejection banner if rejected
              if (widget.isRejected)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Application Rejected',
                        style: AppTextStyles.h5.copyWith(
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your KYC application was rejected. Please review and try again.',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

              // Full Name (read-only)
              Text('Full Name', style: AppTextStyles.labelSmall),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: userName,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Your name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 24),

              // National ID Number
              Text('National ID Number', style: AppTextStyles.labelSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _idNumberController,
                decoration: InputDecoration(
                  hintText: 'Enter your ID number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your ID number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // ID Document Photo
              Text('ID Document Photo', style: AppTextStyles.labelSmall),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _pickImage(true),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _idPhotoFile != null
                          ? AppColors.primary
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: _idPhotoFile != null
                        ? AppColors.primary.withValues(alpha: 0.05)
                        : Colors.grey.shade50,
                  ),
                  child: _idPhotoFile != null
                      ? Image.file(
                          _idPhotoFile!,
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to upload ID front',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Selfie Photo
              Text('Selfie (Face Photo)', style: AppTextStyles.labelSmall),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _pickImage(false),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selfiePhotoFile != null
                          ? AppColors.primary
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: _selfiePhotoFile != null
                        ? AppColors.primary.withValues(alpha: 0.05)
                        : Colors.grey.shade50,
                  ),
                  child: _selfiePhotoFile != null
                      ? Image.file(
                          _selfiePhotoFile!,
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to take selfie',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitKyc,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Submit KYC'),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Your documents will be reviewed within 24-48 hours',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
