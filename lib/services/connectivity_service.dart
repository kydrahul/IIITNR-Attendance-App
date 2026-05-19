import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// A singleton that surfaces real-time network connectivity status.
///
/// Usage:
///   ConnectivityService().isOnline   // synchronous snapshot
///   ConnectivityService().onChanged  // broadcast stream of bool
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;

  final Connectivity _connectivity = Connectivity();

  // Stream controller — broadcast so many listeners can subscribe.
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  late StreamSubscription<List<ConnectivityResult>> _subscription;

  bool _isOnline = true; // optimistic default until first check
  bool get isOnline => _isOnline;

  Stream<bool> get onChanged => _controller.stream;

  ConnectivityService._internal() {
    _init();
  }

  Future<void> _init() async {
    // Seed with current state.
    final results = await _connectivity.checkConnectivity();
    _isOnline = _resultsToOnline(results);

    // Listen for changes.
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = _resultsToOnline(results);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(_isOnline);
        debugPrint(
            'ConnectivityService: network is now ${_isOnline ? "ONLINE" : "OFFLINE"}');
      }
    });
  }

  bool _resultsToOnline(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }

  void dispose() {
    _subscription.cancel();
    _controller.close();
  }
}
