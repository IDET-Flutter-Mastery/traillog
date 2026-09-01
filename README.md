# TrailLog — Live-Coding Starter 🥾🧭

A tiny offline-first hiking trail tracker, built to accompany the
**Local Storage & Persistence** lecture: SharedPreferences, Hive,
offline-first strategy, caching, and syncing local + remote data.

**No external services, no signup, nothing to configure.** The "server"
is a small Dart class that lives inside the app itself — see
[Why is the backend fake?](#why-is-the-backend-fake) below if you're
wondering why.

By the end of the four checkpoints below, TrailLog will:
- Remember a filter setting across restarts (SharedPreferences)
- Cache every trail locally so the list works with zero signal (Hive)
- Show cached trails instantly, then quietly refresh from the network
- Let you add a trail while offline and have it **sync automatically**
  the moment you're back online — no manual refresh required

Comes with two custom illustrations (a mountain-trail banner and a
compass empty-state) plus real photo thumbnails per trail, loaded from
the network.

---

## Screenshots

| Trail List | Empty State |
| :---: | :---: |
| <img width="493" height="940" alt="trail_list_screen" src="https://github.com/user-attachments/assets/c648d7a8-baf4-44bd-aa97-57fadaaf495b" /> | <img width="496" height="940" alt="empty_state" src="https://github.com/user-attachments/assets/4bb2a56c-98ef-4fd7-9023-e264f35aa5ff" /> |
---

## Setup

There's no account to create and no URL to paste anywhere. Just:

```
flutter pub get
flutter run
```

You should land on the TrailLog home screen with three starter trails
already loaded (Eagle Ridge, Blue River Loop, Sunset Overlook) — those
live inside `TrailApiService` and stand in for "the server." The list
will show an error until CP2 and CP3 are done — that's expected, keep
going!

## Project structure

```
lib/
 ├── main.dart                       (done — opens Hive, applies AppTheme, runs the app)
 ├── theme/
 │    ├── app_colors.dart            (done — the pastel palette from the slides)
 │    └── app_theme.dart             (done — ThemeData using the "National Park" font)
 ├── models/
 │    └── trail.dart                 (done — the shared data shape)
 ├── network/
 │    └── trail_api_service.dart     (done — a self-contained fake backend)
 ├── storage/
 │    ├── trail_preferences.dart     ← CP1
 │    └── trail_cache.dart           ← CP2, Quick Challenge
 ├── repositories/
 │    └── trail_repository.dart      ← CP3, CP4 (+ an advanced feature, already done)
 └── screens/
      └── trail_list_screen.dart     (done — the UI; calls into your TODOs)

assets/images/
 ├── trail_hero.png                  the mountain banner on the home screen
 └── empty_state.png                 shown when the trail list is empty
```

Every `// TODO (CPx)` comment sits exactly where the corresponding code
goes, with the exact steps written above it. Work in order — CP4 assumes
CP3 is done, and the Quick Challenge assumes CP2 is done.

---

## CP1 — Remembering a Filter Preference
**File:** `lib/storage/trail_preferences.dart` · **~15 min**

**Goal:** remember whether the user wants to see completed trails, so
the filter survives a full app restart.

### Steps
1. In `getShowCompleted()`, get a `SharedPreferences` instance and
   return the saved bool, defaulting to `true`:
   ```dart
   final prefs = await SharedPreferences.getInstance();
   return prefs.getBool(_kShowCompletedKey) ?? true;
   ```
2. In `setShowCompleted()`, get a `SharedPreferences` instance and save
   the value:
   ```dart
   final prefs = await SharedPreferences.getInstance();
   await prefs.setBool(_kShowCompletedKey, value);
   ```

### Definition of done
Toggle the **"Show completed"** switch in the app bar, force-close the
app, and reopen it. The switch should already be in the position you
left it — no network call involved.

---

## CP2 — Caching Your Trail List in Hive
**File:** `lib/storage/trail_cache.dart` · **~20 min**

**Goal:** cache every fetched trail in a Hive box, so the list is
browsable even with zero signal.

### Steps
1. In `saveAll()`, build a map keyed by each trail's `id`, then write it
   all at once:
   ```dart
   final map = {for (final t in trails) t.id: t.toJson()};
   await _box.putAll(map);
   ```
2. In `getAll()`, turn every cached value back into a `Trail`:
   ```dart
   return _box.values
       .map((e) => Trail.fromJson(Map<String, dynamic>.from(e)))
       .toList();
   ```

### Definition of done
Once CP3 is also done and you've loaded the list at least once, turn off
wifi and relaunch — `TrailCache().getAll()` should still return every
trail.

---

## ★ Quick Challenge — Mark a Trail Completed
**File:** `lib/storage/trail_cache.dart` · **~10 min** (after the break)

**Goal:** let a checkbox update just one trail, instantly, with zero
network involved.

### Steps
3. Implement `update()` — overwrite just that one entry:
   ```dart
   Future<void> update(Trail trail) async {
     await _box.put(trail.id, trail.toJson());
   }
   ```

### Definition of done
Turn off wifi, tick a trail as completed, force-close and reopen the
app — the checkbox should remember its state with zero connection.

---

## CP3 — Building a Cache-First Repository
**File:** `lib/repositories/trail_repository.dart` · **~20 min**

**Goal:** fetch every trail, but show cached trails instantly first —
the "stale-while-revalidate" pattern.

### Steps
1. Read the cache: `final cached = _cache.getAll();`
2. If it's not empty, yield it immediately:
   ```dart
   if (cached.isNotEmpty) yield cached;
   ```
3. Inside a `try` block, fetch fresh data, cache it, and yield it:
   ```dart
   final fresh = await _api.getTrails();
   await _cache.saveAll(fresh);
   yield fresh;
   ```
4. In the `catch` block: if the cache was empty, `rethrow` (nothing to
   fall back on). Otherwise, do nothing — the cached trails from step 2
   are already on screen.

### Full shape
```dart
Stream<List<Trail>> watchTrails() async* {
  final cached = _cache.getAll();
  if (cached.isNotEmpty) yield cached;

  try {
    final fresh = await _api.getTrails();
    await _cache.saveAll(fresh);
    yield fresh;
  } catch (e) {
    if (cached.isEmpty) rethrow;
    // otherwise: keep showing cached trails
  }
}
```

### Definition of done
On a warm cache, the trail list should render instantly — before the
network call even resolves. On a cold cache with wifi off, you should
see a real `NoConnectionException` surface in the UI (that's
`TrailApiService` behaving like a real backend that genuinely failed).

---

## CP4 — Wiring Up the Full Sync Flow
**File:** `lib/repositories/trail_repository.dart` · **~20 min**

**Goal:** adding a trail should work online AND offline, without ever
losing the write.

### Steps
1. Connectivity checking is already implemented for you
   (`_isOnline()` at the bottom of the file).
2. If online, save it to the server first, then cache the *server's*
   version (it now has a real `id` and `createdAt`):
   ```dart
   final saved = await _api.addTrail(trail);
   await _cache.update(saved);
   ```
3. If offline, cache it immediately so the UI feels instant, flagged as
   not-yet-synced:
   ```dart
   await _cache.update(trail.copyWith(pendingSync: true));
   ```

### Full shape
```dart
Future<void> addTrail(Trail trail) async {
  final isOnline = await _isOnline();

  if (isOnline) {
    final saved = await _api.addTrail(trail);
    await _cache.update(saved);
  } else {
    await _cache.update(trail.copyWith(pendingSync: true));
  }
}
```

### Definition of done
Turn on airplane mode, tap **+** and add a new trail — it should appear
immediately, highlighted with a "Not synced yet" label. Turn wifi back
on and **wait a couple seconds — don't even pull to refresh.** It
should sync on its own.

### Advanced (already done for you) — automatic sync on reconnect

Once CP4 is finished, take a look at `syncPendingTrails()` further down
in the same file, and at how `trail_list_screen.dart` calls it from an
`onConnectivityChanged` listener in `initState()`. This is what makes
the sync automatic instead of requiring a manual pull-to-refresh — it's
built entirely out of the pieces you just wrote in CP2–CP4. Nothing to
implement here, but it's worth reading once you're done: this is what
the "last write wins" pattern actually looks like wired end-to-end in a
real app.

---

## Final Exercise (take-home)
Right now, a trail that fails to sync (say, connectivity drops again
mid-sync) just quietly stays `pendingSync: true` forever until the next
reconnect. Add a small manual **"Retry sync"** button in the app bar
that calls `TrailRepository().syncPendingTrails()` on demand, for cases
where a user doesn't want to wait for the automatic listener.

---

## Why is the backend fake?
Earlier versions of this starter used a free MockAPI.io project as the
backend. In practice, an external service outside your control adds a
whole category of failure that has nothing to do with local storage —
the actual subject of this lecture. `TrailApiService` now simulates a
real backend using nothing but Dart: it has a genuine delay, it
persists data for the life of the app, and — importantly — it checks
real device connectivity and throws a real exception when there isn't
any, so CP3's error handling and CP4's offline branch both get
exercised exactly as designed. Swapping it for a real HTTP-backed
service later (dio, http, MockAPI, your own backend) requires changing
exactly one file — nothing else in the app needs to know the
difference. That's the entire point of the repository pattern.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| List stays empty, no error | CP2's `saveAll()`/`getAll()` not implemented yet | Finish CP2 first — CP3 depends on it |
| Checkbox resets after restart | CP2 not done yet, or `update()` (Quick Challenge) not implemented | Do CP2 fully before attempting the Quick Challenge |
| New trail never appears | CP4 not implemented yet | Check the console for `UnimplementedError` |
| Trail added offline never shows "Not synced yet" | Using `trail` instead of `trail.copyWith(pendingSync: true)` | Re-check CP4 step 3 |
| Sync doesn't happen automatically after reconnecting | `_connectivitySub` never started, or app was already killed | This listener only runs while the app is alive — reopening the app also triggers a fresh `watchTrails()` fetch, so a manual pull-to-refresh always works as a fallback |
| Thumbnail images don't load | No internet, or picsum.photos temporarily down | Not a bug in your code — the `errorBuilder` shows a fallback icon instead |
| "Duplicate" trail after sync | `syncPendingTrails()` should `remove()` the old local-id entry before `update()`-ing the new one — if you edited that method, check both calls are still there | Compare against the provided implementation |

---

**Remember:** the storage layer, the cache-first repository, and the
sync flow you're building here transfer directly to a production app —
only the network class at the very bottom would need to change.
