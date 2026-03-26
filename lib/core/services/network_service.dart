// lib/core/services/network_service.dart

import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  final Connectivity _connectivity = Connectivity();

  Future<bool> isConnected() async {
    final List<ConnectivityResult> result = await _connectivity.checkConnectivity();
    return _hasConnection(result);
  }

  Stream<bool> get connectivityStream =>
      _connectivity.onConnectivityChanged.map(_hasConnection);

  // ✅ Fixed: Accepts a List of results instead of a single result
  bool _hasConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;

    // If the list ONLY contains .none, we are offline
    if (results.length == 1 && results.first == ConnectivityResult.none) {
      return false;
    }

    return true;
  }
}