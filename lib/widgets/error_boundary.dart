import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_sizes.dart';

/// A reusable error boundary widget that catches errors during build
/// and shows a graceful fallback UI instead of the red error screen.
///
/// Errors are reported to Sentry automatically.
///
/// Usage:
/// ```dart
/// ErrorBoundary(
///   onRetry: () => setState(() {}),
///   child: MyWidget(),
/// )
/// ```
class ErrorBoundary extends StatefulWidget {
  final Widget child;

  /// Called when the user taps the "Try Again" button.
  /// Typically triggers a rebuild, e.g. `() => setState(() {})`.
  final VoidCallback? onRetry;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.onRetry,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;

  @override
  void didUpdateWidget(covariant ErrorBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset error state when child widget changes
    if (widget.child != oldWidget.child && _hasError) {
      setState(() {
        _hasError = false;
      });
    }
  }

  void _handleError(FlutterErrorDetails details) {
    // Report to Sentry
    Sentry.captureException(
      details.exception,
      stackTrace: details.stack,
    );

    if (mounted) {
      setState(() {
        _hasError = true;
      });
    }
  }

  void _retry() {
    setState(() {
      _hasError = false;
    });
    widget.onRetry?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _ErrorFallbackView(onRetry: _retry);
    }

    // Use a custom ErrorWidget.builder scoped to this subtree
    return _ErrorBoundaryScope(
      onError: _handleError,
      child: widget.child,
    );
  }
}

/// Internal widget that installs a local error handler for its subtree.
class _ErrorBoundaryScope extends StatefulWidget {
  final Widget child;
  final void Function(FlutterErrorDetails) onError;

  const _ErrorBoundaryScope({
    required this.child,
    required this.onError,
  });

  @override
  State<_ErrorBoundaryScope> createState() => _ErrorBoundaryScopeState();
}

class _ErrorBoundaryScopeState extends State<_ErrorBoundaryScope> {
  @override
  Widget build(BuildContext context) {
    // Wrap child in a Builder so we can catch errors in its subtree
    return _ErrorCatcher(
      onError: widget.onError,
      child: widget.child,
    );
  }
}

/// Uses ErrorWidget.builder override to catch build-phase errors.
class _ErrorCatcher extends StatelessWidget {
  final Widget child;
  final void Function(FlutterErrorDetails) onError;

  const _ErrorCatcher({
    required this.child,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    final previousErrorBuilder = ErrorWidget.builder;

    ErrorWidget.builder = (FlutterErrorDetails details) {
      // Schedule the error handling for after the current build frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onError(details);
      });

      // Restore the previous builder
      ErrorWidget.builder = previousErrorBuilder;

      // Return an empty container while the error state propagates
      return const SizedBox.shrink();
    };

    return child;
  }
}

/// The fallback UI shown when an error is caught.
class _ErrorFallbackView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorFallbackView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Title
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),

            // Subtitle
            Text(
              'An unexpected error occurred.\nPlease try again.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.lg),

            // Retry button
            SizedBox(
              width: 160,
              height: AppSizes.buttonHeightMd,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
