// =============================================================================
// test/service_catalog_test.dart — DO SUGGESTIONS MAKE SENSE?
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:subbies/data/service_catalog.dart';

void main() {
  List<String> names(String query) =>
      searchCatalog(query).map((s) => s.name).toList();

  test('names that start with the text come first', () {
    expect(names('net').first, 'Netflix');
  });

  test('also finds words inside names', () {
    expect(names('music'), containsAll(['Apple Music', 'YouTube Music']));
  });

  test('ignores capital letters and extra spaces', () {
    expect(names('  SPOT ').first, 'Spotify');
  });

  test('empty text gives no suggestions', () {
    expect(searchCatalog(''), isEmpty);
  });

  test('never shows more than the limit', () {
    expect(searchCatalog('a').length, lessThanOrEqualTo(6));
  });

  test('every service name is unique', () {
    // A Set drops duplicates, so the sizes match only if there are none.
    final all = serviceCatalog.map((s) => s.name).toList();
    expect(all.toSet().length, all.length);
  });
}