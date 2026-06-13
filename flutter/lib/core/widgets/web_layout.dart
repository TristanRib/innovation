import 'package:flutter/material.dart';

const double kWebMaxWidth = 780.0;

class WebLayout extends StatelessWidget {
  final Widget child;
  const WebLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kWebMaxWidth),
        child: child,
      ),
    );
  }
}
