import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_text_styles.dart';

/// Floating WhatsApp support button pinned to the bottom-left.
/// Small and non-intrusive — just a circle icon with a tooltip.
class WhatsAppSupportButton extends StatefulWidget {
  final String phoneNumber;
  final String? message;

  const WhatsAppSupportButton({
    super.key,
    this.phoneNumber = '256700000000', // Replace with real support number
    this.message = 'Hello! I need help with my LipaCart order.',
  });

  @override
  State<WhatsAppSupportButton> createState() => _WhatsAppSupportButtonState();
}

class _WhatsAppSupportButtonState extends State<WhatsAppSupportButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp() async {
    final encoded = Uri.encodeComponent(widget.message ?? '');
    final uri = Uri.parse(
      'https://wa.me/${widget.phoneNumber}?text=$encoded',
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      setState(() => _expanded = !_expanded);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 90,
      left: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_expanded)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need help?',
                    style: AppTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Chat with us on WhatsApp',
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF25D366),
                    ),
                  ),
                ],
              ),
            ),
          GestureDetector(
            onTap: _openWhatsApp,
            onLongPress: () => setState(() => _expanded = !_expanded),
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF25D366).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: _WhatsAppIcon(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple WhatsApp SVG-like icon drawn with CustomPaint.
class _WhatsAppIcon extends StatelessWidget {
  const _WhatsAppIcon();

  @override
  Widget build(BuildContext context) {
    // Use a text icon as fallback since wa icon not in iconsax
    return const Text(
      'W',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 22,
      ),
    );
  }
}
