import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:trail_log_starter/storage/trail_cache.dart';

import '../models/trail.dart';
import '../network/trail_api_service.dart';

/// One front door to the network for the whole app. Screens call this
/// class only — never TrailApiService or TrailCache directly.
class TrailRepository {
  final TrailApiService _api = TrailApiService.instance;
  final TrailCache _cache = TrailCache();

  /// -----------------------------------------------------------------------
  /// CP3 — Building a Cache-First Repository (Section 8 · ~20 min)
  /// -----------------------------------------------------------------------
  /// Goal: fetch every trail, but show cached trails instantly first —
  /// the "stale-while-revalidate" pattern.
  ///
  /// STEPS:
  ///   1. Read the cache: final cached = _cache.getAll();
  ///   2. If it's not empty, yield it immediately: if (cached.isNotEmpty)
  ///      yield cached;
  ///   3. Inside a try block, await _api.getTrails(), save the result
  ///      with await _cache.saveAll(fresh), then yield fresh.
  ///   4. In the catch block: if the cache was empty, rethrow (there's
  ///      nothing to fall back on). Otherwise, do nothing — keep showing
  ///      the cached trails already yielded in step 2.
  ///
  /// DEFINITION OF DONE:
  ///   Use a StreamBuilder in the Trail List screen. On a warm cache,
  ///   trails should render instantly — before the network call even
  ///   resolves. Turn off wifi with an empty cache and you should see a
  ///   real NoConnectionException surface to the UI.
  /// -----------------------------------------------------------------------
  Stream<List<Trail>> watchTrails() async* {
    // TODO (CP3): implement the 4 steps above.
    throw UnimplementedError('TODO (CP3): implement watchTrails()');
  }

  /// -----------------------------------------------------------------------
  /// CP4 — Wiring Up the Full Sync Flow (Section 8 · ~20 min)
  /// -----------------------------------------------------------------------
  /// Goal: adding a trail should work online AND offline, without ever
  /// losing the write.
  ///
  /// STEPS:
  ///   1. Check connectivity: final isOnline = await _isOnline();
  ///      (already implemented for you below)
  ///   2. If isOnline, call await _api.addTrail(trail) to get the saved
  ///      version back (with its real id + createdAt), then save it to
  ///      the cache with await _cache.update(saved).
  ///   3. If not online, save the trail to the cache immediately with
  ///      trail.copyWith(pendingSync: true) so the UI feels instant and
  ///      the row is clearly marked as not-yet-synced.
  ///
  /// DEFINITION OF DONE:
  ///   Turn on airplane mode, add a new trail, turn wifi back on. Within
  ///   a couple seconds it should sync automatically — see
  ///   syncPendingTrails() below, which is already wired up for you.
  /// -----------------------------------------------------------------------
  Future<void> addTrail(Trail trail) async {
    // TODO (CP4): implement steps 2–3 above using the isOnline flag.
    throw UnimplementedError('TODO (CP4): implement addTrail()');
  }

  /// -----------------------------------------------------------------------
  /// Advanced (already implemented) — Automatic Sync on Reconnect
  /// -----------------------------------------------------------------------
  /// This goes one step further than the lecture's CP4: instead of only
  /// syncing on the next manual pull-to-refresh, the screen listens for
  /// connectivity changes and calls this whenever the device comes back
  /// online. It finds every trail still marked pendingSync, resubmits
  /// it, and — critically — removes the old temporary local id once the
  /// server has assigned a real one, so you don't end up with the same
  /// trail twice under two different ids.
  ///
  /// Nothing to implement here. Read it once CP4 is done — it's built
  /// entirely out of pieces you just wrote.
  /// -----------------------------------------------------------------------
  Future<int> syncPendingTrails() async {
    final isOnline = await _isOnline();
    if (!isOnline) return 0;

    final pending = _cache.getAll().where((t) => t.pendingSync).toList();
    var syncedCount = 0;

    for (final trail in pending) {
      try {
        final saved = await _api.addTrail(trail);
        await _cache.remove(trail.id); // drop the old local-xxx entry
        await _cache.update(saved); // add it back under the real server id
        syncedCount++;
      } catch (_) {
        // Leave it pending — we'll try again on the next reconnect.
      }
    }
    return syncedCount;
  }

  /// Already implemented — checks the network interface, not whether
  /// the internet actually works. Used by CP4 and by syncPendingTrails().
  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
