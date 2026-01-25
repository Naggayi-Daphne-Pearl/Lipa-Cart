import 'package:flutter/material.dart';

/// Responsive breakpoints for different screen sizes
class Breakpoints {
  // Mobile breakpoint (phones)
  static const double mobile = 600;

  // Tablet breakpoint (tablets in portrait)
  static const double tablet = 900;

  // Desktop breakpoint (tablets in landscape, desktops)
  static const double desktop = 1200;

  // Large desktop breakpoint (large monitors)
  static const double largeDesktop = 1600;
}

/// Extension on BuildContext to check screen sizes
extension ResponsiveContext on BuildContext {
  /// Get current screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get current screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Check if screen is mobile size
  bool get isMobile => screenWidth < Breakpoints.mobile;

  /// Check if screen is tablet size
  bool get isTablet => screenWidth >= Breakpoints.mobile && screenWidth < Breakpoints.desktop;

  /// Check if screen is desktop size
  bool get isDesktop => screenWidth >= Breakpoints.desktop;

  /// Check if screen is large desktop size
  bool get isLargeDesktop => screenWidth >= Breakpoints.largeDesktop;

  /// Get responsive value based on screen size
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    if (isLargeDesktop && largeDesktop != null) return largeDesktop;
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  /// Get number of columns for grid based on screen size
  int get gridColumns {
    if (isLargeDesktop) return 6;
    if (isDesktop) return 4;
    if (isTablet) return 3;
    return 2;
  }

  /// Get horizontal padding based on screen size
  double get horizontalPadding {
    if (isLargeDesktop) return 80;
    if (isDesktop) return 60;
    if (isTablet) return 40;
    return 20;
  }

  /// Get max content width (prevents stretching on large screens)
  double get maxContentWidth {
    if (isLargeDesktop) return 1600;
    if (isDesktop) return 1400;
    if (isTablet) return 1024;
    return double.infinity;
  }
}

/// Widget that constrains content width on larger screens
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool centerContent;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.centerContent = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? context.maxContentWidth;

    return Container(
      padding: padding,
      alignment: centerContent ? Alignment.center : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: child,
      ),
    );
  }
}

/// Responsive grid that adapts columns based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final EdgeInsetsGeometry? padding;
  final double? childAspectRatio;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.mobileColumns = 2,
    this.tabletColumns = 3,
    this.desktopColumns = 4,
    this.padding,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final columns = context.responsive<int>(
      mobile: mobileColumns ?? 2,
      tablet: tabletColumns ?? 3,
      desktop: desktopColumns ?? 4,
      largeDesktop: 6,
    );

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: runSpacing,
          childAspectRatio: childAspectRatio ?? 0.75,
        ),
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

/// Responsive row that wraps children based on available space
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final WrapAlignment alignment;
  final WrapCrossAlignment crossAlignment;
  final EdgeInsetsGeometry? padding;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.spacing = 16,
    this.alignment = WrapAlignment.start,
    this.crossAlignment = WrapCrossAlignment.start,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        alignment: alignment,
        crossAxisAlignment: crossAlignment,
        children: children,
      ),
    );
  }
}

/// Layout builder that provides different layouts for different screen sizes
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop && desktop != null) {
      return desktop!(context);
    }

    if (context.isTablet && tablet != null) {
      return tablet!(context);
    }

    return mobile(context);
  }
}
