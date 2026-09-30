import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:subbies/app.dart';
import 'package:subbies/data/settings_repository.dart';
import 'package:subbies/data/subscription_repository.dart';
import 'package:subbies/state/settings_controller.dart';
import 'package:subbies/state/subscriptions_controller.dart';



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