import 'package:shared_preferences/shared_preferences.dart';

/// -----------------------------------------------------------------------
/// CP1 — Remembering a Filter Preference (Section 3 · ~15 min)
/// -----------------------------------------------------------------------
/// Goal: remember whether the user wants to see completed trails, so the
/// filter survives a full app restart.
///
/// STEPS:
///   1. In getShowCompleted(), get a SharedPreferences instance and
///      return prefs.getBool(_kShowCompletedKey) ?? true.
///      (default to true — showing everything — until the user changes it)
///   2. In setShowCompleted(), get a SharedPreferences instance and call
///      prefs.setBool(_kShowCompletedKey, value).
///
/// DEFINITION OF DONE:
///   Force-close the app after toggling the "Show completed" switch on
///   the home screen. Reopen it — the switch should already be in the
///   right position, with no network call involved.
/// -----------------------------------------------------------------------
const _kShowCompletedKey = 'showCompleted';

class TrailPreferences {
  Future<bool> getShowCompleted() async {
    // TODO (CP1, step 1): read the saved bool, defaulting to true.
    throw UnimplementedError('TODO (CP1): implement getShowCompleted()');
  }

  Future<void> setShowCompleted(bool value) async {
    // TODO (CP1, step 2): save the given bool.
    throw UnimplementedError('TODO (CP1): implement setShowCompleted()');
  }
}
