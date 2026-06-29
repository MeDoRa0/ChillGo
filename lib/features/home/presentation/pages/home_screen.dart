import 'package:flutter/material.dart';
import 'package:chillgo/core/presentation/widgets/responsive_layout.dart';
import '../widgets/home_desktop_layout.dart';
import '../widgets/home_mobile_layout.dart';
import '../widgets/home_tablet_layout.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onTriggerCrash;

  const HomeScreen({super.key, this.onTriggerCrash});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: HomeMobileLayout(onTriggerCrash: onTriggerCrash),
      tabletBody: HomeTabletLayout(onTriggerCrash: onTriggerCrash),
      desktopBody: HomeDesktopLayout(onTriggerCrash: onTriggerCrash),
    );
  }
}
