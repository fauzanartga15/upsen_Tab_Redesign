import 'package:shared_preferences/shared_preferences.dart';

class StorageHelper {
  static Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static String? getString(String key) {
    // Ini akan return null jika belum ada SharedPreferences instance
    return null; // Untuk sementara, nanti akan diupdate di AuthProvider
  }

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
