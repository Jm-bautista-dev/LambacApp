import 'package:shared_preferences/shared_preferences.dart';

/// Durable key/value store backing the offline order & sales ledger.
///
/// The Lambac mock "backend" keeps orders and recorded sales in memory. Without
/// durable storage, a page refresh / app restart rebuilds the ledger from seed
/// data and a completed order reappears as NEW. This store makes the ledger the
/// persisted source of truth. It is a no-op until [init] is called (tests never
/// call it, so test isolation is unchanged).
class MockLedgerStore {
  MockLedgerStore._();

  static SharedPreferences? _prefs;

  static const String ordersKey = 'lambac_ledger_orders_v1';
  static const String salesKey = 'lambac_ledger_sales_v1';
  static const String usersKey = 'lambac_ledger_users_v1';

  /// Must be awaited in main() before any datasource is first used
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool get isEnabled => _prefs != null;

  static String? read(String key) => _prefs?.getString(key);

  static void write(String key, String value) {
    _prefs?.setString(key, value);
  }
}
