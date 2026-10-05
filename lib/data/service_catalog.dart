// =============================================================================
// data/service_catalog.dart — POPULAR SERVICES FOR QUICK ADD
// =============================================================================
// Type "spo" and Subbies suggests Spotify, then fills in its category,
// usual price, billing cycle and brand color.
//
// Prices are typical US prices (around 2026). They change often, so they're
// only a starting point: the user can always edit them.
// We use brand NAMES and COLORS to help recognition, never logos.
// =============================================================================

import 'package:subbies/models/subscription.dart';

class CatalogService {
  const CatalogService(
    this.name,
    this.category,
    this.typicalPriceCents,
    this.cycle,
    this.brandColor,
  );

  final String name;
  final SubscriptionCategory category;
  final int typicalPriceCents;
  final BillingCycle cycle;
  final int brandColor; // 0xAARRGGBB, same format as Color(...)
}

// Shorter names, so the list below stays readable.
const _ent = SubscriptionCategory.entertainment;
const _music = SubscriptionCategory.music;
const _work = SubscriptionCategory.productivity;
const _util = SubscriptionCategory.utilities;
const _health = SubscriptionCategory.health;
const _other = SubscriptionCategory.other;
const _mo = BillingCycle.monthly;
const _yr = BillingCycle.yearly;

const serviceCatalog = [
  // Video and games
  CatalogService('Netflix', _ent, 1549, _mo, 0xFFE50914),
  CatalogService('Disney+', _ent, 1399, _mo, 0xFF113CCF),
  CatalogService('Max', _ent, 1699, _mo, 0xFF5822B4),
  CatalogService('Hulu', _ent, 999, _mo, 0xFF13A35A),
  CatalogService('Prime Video', _ent, 899, _mo, 0xFF00A8E1),
  CatalogService('Apple TV+', _ent, 999, _mo, 0xFF2C2C2E),
  CatalogService('YouTube Premium', _ent, 1399, _mo, 0xFFE62117),
  CatalogService('Crunchyroll', _ent, 799, _mo, 0xFFF47521),
  CatalogService('Paramount+', _ent, 799, _mo, 0xFF0064FF),
  CatalogService('Xbox Game Pass', _ent, 1699, _mo, 0xFF107C10),
  CatalogService('PlayStation Plus', _ent, 7999, _yr, 0xFF0070D1),
  CatalogService('Nintendo Switch Online', _ent, 1999, _yr, 0xFFE60012),

  // Music and audio
  CatalogService('Spotify', _music, 1199, _mo, 0xFF1AA34A),
  CatalogService('Apple Music', _music, 1099, _mo, 0xFFFA243C),
  CatalogService('YouTube Music', _music, 1099, _mo, 0xFFCC1F1F),
  CatalogService('Tidal', _music, 1099, _mo, 0xFF1F1F1F),
  CatalogService('Deezer', _music, 1199, _mo, 0xFFA238FF),
  CatalogService('Audible', _music, 1495, _mo, 0xFFE8890C),

  // Work and learning
  CatalogService('ChatGPT Plus', _work, 2000, _mo, 0xFF10A37F),
  CatalogService('Claude Pro', _work, 2000, _mo, 0xFFC96442),
  CatalogService('Notion', _work, 1000, _mo, 0xFF2F2F2F),
  CatalogService('Microsoft 365', _work, 9999, _yr, 0xFFD83B01),
  CatalogService('Google One', _work, 199, _mo, 0xFF4285F4),
  CatalogService('Dropbox', _work, 1199, _mo, 0xFF0061FF),
  CatalogService('Adobe Creative Cloud', _work, 5999, _mo, 0xFFDA1F26),
  CatalogService('Canva Pro', _work, 11999, _yr, 0xFF00A3AD),
  CatalogService('GitHub Copilot', _work, 1000, _mo, 0xFF24292F),
  CatalogService('1Password', _work, 299, _mo, 0xFF0572EC),
  CatalogService('Duolingo Super', _work, 8399, _yr, 0xFF4CAF00),

  // Utilities
  CatalogService('iCloud+', _util, 299, _mo, 0xFF3693F3),
  CatalogService('NordVPN', _util, 1299, _mo, 0xFF4687FF),

  // Health and fitness
  CatalogService('Strava', _health, 1199, _mo, 0xFFFC4C02),
  CatalogService('Peloton App', _health, 1299, _mo, 0xFF181A1D),
  CatalogService('Headspace', _health, 1299, _mo, 0xFFF47D31),
  CatalogService('Calm', _health, 6999, _yr, 0xFF3A7BD5),

  // Everyday
  CatalogService('Amazon Prime', _other, 1499, _mo, 0xFFE88A00),
  CatalogService('Uber One', _other, 999, _mo, 0xFF1F1F1F),
  CatalogService('DoorDash DashPass', _other, 999, _mo, 0xFFFF3008),
];

/// Services matching what the user typed, best matches first:
/// names that START with the text come before names that merely CONTAIN it.
/// So "music" finds "Apple Music", but "a" puts "Amazon Prime" before "Max".
List<CatalogService> searchCatalog(String query, {int limit = 6}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];

  final startsWith = <CatalogService>[];
  final contains = <CatalogService>[];
  for (final service in serviceCatalog) {
    final name = service.name.toLowerCase();
    if (name.startsWith(q)) {
      startsWith.add(service);
    } else if (name.contains(q)) {
      contains.add(service);
    }
  }
  return [...startsWith, ...contains].take(limit).toList();
}