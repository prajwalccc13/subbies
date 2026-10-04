// flutter
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:flutter_web_plugins/url_strategy.dart';

// third party packages
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:firebase_core/firebase_core.dart'; 
import 'package:provider/provider.dart';

// mains
import 'package:subbies/app.dart';
import 'package:subbies/firebase_options.dart';

// data
import 'package:subbies/data/firestore_subscription_repository.dart'; 
import 'package:subbies/data/local_subscription_repository.dart';
import 'package:subbies/data/settings_repository.dart';

// Services
import 'package:subbies/services/account_sync.dart'; 
import 'package:subbies/services/local_notification_scheduler.dart';
import 'package:subbies/services/noop_reminder_scheduler.dart'; 
import 'package:subbies/services/reminder_scheduler.dart';

// state
import 'package:subbies/state/auth_controller.dart'; 
import 'package:subbies/state/reminders_controller.dart';
import 'package:subbies/state/settings_controller.dart';
import 'package:subbies/state/subscriptions_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  usePathUrlStrategy();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final localRepository = LocalSubscriptionRepository();

  final ReminderScheduler scheduler =
      kIsWeb ? const NoopReminderScheduler() : LocalNotificationScheduler();

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
            scheduler: scheduler,
            settings: SettingsRepository(),
            subscriptions: context.read<SubscriptionsController>(),
          )..load(),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) {
            final auth = AuthController(
              FirebaseAuth.instance,
              deleteUserData: (userId) async {
                final cloud = FirestoreSubscriptionRepository(userId: userId);
                for (final subscription in await cloud.fetchAll()) {
                  await cloud.delete(subscription.id);
                }
              },
            );
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