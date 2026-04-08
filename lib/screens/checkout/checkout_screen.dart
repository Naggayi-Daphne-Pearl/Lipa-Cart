import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../models/user.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/order_service.dart';
import '../../services/address_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/app_bottom_nav.dart';

class CheckoutScreen extends StatefulWidget {
  final bool isGuest;
  const CheckoutScreen({super.key, this.isGuest = false});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  PaymentMethod _selectedPayment = PaymentMethod.mobileMoney;
  Address? _selectedAddress;
  bool _isLoading = false;
  bool _consentChecked = false;
  bool _showAddressForm = false;
  bool _didAutoRedirectForMissingAddress = false;

  // Guest checkout fields
  late final TextEditingController _guestNameController;
  late final TextEditingController _guestPhoneController;
  late final TextEditingController _guestEmailController;
  late final TextEditingController _guestAddressController;
  late final TextEditingController _guestCityController;

  // Authenticated user address fields
  late final TextEditingController _authAddressController;
  late final TextEditingController _authCityController;
  late final TextEditingController _authLandmarkController;

  @override
  void initState() {
    super.initState();
    _guestNameController = TextEditingController();
    _guestPhoneController = TextEditingController();
    _guestEmailController = TextEditingController();
    _guestAddressController = TextEditingController();
    _guestCityController = TextEditingController();

    final preferredAddress = context.read<AddressService>().defaultAddress;
    if (preferredAddress != null && preferredAddress.id != 0) {
      _guestAddressController.text = preferredAddress.addressLine;
      _guestCityController.text = preferredAddress.city;
    }

    _authAddressController = TextEditingController();
    _authCityController = TextEditingController(text: 'Kampala');
    _authLandmarkController = TextEditingController();

    // Clear snackbars from previous screens (e.g. "View Cart" actions)
    // so checkout starts with a clean UI.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.hideCurrentSnackBar(reason: SnackBarClosedReason.remove);
      messenger?.clearSnackBars();
    });

    if (!widget.isGuest) {
      _selectedAddress = context.read<AuthProvider>().defaultAddress;
      _loadSavedAddresses();
    }
  }

  Future<void> _loadSavedAddresses() async {
    final authProvider = context.read<AuthProvider>();
    final addressService = context.read<AddressService>();

    if (authProvider.user == null || authProvider.token == null) return;
    final customerId = authProvider.user?.customerId;
    if (customerId == null || customerId.isEmpty) return;

    if (authProvider.user!.addresses.isEmpty) {
      final success = await addressService.fetchAddresses(
        authProvider.token!,
        customerId,
      );
      if (success && mounted) {
        await authProvider.setAddresses(addressService.userAddresses);
      }
    }

    if (!mounted) return;
    setState(() => _selectedAddress = authProvider.defaultAddress);

    if (_selectedAddress == null && !_didAutoRedirectForMissingAddress) {
      _didAutoRedirectForMissingAddress = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _goToAddressSelection();
        }
      });
    }
  }

  @override
  void dispose() {
    _guestNameController.dispose();
    _guestPhoneController.dispose();
    _guestEmailController.dispose();
    _guestAddressController.dispose();
    _guestCityController.dispose();
    _authAddressController.dispose();
    _authCityController.dispose();
    _authLandmarkController.dispose();
    super.dispose();
  }

  /// Haversine formula — returns distance in km between two GPS points.
  double _haversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;

  Future<String?> _promptForMissingPhoneNumber() async {
    final phoneController = TextEditingController();
    String? submittedPhone;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Add phone number to place your order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Google got you signed in quickly. We just need a delivery phone number before your first order.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                prefixText: '+256 ',
                hintText: '7XXXXXXXX',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () {
              final phoneText = phoneController.text.trim();
              if (phoneText.length != 9 ||
                  !RegExp(r'^[0-9]{9}$').hasMatch(phoneText)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Phone number must be exactly 9 digits'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              submittedPhone = '+256$phoneText';
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Save & continue'),
          ),
        ],
      ),
    );

    phoneController.dispose();
    return submittedPhone;
  }

  Future<void> _placeOrder() async {
    setState(() => _isLoading = true);

    try {
      final cartProvider = context.read<CartProvider>();

      if (widget.isGuest) {
        final nameText = _guestNameController.text.trim();
        final phoneText = _guestPhoneController.text.trim();
        final emailText = _guestEmailController.text.trim();
        final addressText = _guestAddressController.text.trim();
        final cityText = _guestCityController.text.trim();

        if (nameText.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter your name'),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        if (phoneText.length != 9 ||
            !RegExp(r'^[0-9]{9}$').hasMatch(phoneText)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone number must be exactly 9 digits'),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        if (emailText.isNotEmpty &&
            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+\b').hasMatch(emailText)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid email address'),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        if (addressText.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a delivery address'),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        final orderProvider = context.read<OrderProvider>();
        final orderService = context.read<OrderService>();
        final addressService = context.read<AddressService>();
        final resolvedCity = cityText.isEmpty ? 'Kampala' : cityText;

        await addressService.savePreferredAddress(
          label: 'Delivery Address',
          addressLine: addressText,
          city: resolvedCity,
          isDefault: true,
        );

        final guestAddress = Address(
          id: 'guest-${DateTime.now().millisecondsSinceEpoch}',
          label: 'Delivery Address',
          fullAddress: '$addressText, $resolvedCity',
          latitude: 0.0,
          longitude: 0.0,
          isDefault: true,
        );

        final localOrder = await orderProvider.createOrder(
          items: cartProvider.items,
          deliveryAddress: guestAddress,
          subtotal: cartProvider.subtotal,
          serviceFee: cartProvider.serviceFee,
          deliveryFee: cartProvider.deliveryFee,
          paymentMethod: _selectedPayment,
        );

        final backendGuestOrder = await orderService.createGuestOrder(
          guestName: nameText,
          guestPhone: '+256$phoneText',
          addressLine: addressText,
          city: resolvedCity,
          subtotal: cartProvider.subtotal,
          serviceFee: cartProvider.serviceFee,
          deliveryFee: cartProvider.deliveryFee,
          total: cartProvider.total,
        );

        setState(() => _isLoading = false);

        final createdOrder = localOrder ?? backendGuestOrder;
        if (createdOrder != null && mounted) {
          cartProvider.clearCart();
          context.push(
            '/customer/order-success',
            extra: {'order': createdOrder, 'isGuest': true},
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                orderProvider.errorMessage ??
                    orderService.error ??
                    'Failed to place order',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } else {
        // Authenticated checkout flow
        final authProvider = context.read<AuthProvider>();

        if (authProvider.needsPhoneNumber) {
          final phoneNumber = await _promptForMissingPhoneNumber();
          if (!mounted) return;
          if (phoneNumber == null) {
            setState(() => _isLoading = false);
            return;
          }

          final saved = await authProvider.completeCustomerProfile(
            phoneNumber: phoneNumber,
          );
          if (!mounted) return;

          if (!saved) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  authProvider.errorMessage ?? 'Failed to save phone number',
                ),
                backgroundColor: AppColors.error,
              ),
            );
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Phone number saved. You can continue with checkout.',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }

        if (_selectedAddress == null) {
          setState(() => _isLoading = false);
          _goToAddressSelection();
          return;
        }

        // Service area validation — check if address is within delivery zone
        if (_selectedAddress!.latitude != 0.0 &&
            _selectedAddress!.longitude != 0.0) {
          final distanceKm = _haversineDistance(
            _selectedAddress!.latitude,
            _selectedAddress!.longitude,
            AppConstants.serviceAreaCenterLat,
            AppConstants.serviceAreaCenterLng,
          );
          if (distanceKm > AppConstants.serviceAreaRadiusKm) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Sorry, this address is ${distanceKm.toStringAsFixed(1)} km away. '
                    'We currently deliver within ${AppConstants.serviceAreaRadiusKm.toInt()} km of Kampala center.',
                  ),
                  backgroundColor: AppColors.error,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
            setState(() => _isLoading = false);
            return;
          }
        }

        final orderProvider = context.read<OrderProvider>();
        final orderService = context.read<OrderService>();

        final localOrder = await orderProvider.createOrder(
          items: cartProvider.items,
          deliveryAddress: _selectedAddress!,
          subtotal: cartProvider.subtotal,
          serviceFee: cartProvider.serviceFee,
          deliveryFee: cartProvider.deliveryFee,
          paymentMethod: _selectedPayment,
        );

        final backendOrder = await orderService.createOrderWithItems(
          token: authProvider.token!,
          userId: authProvider.user!.id,
          addressId: _selectedAddress!.id,
          items: cartProvider.items,
          subtotal: cartProvider.subtotal,
          serviceFee: cartProvider.serviceFee,
          deliveryFee: cartProvider.deliveryFee,
          total: cartProvider.total,
          paymentMethod: _selectedPayment.name,
        );

        if (!mounted) return;

        if (backendOrder != null) {
          orderProvider.syncOrdersFromService(orderService.orders);
          orderProvider.setCurrentOrder(backendOrder);
        }

        setState(() => _isLoading = false);

        final orderForSuccess = backendOrder ?? localOrder;
        if (orderForSuccess != null && mounted) {
          cartProvider.clearCart();
          context.push('/customer/order-success', extra: orderForSuccess);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                orderProvider.errorMessage ?? 'Failed to place order',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              GoRouter.of(context).go('/customer/home');
            }
          },
        ),
        title: const Text('Checkout'),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.elegantBgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Progress Stepper
              _buildProgressStepper(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Delivery address or guest form
                      if (widget.isGuest)
                        _buildSection(
                          title: 'Sign Up & Delivery Details',
                          icon: Iconsax.user_add,
                          child: _buildGuestAddressForm(),
                        )
                      else
                        _buildSection(
                          title: 'Delivery Address',
                          icon: Iconsax.location,
                          child: _selectedAddress == null
                              ? (_showAddressForm
                                    ? _buildAuthAddressForm()
                                    : _buildAddAddressButton())
                              : _buildAddressCard(authProvider),
                        ),
                      const SizedBox(height: AppSizes.md),

                      // Order items
                      _buildSection(
                        title: 'Order Items (${cartProvider.itemCount})',
                        icon: Iconsax.shopping_bag,
                        child: Column(
                          children: cartProvider.items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSizes.sm,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.quantity.toInt()}x ${item.product.name}',
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                  ),
                                  Text(
                                    Formatters.formatCurrency(item.totalPrice),
                                    style: AppTextStyles.labelMedium,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),

                      // Payment method
                      _buildSection(
                        title: 'Payment Method',
                        icon: Iconsax.card,
                        child: Column(
                          children: PaymentMethod.values.map((method) {
                            return _buildPaymentOption(method);
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),

                      // Order summary
                      _buildSection(
                        title: 'Order Summary',
                        icon: Iconsax.receipt_2,
                        child: Column(
                          children: [
                            _buildSummaryRow(
                              'Subtotal',
                              Formatters.formatCurrency(cartProvider.subtotal),
                            ),
                            const SizedBox(height: AppSizes.sm),
                            _buildSummaryRow(
                              'Service Fee (5%)',
                              Formatters.formatCurrency(
                                cartProvider.serviceFee,
                              ),
                            ),
                            const SizedBox(height: AppSizes.sm),
                            _buildSummaryRow(
                              'Delivery Fee',
                              Formatters.formatCurrency(
                                cartProvider.deliveryFee,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSizes.sm,
                              ),
                              child: Divider(),
                            ),
                            _buildSummaryRow(
                              'Total',
                              Formatters.formatCurrency(cartProvider.total),
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Consent checkbox and Place order button
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Consent checkbox
                      CheckboxListTile(
                        value: _consentChecked,
                        onChanged: (val) {
                          setState(() => _consentChecked = val ?? false);
                        },
                        title: Text(
                          widget.isGuest
                              ? 'I confirm my details and agree to create an account'
                              : 'I confirm my order details are correct and agree to the terms',
                          style: AppTextStyles.bodySmall,
                        ),
                        activeColor: AppColors.accent,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: AppSizes.md),
                      // Place order button
                      CustomButton(
                        text:
                            'Place Order - ${Formatters.formatCurrency(cartProvider.total)}',
                        isLoading: _isLoading,
                        onPressed: _consentChecked ? _placeOrder : null,
                      ),
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

  Widget _buildProgressStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.md,
      ),
      child: Row(
        children: [
          _buildStepItem(
            icon: Iconsax.location,
            label: 'Address',
            isActive: true,
            isCompleted: _selectedAddress != null,
          ),
          Expanded(
            child: Container(
              height: 2,
              color: _selectedAddress != null
                  ? AppColors.primary
                  : AppColors.grey300,
            ),
          ),
          _buildStepItem(
            icon: Iconsax.card,
            label: 'Payment',
            isActive: true,
            isCompleted: false,
          ),
          Expanded(child: Container(height: 2, color: AppColors.grey300)),
          _buildStepItem(
            icon: Iconsax.tick_circle,
            label: 'Confirm',
            isActive: false,
            isCompleted: false,
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isCompleted,
  }) {
    final color = isCompleted
        ? AppColors.primary
        : isActive
        ? AppColors.accent
        : AppColors.grey400;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.primarySoft
                : isActive
                ? AppColors.accentSoft
                : AppColors.grey100,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(
            isCompleted ? Iconsax.tick_circle5 : icon,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryOrange),
              const SizedBox(width: AppSizes.sm),
              Text(title, style: AppTextStyles.h5),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          child,
        ],
      ),
    );
  }

  Widget _buildAddressCard(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedAddress!.label, style: AppTextStyles.labelMedium),
                const SizedBox(height: 4),
                Text(
                  _selectedAddress!.fullAddress,
                  style: AppTextStyles.bodySmall,
                ),
                if (_selectedAddress!.landmark != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Near: ${_selectedAddress!.landmark}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showAddressSelector(authProvider),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _goToAddressSelection() {
    final returnRoute = Uri.encodeComponent('/customer/checkout');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please add or select a delivery address to continue.'),
        backgroundColor: AppColors.warning,
      ),
    );
    context.go('/customer/addresses?return=$returnRoute');
  }

  Widget _buildAddAddressButton() {
    return GestureDetector(
      onTap: _goToAddressSelection,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.primaryOrange,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.add, color: AppColors.primaryOrange, size: 20),
            const SizedBox(width: AppSizes.sm),
            Text(
              'Select Delivery Address',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primaryOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthAddressForm() {
    return Column(
      children: [
        // Address field
        TextField(
          controller: _authAddressController,
          decoration: InputDecoration(
            hintText: 'e.g., Plot 123, Kampala Road',
            labelText: 'Delivery Address (required)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: AppSizes.md),
        // City field
        TextField(
          controller: _authCityController,
          decoration: InputDecoration(
            hintText: 'e.g., Kampala',
            labelText: 'City (required)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        // Landmark field
        TextField(
          controller: _authLandmarkController,
          decoration: InputDecoration(
            hintText: 'e.g., Near Nakumatt',
            labelText: 'Landmark (optional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _showAddressForm = false;
                    _authAddressController.clear();
                    _authCityController.text = 'Kampala';
                    _authLandmarkController.clear();
                  });
                },
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: CustomButton(
                text: 'Save Address',
                onPressed: _saveAddress,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _saveAddress() async {
    final addressText = _authAddressController.text.trim();
    final cityText = _authCityController.text.trim();
    final landmarkText = _authLandmarkController.text.trim();

    if (addressText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a delivery address'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (cityText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a city'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final customerId = authProvider.user?.customerId;
      final token = authProvider.token;

      if (customerId == null || token == null) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please login again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final addressResponse = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/addresses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'data': {
            'customer': customerId,
            'label': 'My Address',
            'address_line': addressText,
            'city': cityText,
            'landmark': landmarkText.isEmpty ? null : landmarkText,
            'is_default': true,
            'gps_lat': 0.0,
            'gps_lng': 0.0,
          },
        }),
      );

      setState(() => _isLoading = false);

      if (addressResponse.statusCode == 201) {
        final addressData = jsonDecode(addressResponse.body)['data'];
        final backendAddress = addressData['attributes'] ?? addressData;

        final savedAddress = Address(
          id: (addressData['id'] ?? addressData['documentId'] ?? '0')
              .toString(),
          label: backendAddress['label'] ?? 'My Address',
          fullAddress:
              '${backendAddress['address_line']}, ${backendAddress['city']}',
          landmark: backendAddress['landmark'],
          latitude:
              (backendAddress['latitude'] ?? backendAddress['gps_lat'] ?? 0.0)
                  .toDouble(),
          longitude:
              (backendAddress['longitude'] ?? backendAddress['gps_lng'] ?? 0.0)
                  .toDouble(),
          isDefault: backendAddress['is_default'] ?? true,
        );

        setState(() {
          _selectedAddress = savedAddress;
          _showAddressForm = false;
          _authAddressController.clear();
          _authCityController.text = 'Kampala';
          _authLandmarkController.clear();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address saved successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save address'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildGuestAddressForm() {
    return Column(
      children: [
        // Name field
        TextField(
          controller: _guestNameController,
          decoration: InputDecoration(
            hintText: 'Your full name',
            labelText: 'Name (required)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        // Email field
        TextField(
          controller: _guestEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'john@example.com',
            labelText: 'Email (optional for receipt)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        // Phone number field
        TextField(
          controller: _guestPhoneController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '701234567',
            labelText: 'Phone Number (9 digits)',
            prefixText: '+256 ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.sm),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Text(
            'No sign-up needed here. Just share your delivery details and place the order naturally.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        // Delivery address field
        TextField(
          controller: _guestAddressController,
          decoration: InputDecoration(
            hintText: 'e.g., 123 Main St, Plot 45',
            labelText: 'Delivery Address (required)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: AppSizes.md),
        // City field (optional)
        TextField(
          controller: _guestCityController,
          decoration: InputDecoration(
            hintText: 'e.g., Kampala',
            labelText: 'City (optional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(PaymentMethod method) {
    final isSelected = _selectedPayment == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = method),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.sm),
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryOrange.withValues(alpha: 0.1)
              : AppColors.lightGrey,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          border: isSelected
              ? Border.all(color: AppColors.primaryOrange)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              _getPaymentIcon(method),
              color: isSelected
                  ? AppColors.primaryOrange
                  : AppColors.textMedium,
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Text(
                method.displayName,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected
                      ? AppColors.primaryOrange
                      : AppColors.textDark,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Iconsax.tick_circle5,
                color: AppColors.primaryOrange,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getPaymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mobileMoney:
        return Iconsax.mobile;
      case PaymentMethod.card:
        return Iconsax.card;
      case PaymentMethod.cashOnDelivery:
        return Iconsax.money;
    }
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal ? AppTextStyles.labelMedium : AppTextStyles.bodySmall,
        ),
        Text(
          value,
          style: isTotal
              ? AppTextStyles.priceMedium
              : AppTextStyles.labelMedium,
        ),
      ],
    );
  }

  void _showAddressSelector(AuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXl),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Address', style: AppTextStyles.h5),
              const SizedBox(height: AppSizes.md),
              if (authProvider.user?.addresses.isEmpty ?? true)
                const Center(child: Text('No saved addresses'))
              else
                ...authProvider.user!.addresses.map((address) {
                  return ListTile(
                    onTap: () {
                      setState(() => _selectedAddress = address);
                      Navigator.pop(context);
                    },
                    leading: const Icon(Iconsax.location),
                    title: Text(address.label),
                    subtitle: Text(address.fullAddress),
                    trailing: _selectedAddress?.id == address.id
                        ? const Icon(
                            Iconsax.tick_circle5,
                            color: AppColors.primaryOrange,
                          )
                        : null,
                  );
                }),
              const SizedBox(height: AppSizes.md),
            ],
          ),
        );
      },
    );
  }
}
