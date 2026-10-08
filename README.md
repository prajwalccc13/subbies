# Subbies

A subscription tracker that tells you what you're paying for, what renews next, and when a free trial is about to turn into a charge.

**[Try the live demo](https://subbies-app.web.app/demo)** (no account needed, sample data resets on refresh)

Built with Flutter for Android, iOS and the web.


<!-- | --- | --- |
| ![Subbies on a laptop](docs/screenshots/desktop.png) | ![Subbies on a phone](docs/screenshots/phone.png) | -->

## What it does

- Tracks weekly, monthly and yearly subscriptions, and works out when each one renews next, including month-end dates like the 31st.
- Free trials get a countdown, and an alert appears a week before the first charge so there's time to cancel.
- Paused subscriptions stay in the list but drop out of the totals.
- Sends a reminder the day before a renewal or trial end (Android and iOS).
- Works without an account. Signing in backs everything up and syncs it across devices, and anything added before signing in moves into the account.
- Quick add: type "spo" and it suggests Spotify with its usual price, category and billing cycle.
- Adapts to the screen: bottom tabs on phones, a side rail on tablets, and a sidebar with list and details side by side on desktop.
- Light and dark themes.

## Stack

Flutter and Dart 3, with `provider` for state and `go_router` for navigation. Firebase handles sign-in (Auth), sync (Cloud Firestore) and web hosting. Signed-out data is stored on the device with `shared_preferences`, and reminders use `flutter_local_notifications`.

## How it's put together

```
lib/
  models/     Plain Dart: the Subscription model and all date math
  data/       Storage behind one interface: local, Firestore, in-memory
  services/   Deciding which data source is active, planning reminders
  state/      ChangeNotifier controllers the UI listens to
  screens/    Pages, plus the adaptive shell and router
  widgets/    Reusable pieces like the subscription row
```

The app only ever talks to a `SubscriptionRepository` interface. There are three implementations: device storage for signed-out use, Firestore for accounts, and an in-memory one that powers the demo and the tests. `AccountSync` is the single place that decides which one is active, so screens don't know or care where the data comes from.

## Decisions 

**Money is stored as whole cents.** Floating-point numbers can't represent most prices exactly, so `9.99` is stored as `999` and only formatted at the last moment.

**Calculations run on the device.** Totals, renewal dates and reminders are computed from the user's own small list, so doing it locally makes them instant, keeps them working offline, and keeps the data private. Anything that has to be trusted, like who can read which data, is enforced on the server by Firestore security rules.

**Old data keeps loading.** New fields (trials, pausing, brand colors) are optional with safe defaults, and there are tests that load data saved by earlier versions.

**Moving data into an account is safe to retry.** Uploads use each subscription's own id, so an interrupted sign-in never creates duplicates, and the device copy is deleted only after every upload succeeds.

**Reminders are planned separately from being scheduled.** Deciding which reminders should exist is plain Dart with unit tests. A thin layer passes the result to the notification plugin, and on the web a do-nothing version takes its place.

**The demo never goes stale.** Sample dates are calculated from today ("renews in 3 days"), so the demo looks right whenever it's opened.

## Running it locally

You'll need the Flutter SDK and a Firebase project of your own with Email/Password sign-in and Firestore enabled.

```bash
git clone "https://github.com/prajwalccc13/subbies"
cd subbies
flutter pub get
flutterfire configure   # connects the app to your Firebase project
flutter run             # or: flutter run -d chrome
```

Firestore rules only allow each user to access their own data:

```
match /users/{userId}/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

## Tests

```bash
flutter test
```

Covers the date and money logic, backward compatibility with old saved data, the controllers (using fake repositories and a fixed clock), account switching and data migration, reminder planning, the service catalog, the demo data and the responsive layout rules.
