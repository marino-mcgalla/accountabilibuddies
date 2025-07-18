import 'package:flutter/material.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;

  const ResponsiveWrapper({
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get device screen size
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return MediaQuery(
      // Apply scaling to text and touch targets for small screens
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: isSmallScreen ? 1.0 : 1.0,
      ),
      child: child,
    );
  }
}
