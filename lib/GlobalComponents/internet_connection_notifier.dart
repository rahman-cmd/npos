import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

final internetConnectionProvider = ChangeNotifierProvider<InternetConnectionNotifier>((ref) {
  return InternetConnectionNotifier();
});

class InternetConnectionNotifier extends ChangeNotifier {
  bool _isConnected = true;
  VoidCallback? _onConnectionRestored;

  bool get isConnected => _isConnected;

  InternetConnectionNotifier() {
    checkConnection();
    InternetConnection().onStatusChange.listen((status) {
      _isConnected = status == InternetStatus.connected;
      notifyListeners();
      if (_isConnected && _onConnectionRestored != null) {
        _onConnectionRestored!();
        _onConnectionRestored = null;
      }
    });
  }

  Future<void> checkConnection() async {
    _isConnected = await InternetConnection().hasInternetAccess;
    notifyListeners();
  }

  void setOnConnectionRestored(VoidCallback callback) {
    _onConnectionRestored = callback;
  }
}