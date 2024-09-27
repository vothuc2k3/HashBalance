import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final connectivityProvider = StreamProvider((ref) {
  return ref.watch(networkControllerProvider).checkInternetConnection();
});

final networkControllerProvider = Provider<NetworkController>((ref) {
  return NetworkController();
});

class NetworkController {
  NetworkController();

  Stream<List<ConnectivityResult>> checkInternetConnection() {
    return Connectivity().onConnectivityChanged;
  }
}
