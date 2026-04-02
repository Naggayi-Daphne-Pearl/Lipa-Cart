import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class ConnectivityBanner extends StatefulWidget {
  final Widget child;
  const ConnectivityBanner({super.key, required this.child});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (mounted && offline != _isOffline) {
        setState(() => _isOffline = offline);
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isOffline)
          MaterialBanner(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            backgroundColor: AppColors.warning.withValues(alpha: 0.15),
            content: Text(
              'You\'re offline — some features may not work',
              style: AppTextStyles.caption.copyWith(color: AppColors.warning, fontWeight: FontWeight.w500),
            ),
            leading: const Icon(Icons.wifi_off, color: AppColors.warning, size: 20),
            actions: const [SizedBox.shrink()],
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
