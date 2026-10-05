// =============================================================================
// screens/demo_launcher.dart — WHAT /demo DOES
// =============================================================================
// Opening /demo switches on the demo, then moves on to the subscriptions
// list.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:subbies/services/account_sync.dart';

class DemoLauncher extends StatefulWidget {
  const DemoLauncher({super.key});

  @override
  State<DemoLauncher> createState() => _DemoLauncherState();
}

class _DemoLauncherState extends State<DemoLauncher> {
  @override
  void initState() {
    super.initState();
    // We can't navigate while Flutter is still building this screen's first
    // frame. addPostFrameCallback runs our code right AFTER that frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccountSync>().enterDemo();
      context.go('/subscriptions');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Visible for a split second at most.
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}