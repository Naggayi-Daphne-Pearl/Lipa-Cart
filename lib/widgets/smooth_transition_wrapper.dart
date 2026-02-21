import 'package:flutter/material.dart';

/// Wrapper widget to add smooth transitions to child widgets
class SmoothTransitionWrapper extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final TransitionType transitionType;

  const SmoothTransitionWrapper({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeInOutCubic,
    this.transitionType = TransitionType.slideFromRight,
  }) : super(key: key);

  @override
  State<SmoothTransitionWrapper> createState() => _SmoothTransitionWrapperState();
}

enum TransitionType {
  slideFromRight,
  slideFromBottom,
  fadeIn,
  scale,
}

class _SmoothTransitionWrapperState extends State<SmoothTransitionWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        switch (widget.transitionType) {
          case TransitionType.slideFromRight:
            return Transform.translate(
              offset: Offset(100 * (1 - _animation.value), 0),
              child: Opacity(
                opacity: _animation.value,
                child: child,
              ),
            );
          case TransitionType.slideFromBottom:
            return Transform.translate(
              offset: Offset(0, 50 * (1 - _animation.value)),
              child: Opacity(
                opacity: _animation.value,
                child: child,
              ),
            );
          case TransitionType.fadeIn:
            return Opacity(
              opacity: _animation.value,
              child: child,
            );
          case TransitionType.scale:
            return Transform.scale(
              scale: 0.9 + (0.1 * _animation.value),
              child: Opacity(
                opacity: _animation.value,
                child: child,
              ),
            );
        }
      },
      child: widget.child,
    );
  }
}
