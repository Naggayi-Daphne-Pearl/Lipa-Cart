import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../models/user.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
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

  // Guest checkout fields
  late final TextEditingController _guestNameController;
  late final TextEditingController _guestPhoneController;
  late final TextEditingController _guestAddressController;
  late final TextEditingController _guestCityController;
  late final TextEditingController _guestPasswordController;
  late final TextEditingController _guestConfirmPasswordController;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _guestNameController = TextEditingController();
    _guestPhoneController = TextEditingController();
    _guestAddressController = TextEditingController();
    _guestCityController = TextEditingController();
    _guestPasswordController = TextEditingController();
    _guestConfirmPasswordController = TextEditingController();

    if (!widget.isGuest) {
      _selectedAddress = context.read<AuthProvider>().defaultAddress;
    }
  }

  @override
  void dispose() {
    _guestNameController.dispose();
    _guestPhoneController.dispose();
    _guestAddressController.dispose();
    _guestCityController.dispose();
    _guestPasswordController.dispose();
    _guestConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    setState(() => _isLoading = true);

    try {
      final cartProvider = context.read<CartProvider>();

      if (widget.isGuest) {
        // Guest checkout flow with signup
        final nameText = _guestNameController.text.trim();
        final phoneText = _guestPhoneController.text.trim();
        final addressText = _guestAddressController.text.trim();
        final cityText = _guestCityController.text.trim();
        final password = _guestPasswordController.text.trim();
        final confirmPassword = _guestConfirmPasswordController.text.trim();

        // Validate name
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

        // Validate phone (9 digits)
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

        // Validate address
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

        // Validate password
        if (password.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a password'),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        if (password.length < 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password must be at least 6 characters'),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        if (password != confirmPassword) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Passwords do not match'),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        // Step 1: Create account
        final authProvider = context.read<AuthProvider>();
        final signupSuccess = await authProvider.signup(
          phoneNumber: '+256$phoneText',
          password: password,
          name: nameText,
        );

        if (!signupSuccess) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  authProvider.errorMessage ?? 'Failed to create account',
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        // Step 2: Create order as authenticated user
        final orderProvider = context.read<OrderProvider>();

        // Create temporary address for the order
        final tempAddress = Address(
          id: '0',
          label: 'Delivery Address',
          fullAddress:
              '$addressText${cityText.isNotEmpty ? ', $cityText' : ''}',
          latitude: 0.0,
          longitude: 0.0,
        );

        final order = await orderProvider.createOrder(
          items: cartProvider.items,
          deliveryAddress: tempAddress,
          subtotal: cartProvider.subtotal,
          serviceFee: cartProvider.serviceFee,
          deliveryFee: cartProvider.deliveryFee,
          paymentMethod: _selectedPayment,
        );

        setState(() => _isLoading = false);

        if (order != null && mounted) {
          cartProvider.clearCart();
          context.push('/customer/order-success', extra: order);
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
      } else {
        // Authenticated checkout flow
        if (_selectedAddress == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please add a delivery address'),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        final orderProvider = context.read<OrderProvider>();

        final order = await orderProvider.createOrder(
          items: cartProvider.items,
          deliveryAddress: _selectedAddress!,
          subtotal: cartProvider.subtotal,
          serviceFee: cartProvider.serviceFee,
          deliveryFee: cartProvider.deliveryFee,
          paymentMethod: _selectedPayment,
        );

        setState(() => _isLoading = false);

        if (order != null && mounted) {
          cartProvider.clearCart();
          context.push('/customer/order-success', extra: order);
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
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
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
                              ? _buildAddAddressButton()
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

  Widget _buildAddAddressButton() {
    return GestureDetector(
      onTap: () {
        // Navigate to add address screen
      },
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
              'Add Delivery Address',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primaryOrange,
              ),
            ),
          ],
        ),
      ),
    );
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
        // Password field
        TextField(
          controller: _guestPasswordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: 'At least 6 characters',
            labelText: 'Password (required)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                color: AppColors.grey400,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        // Confirm Password field
        TextField(
          controller: _guestConfirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            hintText: 'Re-enter your password',
            labelText: 'Confirm Password (required)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Iconsax.eye_slash : Iconsax.eye,
                color: AppColors.grey400,
              ),
              onPressed: () {
                setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                );
              },
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
