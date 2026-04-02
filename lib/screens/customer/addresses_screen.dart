import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:math' as math;
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../services/address_service.dart';
import '../../models/address.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/map_location_picker.dart';
import 'package:geolocator/geolocator.dart';

class AddressesScreen extends StatefulWidget {
  final String? returnRoute;

  const AddressesScreen({super.key, this.returnRoute});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final authProvider = context.read<AuthProvider>();
    final addressService = context.read<AddressService>();

    final customerId = authProvider.user?.customerId;
    if (authProvider.user != null &&
        authProvider.token != null &&
        customerId != null) {
      final success = await addressService.fetchAddresses(
        authProvider.token!,
        customerId,
      );
      if (success) {
        await authProvider.setAddresses(addressService.userAddresses);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/customer/home');
            }
          },
        ),
        title: Text(
          'Delivery Addresses',
          style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.elegantBgGradient),
        child: ResponsiveContainer(
          child: SafeArea(
            child: Consumer2<AuthProvider, AddressService>(
              builder: (context, auth, addressService, _) {
                if (addressService.isLoading) {
                  return const AppLoadingPage();
                }

                return RefreshIndicator(
                  onRefresh: _loadAddresses,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.horizontalPadding,
                        vertical: AppSizes.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saved Addresses',
                            style: AppTextStyles.h5.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSizes.sm),
                          Text(
                            'Manage where your orders are delivered.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSizes.lg),

                          if (addressService.addresses.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(AppSizes.lg),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMd,
                                ),
                                boxShadow: AppColors.shadowSm,
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Iconsax.location_slash,
                                      size: 64,
                                      color: AppColors.textTertiary,
                                    ),
                                    const SizedBox(height: AppSizes.md),
                                    Text(
                                      'No addresses yet',
                                      style: AppTextStyles.h5,
                                    ),
                                    const SizedBox(height: AppSizes.xs),
                                    Text(
                                      'Add your first delivery address to get started',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Column(
                              children: addressService.addresses
                                  .map(
                                    (address) => AddressCard(
                                      address: address,
                                      isDefault:
                                          addressService.defaultAddress?.id ==
                                          address.id,
                                      onEdit: () => _showAddressForm(
                                        context,
                                        auth,
                                        addressService,
                                        address,
                                      ),
                                      onDelete: () => _deleteAddress(
                                        context,
                                        auth,
                                        addressService,
                                        address.id,
                                        address.documentId,
                                      ),
                                      onSetDefault: () => _setDefault(
                                        context,
                                        auth,
                                        addressService,
                                        address.id,
                                        address.documentId,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),

                          const SizedBox(height: AppSizes.lg),
                          CustomButton(
                            text: 'Add New Address',
                            icon: Iconsax.add,
                            backgroundColor: AppColors.primary,
                            onPressed: () => _showAddressForm(
                              context,
                              auth,
                              addressService,
                              null,
                            ),
                          ),
                          const SizedBox(height: AppSizes.xl),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showAddressForm(
    BuildContext context,
    AuthProvider auth,
    AddressService addressService,
    Address? address,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddressForm(
        address: address,
        userId: auth.user?.customerId ?? '',
        token: auth.token ?? '',
        onSave:
            (
              label,
              addressLine,
              city,
              landmark,
              instructions,
              isDefault,
              lat,
              lng,
            ) async {
              if (address == null) {
                await addressService.createAddress(
                  token: auth.token!,
                  customerId: auth.user!.customerId ?? '',
                  label: label,
                  addressLine: addressLine,
                  city: city,
                  landmark: landmark,
                  deliveryInstructions: instructions,
                  isDefault: isDefault,
                  gpsLat: lat,
                  gpsLng: lng,
                );
              } else {
                await addressService.updateAddress(
                  token: auth.token!,
                  addressId: address.id,
                  addressDocumentId: address.documentId,
                  label: label,
                  addressLine: addressLine,
                  city: city,
                  landmark: landmark,
                  deliveryInstructions: instructions,
                  isDefault: isDefault,
                  gpsLat: lat,
                  gpsLng: lng,
                );
              }
              await auth.setAddresses(addressService.userAddresses);
              if (context.mounted) {
                Navigator.pop(context);
                if (address == null && widget.returnRoute != null) {
                  context.go(widget.returnRoute!);
                }
              }
            },
      ),
    );
  }

  Future<void> _deleteAddress(
    BuildContext context,
    AuthProvider auth,
    AddressService addressService,
    int id,
    String documentId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address?'),
        content: const Text('This action cannot be undone'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await addressService.deleteAddress(
        token: auth.token!,
        addressId: id,
        addressDocumentId: documentId,
      );
      await auth.setAddresses(addressService.userAddresses);
    }
  }

  Future<void> _setDefault(
    BuildContext context,
    AuthProvider auth,
    AddressService addressService,
    int id,
    String documentId,
  ) async {
    await addressService.setDefaultAddress(
      token: auth.token!,
      addressId: id,
      addressDocumentId: documentId,
    );
    await auth.setAddresses(addressService.userAddresses);
  }
}

class AddressCard extends StatelessWidget {
  final Address address;
  final bool isDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const AddressCard({
    super.key,
    required this.address,
    required this.isDefault,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.grey200),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: const Icon(
                      Iconsax.location,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address.label,
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        address.city,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    'DEFAULT',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            address.fullAddress,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (address.landmark != null) ...[
            const SizedBox(height: AppSizes.xs),
            Text(
              'Near: ${address.landmark}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
          if (address.deliveryInstructions != null) ...[
            const SizedBox(height: AppSizes.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.sm,
                vertical: AppSizes.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Text(
                address.deliveryInstructions!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSizes.md),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.xs,
            children: [
              _buildActionButton(
                label: 'Edit',
                icon: Iconsax.edit,
                color: AppColors.primary,
                onPressed: onEdit,
              ),
              _buildActionButton(
                label: 'Delete',
                icon: Iconsax.trash,
                color: AppColors.error,
                onPressed: onDelete,
              ),
              if (!isDefault)
                _buildActionButton(
                  label: 'Set Default',
                  icon: Iconsax.tick_circle,
                  color: AppColors.accent,
                  onPressed: onSetDefault,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: AppSizes.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          side: BorderSide(color: color.withValues(alpha: 0.2)),
        ),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class AddressForm extends StatefulWidget {
  final Address? address;
  final String userId;
  final String token;
  final Function(
    String label,
    String addressLine,
    String city,
    String? landmark,
    String? instructions,
    bool isDefault,
    double? lat,
    double? lng,
  )
  onSave;

  const AddressForm({
    super.key,
    this.address,
    required this.userId,
    required this.token,
    required this.onSave,
  });

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  late TextEditingController labelController;
  late TextEditingController addressLineController;
  late TextEditingController cityController;
  late TextEditingController landmarkController;
  late TextEditingController instructionsController;
  bool isDefault = false;
  double? _selectedLat;
  double? _selectedLng;
  bool _showMap = false; // Whether user chose to use map

  double _toRadians(double degrees) => degrees * math.pi / 180;

  @override
  void initState() {
    super.initState();
    labelController = TextEditingController(text: widget.address?.label ?? '');
    addressLineController = TextEditingController(
      text: widget.address?.addressLine ?? '',
    );
    cityController = TextEditingController(text: widget.address?.city ?? '');
    landmarkController = TextEditingController(
      text: widget.address?.landmark ?? '',
    );
    instructionsController = TextEditingController(
      text: widget.address?.deliveryInstructions ?? '',
    );
    isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    labelController.dispose();
    addressLineController.dispose();
    cityController.dispose();
    landmarkController.dispose();
    instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSizes.md,
        right: AppSizes.md,
        top: AppSizes.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.address == null ? 'Add Address' : 'Edit Address',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSizes.md),

            // Location method choice
            if (!_showMap) ...[
              Text(
                'How would you like to set your location?',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showMap = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.map_outlined, color: AppColors.primary, size: 28),
                            const SizedBox(height: 6),
                            Text(
                              'Use Map',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Search or pin location',
                              style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary, fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Skip map, just fill in text fields manually
                        // Focus the address field
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                          border: Border.all(color: AppColors.grey200),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 28),
                            const SizedBox(height: 6),
                            Text(
                              'Type Address',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Enter address manually',
                              style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary, fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
            ] else ...[
              // Map picker (shown after user chooses "Use Map")
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pin your location', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                  GestureDetector(
                    onTap: () => setState(() => _showMap = false),
                    child: Text('Type instead', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              MapLocationPicker(
                initialLat: widget.address?.gpsLat,
                initialLng: widget.address?.gpsLng,
                onLocationSelected: (result) async {
                  setState(() {
                    _selectedLat = result.latitude;
                    _selectedLng = result.longitude;
                    if (result.address != null && addressLineController.text.isEmpty) {
                      addressLineController.text = result.address!;
                    }
                    if (result.city != null && cityController.text.isEmpty) {
                      cityController.text = result.city!;
                    }
                  });

                  // Check distance from current location
                  try {
                    final position = await Geolocator.getLastKnownPosition();
                    if (position != null && mounted) {
                      final distanceMeters = Geolocator.distanceBetween(
                        position.latitude, position.longitude,
                        result.latitude, result.longitude,
                      );
                      final distanceKm = distanceMeters / 1000;
                      if (distanceKm > 3) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'This location is ${distanceKm.toStringAsFixed(1)} km from your current position. Are you sure?',
                            ),
                            backgroundColor: Colors.orange,
                            duration: const Duration(seconds: 4),
                            action: SnackBarAction(
                              label: 'OK',
                              textColor: Colors.white,
                              onPressed: () {},
                            ),
                          ),
                        );
                      }
                    }
                  } catch (_) {
                    // GPS not available — skip distance check
                  }

                  // Service area boundary check
                  if (mounted) {
                    final dLat = _toRadians(result.latitude - AppConstants.serviceAreaCenterLat);
                    final dLng = _toRadians(result.longitude - AppConstants.serviceAreaCenterLng);
                    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
                        math.cos(_toRadians(AppConstants.serviceAreaCenterLat)) *
                        math.cos(_toRadians(result.latitude)) *
                        math.sin(dLng / 2) * math.sin(dLng / 2);
                    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
                    final serviceDistKm = 6371.0 * c;
                    if (serviceDistKm > AppConstants.serviceAreaRadiusKm) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'This location is outside our delivery zone '
                            '(${serviceDistKm.toStringAsFixed(1)} km from Kampala center). '
                            'We currently deliver within ${AppConstants.serviceAreaRadiusKm.toInt()} km.',
                          ),
                          backgroundColor: AppColors.error,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: AppSizes.md),
            ],

            _buildInputField(
              controller: labelController,
              label: 'Label',
              hint: 'e.g., Home, Office',
            ),
            const SizedBox(height: AppSizes.md),
            _buildInputField(
              controller: addressLineController,
              label: 'Address',
              hint: 'Street, building, apartment',
              maxLines: 2,
            ),
            const SizedBox(height: AppSizes.md),
            _buildInputField(
              controller: cityController,
              label: 'City',
              hint: 'e.g., Kampala',
            ),
            const SizedBox(height: AppSizes.md),
            _buildInputField(
              controller: landmarkController,
              label: 'Landmark (optional)',
              hint: 'e.g., Near market, Next to park',
            ),
            const SizedBox(height: AppSizes.md),
            _buildInputField(
              controller: instructionsController,
              label: 'Delivery Instructions (optional)',
              hint: 'e.g., Ring the bell twice',
              maxLines: 2,
            ),
            const SizedBox(height: AppSizes.md),
            Container(
              padding: const EdgeInsets.all(AppSizes.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                border: Border.all(color: AppColors.grey200),
              ),
              child: CheckboxListTile(
                value: isDefault,
                onChanged: (v) => setState(() => isDefault = v ?? false),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Set as default address',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            CustomButton(
              text: widget.address == null ? 'Add Address' : 'Update Address',
              icon: widget.address == null ? Iconsax.add : Iconsax.tick_circle,
              backgroundColor: AppColors.primary,
              onPressed: () {
                widget.onSave(
                  labelController.text,
                  addressLineController.text,
                  cityController.text,
                  landmarkController.text.isEmpty
                      ? null
                      : landmarkController.text,
                  instructionsController.text.isEmpty
                      ? null
                      : instructionsController.text,
                  isDefault,
                  _selectedLat,
                  _selectedLng,
                );
              },
            ),
            const SizedBox(height: AppSizes.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: AppTextStyles.labelMedium,
        hintStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textTertiary,
        ),
        filled: true,
        fillColor: AppColors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.grey200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
