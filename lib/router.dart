// =============================================================================
// router.dart — EVERY LOCATION IN THE APP, IN ONE PLACE
// =============================================================================
//   /subscriptions               the list
//   /subscriptions/new           add a subscription
//   /subscriptions/:id           edit one (:id is a placeholder for its id)
//   /insights
//   /settings
//   /settings/sign-in
// =============================================================================

import 'package:go_router/go_router.dart';

import 'package:subbies/screens/app_shell.dart';
import 'package:subbies/screens/auth_screen.dart';
import 'package:subbies/screens/edit_subscription_screen.dart';
import 'package:subbies/screens/insights_screen.dart';
import 'package:subbies/screens/settings_screen.dart';
import 'package:subbies/screens/subscriptions_layout.dart';


final appRouter = GoRouter(
  initialLocation: '/subscriptions',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => 
        AppShell(navigationShell: navigationShell),
      branches: [
        
        // Tab 1: Subscriptions
        StatefulShellBranch(
          initialLocation: '/subscriptions',
          routes: [
            ShellRoute(
              builder: (context, state, child) => SubscriptionsLayout(
                selectedId: state.pathParameters['id'],
                child: child,
              ),
              routes: [
                GoRoute(
                  path: '/subscriptions',
                  builder: (context, state) => const SubscriptionsHome(),
                  routes: [
                    // ORDER MATTERS: 'new' must come before ':id', or
                    // "new" would be treated as a subscription's id.
                    GoRoute(
                      path: 'new',
                      builder: (context, state) =>
                          const EditSubscriptionScreen(),
                    ),
                    GoRoute(
                      path: ':id',
                      builder: (context, state) => SubscriptionDetail(
                        id: state.pathParameters['id']!,
                      ),
                    ),
                  ],
                ),
              ]
            ),
          ]
        ),

        // Tab 2: Insights
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/insights',
              builder: (context, state) => const InsightsScreen(),
            ),
          ],
        ),

        // Tab 3: Settings (with sign-in as a page inside it)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'sign-in',
                  builder: (context, state) => const AuthScreen(),
                ),
              ],
            ),
          ],
        ),
        
      ]
    )
  ]
);