// lib/core/services/network_service.dart

import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  final Connectivity _connectivity = Connectivity();

  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return _hasConnection(result);
  }

  Stream<bool> get connectivityStream =>
      _connectivity.onConnectivityChanged.map(_hasConnection);

  // Fixed: Accepting a single ConnectivityResult enum instead of a List 👇
  bool _hasConnection(ConnectivityResult result) {
    return result != ConnectivityResult.none;
  }
}