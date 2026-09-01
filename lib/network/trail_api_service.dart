import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/trail.dart';

/// Thrown by TrailApiService when there's genuinely no connection — the
/// same role a real SocketException would play with http or dio.
class NoConnectionException implements Exception {
  @override
  String toString() => 'No internet connection';
}

/// -----------------------------------------------------------------------
/// This class is already complete — nothing to do here.
/// -----------------------------------------------------------------------
/// A tiny "server" that lives entirely inside your own app: no signup,
/// no external service, nothing that can 500 on you mid-lecture.
///
/// It still behaves like a real backend in every way that matters for
/// today's checkpoints:
///   - every call is genuinely async, with a small delay (so CP3's
///     loading spinner has something to show)
///   - it checks real device connectivity and throws NoConnectionException
///     when there isn't one — exactly like a real HTTP call would fail
///   - data survives for the lifetime of the app (a static in-memory list)
///
/// TrailRepository doesn't know or care that this isn't a real network
/// call — that's the whole point of the repository pattern from last
/// week: swap this class for a real http/dio-backed one later, and
/// nothing else in the app has to change.
///
/// Singleton pattern — same shape as last week's ApiService.
/// -----------------------------------------------------------------------
class TrailApiService {
  TrailApiService._internal();
  static final TrailApiService instance = TrailApiService._internal();

  final List<Trail> _serverTrails = [
    Trail(id: 's1', name: 'Eagle Ridge', completed: false, createdAt: DateTime.now().toIso8601String()),
    Trail(id: 's2', name: 'Blue River Loop', completed: true, createdAt: DateTime.now().toIso8601String()),
    Trail(id: 's3', name: 'Sunset Overlook', completed: false, createdAt: DateTime.now().toIso8601String()),
  ];
  int _nextId = 4;

  Future<List<Trail>> getTrails() async {
    await _simulateNetworkCall();
    return List.of(_serverTrails);
  }

  Future<Trail> addTrail(Trail trail) async {
    await _simulateNetworkCall();
    final saved = trail.copyWith(
      id: 's${_nextId++}',
      createdAt: DateTime.now().toIso8601String(),
      pendingSync: false,
    );
    _serverTrails.add(saved);
    return saved;
  }

  Future<void> _simulateNetworkCall() async {
    final result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none) {
      throw NoConnectionException();
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
