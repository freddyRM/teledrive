import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Por donde se permite subir archivos al grupo. Por defecto solo Wi-Fi.
enum NetworkPolicy { wifi, mobile, both }

class NetworkPolicyStore {
  NetworkPolicyStore._();

  static const _key = 'network_policy';

  static Future<NetworkPolicy> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_key);
      return NetworkPolicy.values.firstWhere(
        (policy) => policy.name == name,
        orElse: () => NetworkPolicy.wifi,
      );
    } catch (_) {
      return NetworkPolicy.wifi;
    }
  }

  static Future<void> write(NetworkPolicy policy) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, policy.name);
  }

  /// True si la red actual esta permitida por la politica elegida.
  /// "mobile" significa solo datos moviles: si hay Wi-Fi conectada, no sube.
  static Future<bool> uploadAllowed() async {
    final policy = await read();
    final results = await Connectivity().checkConnectivity();
    final wifi = results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);
    final mobile = results.contains(ConnectivityResult.mobile);
    switch (policy) {
      case NetworkPolicy.wifi:
        return wifi;
      case NetworkPolicy.mobile:
        return mobile && !wifi;
      case NetworkPolicy.both:
        return wifi || mobile;
    }
  }
}
