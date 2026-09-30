import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:recurring/screens/shell_screen.dart';
import 'package:recurring/state/settings_controller.dart';
import 'package:recurring/theme/app_theme.dart';


class RecurringApp extends StatelessWidget {
  const RecurringApp({super.key});

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