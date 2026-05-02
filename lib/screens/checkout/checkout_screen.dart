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
import '../../services/payment_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/web_layout_wrapper.dart';
import '../../widgets/price_text.dart';

enum _CheckoutSubmitPhase {
  placingOrder,
  initiatingPayment,
  waitingForConfirmation,
}

class CheckoutScreen extends StatefulWidget {
  final bool isGuest;

  /// Optional address documentId/id passed via the route query param when the
  /// user picks an address on the addresses screen in select mode. We resolve
  /// it against AddressService in initState and pre-select.
  final String? selectedAddressId;

  const CheckoutScreen({
    super.key,
    this.isGuest = false,
    this.selectedAddressId,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // MVP: only Cash on Delivery exposed. See .claude/playbooks/payments_todo.md
  // for the plan to re-enable mobile money (Flutterwave v4 already scaffolded).
  PaymentMethod _selectedPayment = PaymentMethod.cashOnDelivery;
  String _selectedPawaPayCorrespondent = 'MTN_MOMO_UGA';
  Address? _selectedAddress;
  bool _isLoading = false;
  bool _isCheckoutSubmitting = false;
  _CheckoutSubmitPhase? _checkoutSubmitPhase;
  bool _consentChecked = false;
  bool _showAddressForm = false;
  bool _didAutoRedirectForMissingAddress = false;
  bool _addressExpanded = true;
  bool _slotExpanded = true;
  bool _paymentExpanded = true;
  bool _summaryExpanded = true;
  int _selectedSlotIndex = 0;
  bool _promoExpanded = false;
  final TextEditingController _promoController = TextEditingController();
  final TextEditingController _riderNoteController = TextEditingController();
  late final TextEditingController _paymentPhoneController;

  final List<_DeliverySlot> _slots = const [
    _DeliverySlot('Now (60 min)', 5000, etaTag: 'Almost full'),
    _DeliverySlot('Today 2-3 PM', 3000),
    _DeliverySlot('Today 6-7 PM', 3000),
    _DeliverySlot('Tomorrow 9-10 AM', 2500, saveTag: 'Save UGX 2,500'),
  ];

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
    _paymentPhoneController = TextEditingController();

    final authPhone = _resolvePaymentPhoneNumber(context.read<AuthProvider>());
    if (authPhone != null && authPhone.startsWith('+256') && authPhone.length == 13) {
      _paymentPhoneController.text = authPhone.substring(4);
    }

    // Clear snackbars from previous screens (e.g. "View Cart" actions)
    // so checkout starts with a clean UI.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.hideCurrentSnackBar(reason: SnackBarClosedReason.remove);
      messenger?.clearSnackBars();
    });

