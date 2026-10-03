

import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:firebase_core/firebase_core.dart'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:subbies/app.dart';
import 'package:subbies/data/firestore_subscription_repository.dart'; 
import 'package:subbies/data/local_subscription_repository.dart';
import 'package:subbies/data/settings_repository.dart';
import 'package:subbies/firebase_options.dart'; 
import 'package:subbies/services/account_sync.dart'; 
import 'package:subbies/services/local_notification_scheduler.dart';
import 'package:subbies/state/auth_controller.dart'; 
import 'package:subbies/state/reminders_controller.dart';
import 'package:subbies/state/settings_controller.dart';
import 'package:subbies/state/subscriptions_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final localRepository = LocalSubscriptionRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => SettingsController(SettingsRepository())..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => SubscriptionsController(localRepository),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) => RemindersController(
            scheduler: LocalNotificationScheduler(),
            settings: SettingsRepository(),
            subscriptions: context.read<SubscriptionsController>(),
          )..load(),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) {
            final auth = AuthController(FirebaseAuth.instance);
            final sync = AccountSync(
              subscriptions: context.read<SubscriptionsController>(),
              localRepository: localRepository,
              cloudRepositoryFor: (userId) =>
                  FirestoreSubscriptionRepository(userId: userId),
            );
            auth.addListener(() => sync.handleUserChanged(auth.userId));
            return auth;
          },
        ),
      ],
      child: const SubbiesApp(), 
    ),
  );
}