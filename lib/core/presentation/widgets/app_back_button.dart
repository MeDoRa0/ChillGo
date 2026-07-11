import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBackButton extends StatelessWidget {
  final String fallbackRoute;

  const AppBackButton({super.key, this.fallbackRoute = '/'});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(fallbackRoute);
        }
      },
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }
}
