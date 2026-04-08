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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadAddresses();
      }
    });
  }

  Future<void> _loadAddresses() async {
    final authProvider = context.read<AuthProvider>();
    final addressService = context.read<AddressService>();
    await _refreshAddresses(authProvider, addressService);
  }

  Future<void> _refreshAddresses(
    AuthProvider auth,
    AddressService addressService,
  ) async {
    final customerId = auth.user?.customerId;
    final token = auth.token;

    if (auth.user != null && token != null && customerId != null) {
      final success = await addressService.fetchAddresses(token, customerId);
      if (success) {
        await auth.setAddresses(addressService.userAddresses);
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
    final pageContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => AddressForm(
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
              final token = auth.token;
              final customerId = auth.user?.customerId ?? auth.user?.id;
              bool saved = false;

              if (token == null ||
                  token.isEmpty ||
                  customerId == null ||
                  customerId.isEmpty) {
                await addressService.savePreferredAddress(
                  label: label,
                  addressLine: addressLine,
                  city: city,
                  landmark: landmark,
                  deliveryInstructions: instructions,
                  isDefault: isDefault,
                  gpsLat: lat,
                  gpsLng: lng,
                );
                saved = true;
              } else if (address == null) {
                saved = await addressService.createAddress(
                  token: token,
                  customerId: customerId,
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
                saved = await addressService.updateAddress(
                  token: token,
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

              if (saved) {
                await _refreshAddresses(auth, addressService);
              }

              if (!pageContext.mounted) return;

              if (!saved) {
                ScaffoldMessenger.of(pageContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      addressService.error ??
                          'Could not save address. Please try again.',
                    ),
                  ),
                );
                return;
              }

              Navigator.of(sheetContext).pop();
              if (widget.returnRoute != null &&
                  widget.returnRoute!.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (pageContext.mounted) {
                    pageContext.go(widget.returnRoute!);
                  }
                });
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
      final messenger = ScaffoldMessenger.of(context);
      final deleted = await addressService.deleteAddress(
        token: auth.token!,
        addressId: id,
        addressDocumentId: documentId,
      );

      if (deleted) {
        await _refreshAddresses(auth, addressService);
        if (context.mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Address deleted successfully')),
          );
        }
      } else if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not delete address. Try again.')),
        );
      }
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
    await _refreshAddresses(auth, addressService);

    if (widget.returnRoute != null &&
        widget.returnRoute!.isNotEmpty &&
        context.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(widget.returnRoute!);
        }
      });
    }
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
  final bool showHeader;
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
    this.showHeader = true,
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
  bool _showMap =
      false; // Map pin is optional but helps riders find the exact stop.

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
    _selectedLat = widget.address?.gpsLat;
    _selectedLng = widget.address?.gpsLng;
    _showMap = _selectedLat != null && _selectedLng != null;
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
        top: widget.showHeader ? AppSizes.lg : AppSizes.sm,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showHeader) ...[
              Text(
                widget.address == null ? 'Add Address' : 'Edit Address',
                style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSizes.md),
            ],

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(color: AppColors.grey200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Iconsax.location,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSizes.xs),
                      Expanded(
                        child: Text(
                          'Address details come first',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    'Use the area, building name, and a nearby landmark. Add a map pin only if you want extra precision for the rider.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  if (!_showMap)
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _showMap = true),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('Add map pin (optional)'),
                    )
                  else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pin your exact drop-off point',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _showMap = false),
                          child: const Text('Hide map'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      'Search, drag, or use GPS. The address preview updates automatically as you move the map.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    MapLocationPicker(
                      initialLat: _selectedLat ?? widget.address?.gpsLat,
                      initialLng: _selectedLng ?? widget.address?.gpsLng,
                      onLocationSelected: (result) async {
                        final messenger = ScaffoldMessenger.of(context);

                        setState(() {
                          _selectedLat = result.latitude;
                          _selectedLng = result.longitude;
                          if ((result.address ?? '').trim().isNotEmpty) {
                            addressLineController.text = result.address!.trim();
                          }
                          if ((result.city ?? '').trim().isNotEmpty) {
                            cityController.text = result.city!.trim();
                          }
                        });

                        try {
                          final position =
                              await Geolocator.getLastKnownPosition();
                          if (position != null && mounted) {
                            final distanceMeters = Geolocator.distanceBetween(
                              position.latitude,
                              position.longitude,
                              result.latitude,
                              result.longitude,
                            );
                            final distanceKm = distanceMeters / 1000;
                            if (distanceKm > 3) {
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'This pin is ${distanceKm.toStringAsFixed(1)} km from your current phone location. Please double-check it.',
                                  ),
                                  backgroundColor: Colors.orange,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          }
                        } catch (_) {
                          // GPS not available — skip distance check
                        }

                        if (mounted) {
                          final dLat = _toRadians(
                            result.latitude - AppConstants.serviceAreaCenterLat,
                          );
                          final dLng = _toRadians(
                            result.longitude -
                                AppConstants.serviceAreaCenterLng,
                          );
                          final a =
                              math.sin(dLat / 2) * math.sin(dLat / 2) +
                              math.cos(
                                    _toRadians(
                                      AppConstants.serviceAreaCenterLat,
                                    ),
                                  ) *
                                  math.cos(_toRadians(result.latitude)) *
                                  math.sin(dLng / 2) *
                                  math.sin(dLng / 2);
                          final c =
                              2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
                          final serviceDistKm = 6371.0 * c;
                          if (serviceDistKm >
                              AppConstants.serviceAreaRadiusKm) {
                            messenger.showSnackBar(
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
                    if (_selectedLat != null && _selectedLng != null) ...[
                      const SizedBox(height: AppSizes.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSizes.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusSm,
                          ),
                        ),
                        child: Text(
                          'Pinned coordinates: ${_selectedLat!.toStringAsFixed(5)}, ${_selectedLng!.toStringAsFixed(5)}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),

            _buildInputField(
              controller: labelController,
              label: 'Label',
              hint: 'e.g., Home, Office',
            ),
            const SizedBox(height: AppSizes.md),
            _buildInputField(
              controller: addressLineController,
              label: 'Area / Building / Road',
              hint: 'e.g., Ntinda, Sunrise Apartments, House 4',
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
              hint: 'e.g., Opposite Total Petrol Station',
            ),
            const SizedBox(height: AppSizes.md),
            _buildInputField(
              controller: instructionsController,
              label: 'Delivery Instructions (optional)',
              hint: 'e.g., Call me when you arrive at the gate',
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
