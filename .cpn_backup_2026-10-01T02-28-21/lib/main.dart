import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:recurring/app.dart';
import 'package:recurring/data/settings_repository.dart';
import 'package:recurring/data/subscription_repository.dart';
import 'package:recurring/state/settings_controller.dart';
import 'package:recurring/state/subscriptions_controller.dart';



void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => SettingsController(SettingsRepository())..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => 
            SubscriptionsController(SubscriptionRepository())..load(),
        ),
      ],

      child: const RecurringApp(),
    )
  );
}