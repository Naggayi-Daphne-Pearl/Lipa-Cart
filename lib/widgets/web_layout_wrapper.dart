import 'package:flutter/material.dart';
import '../core/utils/responsive.dart';

/// A wrapper widget that ensures content looks good on web by constraining
/// max width and adding appropriate padding on larger screens
class WebLayoutWrapper extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final bool addPadding;

  const WebLayoutWrapper({
    super.key,
    required this.child,
    this.backgroundColor,
    this.addPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: context.maxContentWidth,
        ),
        child: addPadding
            ? Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.isMobile ? 0 : 16,
                ),
                child: child,
              )
            : child,
      ),
    );
  }
}

/// A grid widget that adapts to screen size - shows grid on web/tablet, list on mobile
class AdaptiveProductGrid extends StatelessWidget {
  final List<Widget> children;
  final bool forceList;
  final double spacing;

  const AdaptiveProductGrid({
    super.key,
    required this.children,
    this.forceList = false,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    // On mobile or when forced, show horizontal list
    if (context.isMobile || forceList) {
      return SizedBox(
        height: 240,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
          itemCount: children.length,
          separatorBuilder: (_, __) => SizedBox(width: spacing),
          itemBuilder: (context, index) => children[index],
        ),
      );
    }

    // On tablet/desktop, show grid
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: context.gridColumns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: 0.7,
        ),
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}
