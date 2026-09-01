import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../models/trail.dart';
import '../repositories/trail_repository.dart';
import '../storage/trail_cache.dart';
import '../storage/trail_preferences.dart';
import '../theme/app_colors.dart';

class TrailListScreen extends StatefulWidget {
  const TrailListScreen({super.key});

  @override
  State<TrailListScreen> createState() => _TrailListScreenState();
}

class _TrailListScreenState extends State<TrailListScreen> {
  final TrailRepository _repo = TrailRepository();
  final TrailPreferences _prefs = TrailPreferences();

  late Stream<List<Trail>> _trailsStream;
  bool _showCompleted = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  // Local overrides so the Quick Challenge's checkbox feels instant,
  // without needing to restart the whole watchTrails() stream on every tap.
  final Map<String, bool> _completedOverrides = {};

  @override
  void initState() {
    super.initState();
    _trailsStream = _repo.watchTrails();
    _loadShowCompleted();

    // Advanced: whenever the device comes back online, try to push any
    // trails that were added offline. This is on top of CP4, not part
    // of it — CP4 only needs the app to survive being offline; this is
    // what makes it feel automatic instead of requiring a manual refresh.
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) _trySyncPending();
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> _loadShowCompleted() async {
    final value = await _prefs.getShowCompleted();
    if (mounted) setState(() => _showCompleted = value);
  }

  Future<void> _onToggleShowCompleted(bool value) async {
    setState(() => _showCompleted = value);
    await _prefs.setShowCompleted(value);
  }

  Future<void> _trySyncPending() async {
    final synced = await _repo.syncPendingTrails();
    if (!mounted) return;
    setState(() => _trailsStream = _repo.watchTrails());
    if (synced > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Synced $synced trail${synced == 1 ? '' : 's'} \u2705')),
      );
    }
  }

  Future<void> _onRefresh() async {
    await _trySyncPending();
    setState(() => _trailsStream = _repo.watchTrails());
  }

  Future<void> _onToggleCompleted(Trail trail, bool value) async {
    setState(() => _completedOverrides[trail.id] = value);
    try {
      await TrailCache().update(trail.copyWith(completed: value));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\u2019t save that yet: $e')),
        );
      }
    }
  }

  Future<void> _onAddTrailPressed() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New trail'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Eagle Ridge'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;

    final newTrail = Trail(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      completed: false,
      createdAt: DateTime.now().toIso8601String(),
    );

    try {
      await _repo.addTrail(newTrail);
      setState(() => _trailsStream = _repo.watchTrails());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\u2019t add that trail yet: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TrailLog'),
        actions: [
          Row(
            children: [
              const Text('Show completed', style: TextStyle(fontSize: 13)),
              Switch(value: _showCompleted, onChanged: _onToggleShowCompleted),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddTrailPressed,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          ClipRRect(
            child: Image.asset(
              'assets/images/trail_hero.png',
              width: double.infinity,
              height: 130,
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Trail>>(
              stream: _trailsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        '${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final allTrails = snapshot.data ?? [];
                final trails = allTrails.where((t) {
                  final completed = _completedOverrides[t.id] ?? t.completed;
                  return _showCompleted || !completed;
                }).toList()
                  // Pending trails float to the top — you want to see
                  // what's still waiting to sync.
                  ..sort((a, b) {
                    if (a.pendingSync == b.pendingSync) return 0;
                    return a.pendingSync ? -1 : 1;
                  });

                if (trails.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/images/empty_state.png', height: 170),
                        const SizedBox(height: 16),
                        const Text(
                          'No trails yet — tap + to add one.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: trails.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final trail = trails[index];
                      final completed = _completedOverrides[trail.id] ?? trail.completed;
                      return Container(
                        color: trail.pendingSync ? AppColors.yellowSoft : null,
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              'https://picsum.photos/seed/${trail.id}/100/100',
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.terrain, size: 40),
                            ),
                          ),
                          title: Text(trail.name),
                          subtitle: Text(
                            trail.pendingSync
                                ? 'Not synced yet \u2014 will upload automatically'
                                : 'Logged: ${trail.createdAt}',
                            style: TextStyle(
                              color: trail.pendingSync ? AppColors.yellowDeep : Colors.grey,
                              fontStyle: trail.pendingSync ? FontStyle.italic : FontStyle.normal,
                            ),
                          ),
                          trailing: Checkbox(
                            value: completed,
                            onChanged: (value) => _onToggleCompleted(trail, value ?? false),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
