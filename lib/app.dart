import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:subbies/router.dart';
import 'package:subbies/state/settings_controller.dart';
import 'package:subbies/theme/app_theme.dart';


class SubbiesApp extends StatelessWidget {
  const SubbiesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<SettingsController>().themeMode;

    return MaterialApp.router(
      title: 'Subbies',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}