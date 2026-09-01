import 'package:hive/hive.dart';

import '../models/trail.dart';

/// -----------------------------------------------------------------------
/// CP2 — Caching Your Trail List in Hive (Section 5 · ~20 min)
/// -----------------------------------------------------------------------
/// Goal: cache every fetched trail in a Hive box, so the list is
/// browsable even with zero signal.
///
/// STEPS:
///   1. In saveAll(), build a Map<String, dynamic> keyed by each trail's
///      id, with each value being trail.toJson(). Then call
///      await _box.putAll(map).
///   2. In getAll(), map every value in _box.values through
///      Trail.fromJson(Map<String, dynamic>.from(e)), then .toList().
///
/// DEFINITION OF DONE:
///   After fetching your trail list once, turn off wifi and relaunch —
///   TrailCache().getAll() should still show every trail.
/// -----------------------------------------------------------------------
/// QUICK CHALLENGE — Mark a Trail Completed (Section 6, after the break)
/// -----------------------------------------------------------------------
/// STEPS:
///   3. Implement update(): call _box.put(trail.id, trail.toJson()) to
///      overwrite just that one trail (or create it, if the id is new —
///      Hive's put() does both).
///
/// DEFINITION OF DONE:
///   Turn off wifi, tick a trail as completed, force-close and reopen the
///   app — the checkbox should remember its state with zero connection.
/// -----------------------------------------------------------------------
class TrailCache {
  Box get _box => Hive.box('trailsBox');

  Future<void> saveAll(List<Trail> trails) async {
    // TODO (CP2, step 1): build {id: toJson()} for every trail, then
    // await _box.putAll(map).
    throw UnimplementedError('TODO (CP2): implement saveAll()');
  }

  List<Trail> getAll() {
    // TODO (CP2, step 2): map _box.values into a List<Trail>.
    throw UnimplementedError('TODO (CP2): implement getAll()');
  }

  Future<void> update(Trail trail) async {
    // TODO (Quick Challenge, step 3): overwrite just this one trail.
    throw UnimplementedError('TODO (Quick Challenge): implement update()');
  }

  /// Already implemented — used by the advanced sync flow in
  /// TrailRepository.syncPendingTrails() to remove a trail's temporary
  /// local id once the server has assigned it a real one.
  Future<void> remove(String id) => _box.delete(id);

  Future<void> clear() => _box.clear();
}
