import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:subbies/screens/shell_screen.dart';
import 'package:subbies/state/settings_controller.dart';
import 'package:subbies/theme/app_theme.dart';


class SubbiesApp extends StatelessWidget {
  const SubbiesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<SettingsController>().themeMode;

    return MaterialApp(
      title: 'Recurring',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const ShellScreen()
    );
  }
}