    if (!widget.isGuest) {
      final addressService = context.read<AddressService>();
      // Prefer an explicit pick from the addresses screen over the default.
      final picked = _resolveSelectedAddress(addressService);
      _selectedAddress = picked ?? addressService.defaultUserAddress;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadSavedAddresses();
      });
    }
  }

  /// Look up the address the user picked on the addresses screen by matching
  /// either the documentId-as-id we encoded or the numeric Strapi id.
  Address? _resolveSelectedAddress(AddressService addressService) {
    final id = widget.selectedAddressId;
    if (id == null || id.isEmpty) return null;
    for (final a in addressService.addresses) {
      if (a.documentId == id || a.id.toString() == id) {
        // Convert via the existing Address -> user_models.Address mapper.
        return addressService.userAddresses.firstWhere(
          (u) => u.id == a.id.toString(),
          orElse: () => addressService.defaultUserAddress!,
        );
      }
    }
    return null;
  }

  Future<void> _loadSavedAddresses() async {
    final authProvider = context.read<AuthProvider>();
    final addressService = context.read<AddressService>();

    if (authProvider.user == null || authProvider.token == null) return;
    final customerId = authProvider.user?.customerId;
    if (customerId == null || customerId.isEmpty) return;

    if (addressService.userAddresses.isEmpty) {
      await addressService.fetchAddresses(authProvider.token!, customerId);
    }

    if (!mounted) return;
    // If the user explicitly picked an address on the addresses screen, keep
    // it selected after the fetch completes. Otherwise fall back to default.
    final picked = _resolveSelectedAddress(addressService);
    setState(
      () => _selectedAddress = picked ?? addressService.defaultUserAddress,
    );

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
    _promoController.dispose();
    _riderNoteController.dispose();
    _paymentPhoneController.dispose();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  String? _resolvePaymentPhoneNumber(AuthProvider authProvider) {
    final raw = authProvider.user?.phoneNumber.trim() ?? '';
    if (raw.isEmpty) return null;

    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('256') && digits.length == 12) return '+$digits';
    if (digits.startsWith('0') && digits.length == 10) {
      return '+256${digits.substring(1)}';
    }
    if (digits.length == 9) return '+256$digits';
    return null;
  }

  String? _normalizedSelectedPaymentPhone() {
    final raw = _paymentPhoneController.text.trim();
    if (raw.isEmpty) return null;

    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('256') && digits.length == 12) return '+$digits';
    if (digits.startsWith('0') && digits.length == 10) {
      return '+256${digits.substring(1)}';
    }
    if (digits.length == 9) return '+256$digits';
    return null;
  }

  double _estimatedPawaPayCharge(double subtotal) {
    if (_selectedPayment != PaymentMethod.mobileMoney) return 0;
    final charge =
        AppConstants.pawaPayChargeFlat +
        (subtotal * (AppConstants.pawaPayChargePercent / 100));
    return charge.roundToDouble();
  }

  double _checkoutDisplayTotal(CartProvider cartProvider) {
    return cartProvider.subtotal +
        cartProvider.serviceFee +
        _slots[_selectedSlotIndex].fee +
        _estimatedPawaPayCharge(cartProvider.subtotal);
  }

  void _setCheckoutSubmitPhase(_CheckoutSubmitPhase phase) {
    if (!mounted) return;
    setState(() {
      _isCheckoutSubmitting = true;
      _checkoutSubmitPhase = phase;
    });
  }

  void _clearCheckoutSubmitState() {
    if (!mounted) return;
    setState(() {
      _isCheckoutSubmitting = false;
      _checkoutSubmitPhase = null;
    });
  }

  String get _checkoutPhaseLabel {
    switch (_checkoutSubmitPhase) {
      case _CheckoutSubmitPhase.placingOrder:
        return 'Placing your order...';
      case _CheckoutSubmitPhase.initiatingPayment:
        return 'Initiating payment...';
      case _CheckoutSubmitPhase.waitingForConfirmation:
        return 'Waiting for confirmation...';
      case null:
        return 'Processing checkout...';
    }
  }

  double get _checkoutPhaseProgress {
    switch (_checkoutSubmitPhase) {
      case _CheckoutSubmitPhase.placingOrder:
        return 0.33;
      case _CheckoutSubmitPhase.initiatingPayment:
        return 0.66;
      case _CheckoutSubmitPhase.waitingForConfirmation:
        return 1.0;
      case null:
        return 0.0;
    }
  }

  Widget _buildCheckoutLoadingButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Flexible(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    _checkoutPhaseLabel,
                    key: ValueKey<String>(_checkoutPhaseLabel),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusXs),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: _checkoutPhaseProgress),
              duration: const Duration(milliseconds: 280),
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: AppColors.primarySoft.withValues(alpha: 0.35),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.white),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutLoadingOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: AppColors.background.withValues(alpha: 0.55),
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Align(
            alignment: Alignment.center,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                boxShadow: AppColors.shadowSm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Checkout in progress', style: AppTextStyles.labelLarge),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    _checkoutPhaseLabel,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusXs),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: _checkoutPhaseProgress),
                      duration: const Duration(milliseconds: 280),
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor: AppColors.primarySoft,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    _setCheckoutSubmitPhase(_CheckoutSubmitPhase.placingOrder);

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
          _clearCheckoutSubmitState();
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
          _clearCheckoutSubmitState();
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
          _clearCheckoutSubmitState();
          return;
        }

        if (addressText.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a delivery address'),
              backgroundColor: AppColors.error,
            ),
          );
          _clearCheckoutSubmitState();
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

        // Backend-first: only mutate local state on a successful round-trip,
        // so we don't show a fake success screen for an order the server
        // never accepted.
        final backendGuestOrder = await orderService.createGuestOrder(
          guestName: nameText,
          guestPhone: '+256$phoneText',
          addressLine: addressText,
          city: resolvedCity,
          items: cartProvider.items,
        );

        _clearCheckoutSubmitState();

        if (backendGuestOrder != null && mounted) {
          // Mirror the order locally so the order list is populated immediately,
          // then clear the cart atomically.
          await orderProvider.adoptExistingOrder(backendGuestOrder);
          if (!mounted) return;
          cartProvider.clearCart();
          context.push(
            '/customer/order-success',
            extra: {'order': backendGuestOrder, 'isGuest': true},
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(orderService.error ?? 'Failed to place order'),
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
            _clearCheckoutSubmitState();
            return;
          }

          final saved = await authProvider.completeCustomerProfile(
            phoneNumber: phoneNumber,
          );
          if (!mounted) return;

          if (!saved) {
            _clearCheckoutSubmitState();
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
          _clearCheckoutSubmitState();
          _goToAddressSelection();
          return;
        }

        // Service area validation — check if address is within delivery zone.
        // Backend also enforces this; the client check is just for fast UX.
        final lat = _selectedAddress!.latitude;
        final lng = _selectedAddress!.longitude;
        if (!_selectedAddress!.hasCoordinates) {
          // Address has no GPS pin — backend service-area check would reject
          // with a confusing 400. Push the user to the address picker so they
          // can drop a pin before checkout.
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Please pick a delivery address with a map location so we can verify it’s in our delivery zone.',
                ),
                backgroundColor: AppColors.error,
                duration: Duration(seconds: 4),
              ),
            );
          }
          _clearCheckoutSubmitState();
          _goToAddressSelection();
          return;
        }
        if (lat != null && lng != null && !(lat == 0 && lng == 0)) {
          final distanceKm = _haversineDistance(
            lat,
            lng,
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
            _clearCheckoutSubmitState();
            return;
          }
        }

        final orderProvider = context.read<OrderProvider>();
        final orderService = context.read<OrderService>();

        String? paymentPhone;
        if (_selectedPayment == PaymentMethod.mobileMoney) {
          paymentPhone = _normalizedSelectedPaymentPhone();
          if (paymentPhone == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Enter a valid Uganda Mobile Money number to pay with.'),
                backgroundColor: AppColors.error,
              ),
            );
            _clearCheckoutSubmitState();
            return;
          }
        }

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
          paymentMethod: _selectedPayment.toBackendValue,
        );

        if (!mounted) return;

        _setCheckoutSubmitPhase(_CheckoutSubmitPhase.initiatingPayment);

        final hasValidBackendTotal =
            backendOrder != null && backendOrder.total > 0;

        if (backendOrder != null && !hasValidBackendTotal) {
          _clearCheckoutSubmitState();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  orderService.error ??
                      'Order total is invalid. Please review cart items and try again.',
                ),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }

        if (hasValidBackendTotal) {
          orderProvider.syncOrdersFromService(orderService.orders);
          orderProvider.setCurrentOrder(backendOrder);

          if (_selectedPayment == PaymentMethod.mobileMoney) {
            if (paymentPhone != null) {
              try {
                final orderRef = backendOrder.documentId ?? backendOrder.id;
                final result =
                    await PaymentService.initiateFlutterwaveMobileMoney(
                      token: authProvider.token!,
                      orderId: orderRef,
                      phoneNumber: paymentPhone,
                      correspondent: _selectedPawaPayCorrespondent,
                    );

                _setCheckoutSubmitPhase(
                  _CheckoutSubmitPhase.waitingForConfirmation,
                );
                await Future<void>.delayed(
                  const Duration(milliseconds: 180),
                );
                _clearCheckoutSubmitState();
                if (!mounted) return;

                final data = result['data'] as Map<String, dynamic>? ?? {};
                final payment = data['payment'] as Map<String, dynamic>? ?? {};
                final paymentId =
                    payment['documentId'] as String? ??
                    payment['id']?.toString() ??
                    '';

                cartProvider.clearCart();
                context.pushReplacement(
                  '/customer/payment-pending',
                  extra: {
                    'order': backendOrder,
                    'paymentId': paymentId,
                    'phoneNumber': paymentPhone,
                  },
                );
                return;
              } catch (e) {
                _clearCheckoutSubmitState();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Order placed, but payment prompt failed. You can retry from your order details.',
                      ),
                      backgroundColor: AppColors.warning,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            }
          }
        }

        _clearCheckoutSubmitState();

        final orderForSuccess = hasValidBackendTotal ? backendOrder : localOrder;
        if (orderForSuccess != null && mounted) {
          cartProvider.clearCart();
          context.pushReplacement(
            '/customer/order-success',
            extra: orderForSuccess,
          );
        } else if (mounted) {
          // Prefer the backend's actual reason (e.g. service-area rejection,
          // missing GPS) over the local provider's generic message so the
          // user knows exactly what to fix.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                orderService.error ??
                    orderProvider.errorMessage ??
                    'Failed to place order',
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      _clearCheckoutSubmitState();
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
      bottomNavigationBar: IgnorePointer(
        ignoring: _isCheckoutSubmitting,
        child: const AppBottomNav(currentIndex: 3),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: _isCheckoutSubmitting
              ? null
              : () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              GoRouter.of(context).go('/customer/home');
            }
          },
        ),
        title: const Text('Checkout', style: AppTextStyles.displaySm),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.elegantBgGradient),
        child: SafeArea(
          child: Stack(
            children: [
              AbsorbPointer(
                absorbing: _isCheckoutSubmitting,
                child: WebLayoutWrapper(
                  addPadding: false,
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
                        // 1) Delivery address
                        _buildCollapsibleSection(
                          title: 'Delivery Address',
                          icon: Iconsax.location,
                          isExpanded: _addressExpanded,
                          summary: widget.isGuest
                              ? _guestAddressController.text.trim().isNotEmpty
                                    ? _guestAddressController.text.trim()
                                    : 'Add your address'
                              : _selectedAddress != null
                                    ? _selectedAddress!.fullAddress
                                    : 'No address selected',
                          onToggle: () => setState(
                            () => _addressExpanded = !_addressExpanded,
                          ),
                          child: widget.isGuest
                              ? _buildGuestAddressForm()
                              : (_selectedAddress == null
                                    ? (_showAddressForm
                                          ? _buildAuthAddressForm()
                                          : _buildAddAddressButton())
                                    : _buildAddressCard(authProvider)),
                        ),
                        const SizedBox(height: AppSizes.md),

                        // 2) Delivery slot
                        _buildCollapsibleSection(
                          title: 'Delivery Slot',
                          icon: Iconsax.timer_1,
                          isExpanded: _slotExpanded,
                          summary:
                              '${_slots[_selectedSlotIndex].label} · ${Formatters.formatCurrency(_slots[_selectedSlotIndex].fee.toDouble())}',
                          onToggle: () => setState(
                            () => _slotExpanded = !_slotExpanded,
                          ),
                          child: _buildDeliverySlotScroller(),
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
                                    PriceText(
                                      amount: item.totalPrice,
                                      showCurrencyCode: false,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),

                        // 3) Payment method
                        _buildCollapsibleSection(
                          title: 'Payment Method',
                          icon: Iconsax.card,
                          isExpanded: _paymentExpanded,
                          summary: _selectedPayment == PaymentMethod.cashOnDelivery
                              ? 'Pay rider on delivery'
                              : 'Pay with Mobile Money',
                          onToggle: () => setState(
                            () => _paymentExpanded = !_paymentExpanded,
                          ),
                          child: Column(
                            children: [
                              _buildMobileMoneyCard(
                                method: PaymentMethod.mobileMoney,
                                correspondent: 'MTN_MOMO_UGA',
                                label: 'MTN Mobile Money',
                                accent: const Color(0xFFFFCC00),
                                textColor: Colors.black,
                                badge: 'MTN',
                                prompt: 'You\'ll get a prompt to approve',
                                comingSoon: false,
                              ),
                              const SizedBox(height: AppSizes.sm),
                              _buildMobileMoneyCard(
                                method: PaymentMethod.mobileMoney,
                                correspondent: 'AIRTEL_OAPI_UGA',
                                label: 'Airtel Money',
                                accent: const Color(0xFFE40000),
                                textColor: Colors.white,
                                badge: 'Airtel',
                                prompt: 'You\'ll get a prompt to approve',
                                comingSoon: false,
                              ),
                              const SizedBox(height: AppSizes.sm),
                              if (_selectedPayment == PaymentMethod.mobileMoney) ...[
                                Container(
                                  padding: const EdgeInsets.all(AppSizes.sm),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                                    border: Border.all(color: AppColors.grey200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Number to charge',
                                        style: AppTextStyles.labelMedium,
                                      ),
                                      const SizedBox(height: AppSizes.xs),
                                      TextField(
                                        controller: _paymentPhoneController,
                                        keyboardType: TextInputType.phone,
                                        decoration: InputDecoration(
                                          prefixText: '+256 ',
                                          hintText: '7XXXXXXXX',
                                          helperText: _selectedPawaPayCorrespondent == 'AIRTEL_OAPI_UGA'
                                              ? 'Use an Airtel Money number for this option.'
                                              : 'Use an MTN Mobile Money number for this option.',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppSizes.radiusSm,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSizes.sm),
                              ],
                              _buildPaymentOption(PaymentMethod.cashOnDelivery),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),

                        // 4) Order summary
                        _buildCollapsibleSection(
                          title: 'Order Summary',
                          icon: Iconsax.receipt_2,
                          isExpanded: _summaryExpanded,
                          summary: 'Total · ${Formatters.formatCurrency(_checkoutDisplayTotal(cartProvider))}',
                          onToggle: () => setState(
                            () => _summaryExpanded = !_summaryExpanded,
                          ),
                          child: Column(
                            children: [
                              _buildSummaryRow('Subtotal', cartProvider.subtotal),
                              const SizedBox(height: AppSizes.sm),
                              _buildSummaryRow('Service Fee (5%)', cartProvider.serviceFee),
                              const SizedBox(height: AppSizes.sm),
                              _buildSummaryRow('Delivery Fee', _slots[_selectedSlotIndex].fee.toDouble()),
                              if (_estimatedPawaPayCharge(cartProvider.subtotal) > 0) ...[
                                const SizedBox(height: AppSizes.sm),
                                _buildSummaryRow(
                                  'PawaPay Charge',
                                  _estimatedPawaPayCharge(cartProvider.subtotal),
                                ),
                              ],
                              const SizedBox(height: AppSizes.sm),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () => setState(() => _promoExpanded = !_promoExpanded),
                                  child: Text(
                                    _promoExpanded ? 'Hide promo code' : 'Have a promo code?',
                                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
                                  ),
                                ),
                              ),
                              if (_promoExpanded)
                                TextField(
                                  controller: _promoController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter promo code',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: AppSizes.sm),
                              TextField(
                                controller: _riderNoteController,
                                minLines: 2,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: 'Note for rider: gate color, landmark, etc.',
                                  labelText: 'Note for rider',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                                  ),
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
                                _checkoutDisplayTotal(cartProvider),
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
                        _isCheckoutSubmitting
                            ? _buildCheckoutLoadingButton()
                            : CustomButton(
                                text: _primaryCheckoutCta(
                                  _checkoutDisplayTotal(cartProvider),
                                ),
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
              if (_isCheckoutSubmitting) _buildCheckoutLoadingOverlay(),
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

  Widget _buildCollapsibleSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required String summary,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: AppColors.primaryOrange),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTextStyles.h5),
                        if (!isExpanded)
                          Text(
                            summary,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  TextButton(onPressed: onToggle, child: Text(isExpanded ? 'Hide' : 'Change')),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.md,
                0,
                AppSizes.md,
                AppSizes.md,
              ),
              child: child,
            ),
        ],
      ),
    );
  }

  Widget _buildDeliverySlotScroller() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_slots.length, (index) {
          final slot = _slots[index];
          final selected = _selectedSlotIndex == index;
          return Padding(
            padding: EdgeInsets.only(right: index == _slots.length - 1 ? 0 : 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedSlotIndex = index),
              child: Container(
                width: 180,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primarySoft
                      : AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.grey300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.label,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    PriceText(amount: slot.fee.toDouble()),
                    if (slot.saveTag != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        slot.saveTag!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (slot.etaTag != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        slot.etaTag!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  String _primaryCheckoutCta(double total) {
    final amount = Formatters.formatCurrency(total);
    switch (_selectedPayment) {
      case PaymentMethod.mobileMoney:
        return 'Pay $amount with MoMo';
      case PaymentMethod.card:
        return 'Pay $amount with card';
      case PaymentMethod.cashOnDelivery:
        return 'Place order - Pay on delivery';
    }
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
            onPressed: () => _goToAddressSelection(announce: false),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  /// Navigate to the addresses screen in select mode. Used both when no
  /// address is selected yet (auto-redirect from build) and when the user
  /// taps "Change". The addresses screen returns here via the `return` query
  /// param with `&selectedAddress=<id>` so we can pre-select on rebuild.
  void _goToAddressSelection({bool announce = true}) {
    final returnRoute = Uri.encodeComponent('/customer/checkout');
    if (announce) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add or select a delivery address to continue.'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
    context.go('/customer/addresses?return=$returnRoute&select=true');
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
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _saveAddress,
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

  Widget _buildMobileMoneyCard({
    required PaymentMethod method,
    required String correspondent,
    required String label,
    required Color accent,
    required Color textColor,
    required String badge,
    required String prompt,
    bool comingSoon = false,
  }) {
    final isSelected =
        _selectedPayment == method && _selectedPawaPayCorrespondent == correspondent;
    return GestureDetector(
      onTap: comingSoon
          ? null
          : () => setState(() {
              _selectedPayment = method;
              _selectedPawaPayCorrespondent = correspondent;
            }),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.sm),
        margin: const EdgeInsets.only(bottom: 0),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryOrange.withValues(alpha: 0.1)
              : AppColors.lightGrey,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : AppColors.grey300,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: AppTextStyles.caption.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    comingSoon ? 'Coming soon' : prompt,
                    style: AppTextStyles.caption.copyWith(
                      color: comingSoon
                          ? AppColors.textSecondary
                          : AppColors.primary,
                      fontStyle: comingSoon ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (comingSoon)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  'Soon',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              )
            else if (isSelected)
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

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal ? AppTextStyles.labelMedium : AppTextStyles.bodySmall,
        ),
        PriceText(
          amount: amount,
          large: isTotal,
          amountColor: isTotal ? AppColors.textPrimary : AppColors.primary,
        ),
      ],
    );
  }
}

class _DeliverySlot {
  final String label;
  final int fee;
  final String? etaTag;
  final String? saveTag;

  const _DeliverySlot(this.label, this.fee, {this.etaTag, this.saveTag});
}
