import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../services/payment_service.dart';

class PaymentPendingScreen extends StatefulWidget {
  final Order order;
  final String paymentId;
  final String phoneNumber;

  const PaymentPendingScreen({
    super.key,
    required this.order,
    required this.paymentId,
    required this.phoneNumber,
  });

  @override
  State<PaymentPendingScreen> createState() => _PaymentPendingScreenState();
}

class _PaymentPendingScreenState extends State<PaymentPendingScreen>
    with SingleTickerProviderStateMixin {
  Timer? _pollTimer;
  int _pollCount = 0;
  static const int _maxPolls = 24; // 24 * 5s = 120 seconds
  static const Duration _pollInterval = Duration(seconds: 5);

  bool _isPolling = false;
  bool _hasTimedOut = false;
  bool _hasFailed = false;
  bool _isRetrying = false;
  String _statusMessage = 'Waiting for payment approval...';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollCount = 0;
    _hasTimedOut = false;
    _hasFailed = false;
    _statusMessage = 'Waiting for payment approval...';
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    if (_isPolling || !mounted) return;
    setState(() => _isPolling = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;
      if (token == null) return;

      final result = await PaymentService.checkPaymentStatus(
        token: token,
        paymentId: widget.paymentId,
      );

      if (!mounted) return;

      final paymentStatus = result['paymentStatus'] as String;
      final orderStatus = result['orderStatus'] as String;

      if (paymentStatus == 'completed' ||
          orderStatus == 'payment_confirmed') {
        _pollTimer?.cancel();
        _navigateToSuccess();
        return;
      }

      if (paymentStatus == 'failed') {
        _pollTimer?.cancel();
        setState(() {
          _hasFailed = true;
          _statusMessage = 'Payment was not completed. You can try again.';
        });
        return;
      }

      _pollCount++;
      if (_pollCount >= _maxPolls) {
        _pollTimer?.cancel();
        setState(() {
          _hasTimedOut = true;
          _statusMessage =
              'Payment is taking longer than expected. You can retry or check your order later.';
        });
      }
    } catch (_) {
      // Network errors during polling are not fatal — keep trying
      _pollCount++;
      if (_pollCount >= _maxPolls) {
        _pollTimer?.cancel();
        setState(() {
          _hasTimedOut = true;
          _statusMessage =
              'Could not confirm payment. Check your order details for the latest status.';
        });
      }
    } finally {
      if (mounted) setState(() => _isPolling = false);
    }
  }

  void _navigateToSuccess() {
    if (!mounted) return;
    context.pushReplacement('/customer/order-success', extra: widget.order);
  }

  Future<void> _retryPayment() async {
    if (_isRetrying || !mounted) return;
    setState(() {
      _isRetrying = true;
      _hasFailed = false;
      _hasTimedOut = false;
      _statusMessage = 'Sending payment prompt...';
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;
      if (token == null) return;

      final orderRef = widget.order.documentId ?? widget.order.id;
      await PaymentService.initiateFlutterwaveMobileMoney(
        token: token,
        orderId: orderRef,
        phoneNumber: widget.phoneNumber,
      );

      if (!mounted) return;
      setState(() {
        _statusMessage = 'Waiting for payment approval...';
        _isRetrying = false;
      });
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRetrying = false;
        _hasFailed = true;
        _statusMessage = 'Could not send payment prompt. Please try again.';
      });
    }
  }

  String get _maskedPhone {
    final phone = widget.phoneNumber;
    if (phone.length < 6) return phone;
    // Show: +256 7XX XXX X89
    final visible = phone.substring(0, 7);
    final last = phone.substring(phone.length - 2);
    final masked = 'X' * (phone.length - 9);
    return '$visible $masked $last';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: AppSizes.screenPadding,
            child: Column(
              children: [
                const Spacer(flex: 1),
                _buildPhoneIcon(),
                const SizedBox(height: AppSizes.xl),
                _buildStatusSection(),
                const SizedBox(height: AppSizes.xl),
                _buildPaymentDetails(),
                const SizedBox(height: AppSizes.lg),
                if (!_hasFailed && !_hasTimedOut) _buildSteps(),
                const Spacer(flex: 2),
                _buildActions(),
                const SizedBox(height: AppSizes.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneIcon() {
    final bool showPulse = !_hasFailed && !_hasTimedOut;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: showPulse ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: _hasFailed
                  ? AppColors.errorSoft
                  : _hasTimedOut
                      ? AppColors.accentSoft
                      : AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _hasFailed
                  ? Iconsax.close_circle
                  : _hasTimedOut
                      ? Iconsax.timer
                      : Iconsax.mobile,
              size: 56,
              color: _hasFailed
                  ? AppColors.error
                  : _hasTimedOut
                      ? AppColors.accent
                      : AppColors.primary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusSection() {
    return Column(
      children: [
        Text(
          _hasFailed
              ? 'Payment Not Completed'
              : _hasTimedOut
                  ? 'Taking Longer Than Expected'
                  : 'Check Your Phone',
          style: AppTextStyles.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          _statusMessage,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPaymentDetails() {
    return Container(
      padding: AppSizes.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        children: [
          _detailRow('Amount', Formatters.formatCurrency(widget.order.total)),
          const SizedBox(height: AppSizes.sm),
          Divider(color: AppColors.grey100, height: 1),
          const SizedBox(height: AppSizes.sm),
          _detailRow('Phone', _maskedPhone),
          const SizedBox(height: AppSizes.sm),
          Divider(color: AppColors.grey100, height: 1),
          const SizedBox(height: AppSizes.sm),
          _detailRow('Method', 'Mobile Money'),
          if (widget.order.orderNumber.isNotEmpty) ...[
            const SizedBox(height: AppSizes.sm),
            Divider(color: AppColors.grey100, height: 1),
            const SizedBox(height: AppSizes.sm),
            _detailRow('Order', '#${widget.order.orderNumber}'),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        )),
        Text(
          value,
          style: label == 'Amount'
              ? AppTextStyles.priceMedium
              : AppTextStyles.labelMedium,
        ),
      ],
    );
  }

  Widget _buildSteps() {
    return Container(
      padding: AppSizes.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How to complete payment', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppSizes.sm),
          _stepRow(1, 'Check your phone for the payment prompt'),
          const SizedBox(height: AppSizes.xs),
          _stepRow(2, 'Enter your Mobile Money PIN'),
          const SizedBox(height: AppSizes.xs),
          _stepRow(3, 'Confirm the payment'),
        ],
      ),
    );
  }

  Widget _stepRow(int number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Text(text, style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textPrimary,
          )),
        ),
      ],
    );
  }

  Widget _buildActions() {
    if (_hasFailed || _hasTimedOut) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeightLg,
            child: ElevatedButton.icon(
              onPressed: _isRetrying ? null : _retryPayment,
              icon: _isRetrying
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(Iconsax.refresh, size: AppSizes.iconSm),
              label: Text(
                _isRetrying ? 'Sending...' : 'Retry Payment',
                style: AppTextStyles.buttonLarge,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeightLg,
            child: OutlinedButton(
              onPressed: () {
                context.go('/customer/orders');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: AppColors.grey200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
              ),
              child: Text('View My Orders', style: AppTextStyles.buttonLarge.copyWith(
                color: AppColors.textSecondary,
              )),
            ),
          ),
        ],
      );
    }

    // While waiting — just show a subtle cancel option
    return TextButton(
      onPressed: () {
        context.go('/customer/orders');
      },
      child: Text(
        'I\'ll check later',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
