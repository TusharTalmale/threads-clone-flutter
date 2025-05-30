import 'package:get_storage/get_storage.dart';
import 'package:thread_app/utils/storage_keys.dart'; // Ensure this file exists and defines StorageKeys.userSession

class StorageService {
  static final GetStorage session = GetStorage();
  static dynamic userSession = session.read(StorageKeys.userSession);

  static Future<void> saveUserSession(Map<String, dynamic> sessionData) async {
    await session.write(StorageKeys.userSession, sessionData);
  }

  static Map<String, dynamic>? getUserSession() {
    final dynamic data = session.read(StorageKeys.userSession);
    if (data != null && data is Map<String, dynamic>) {
      return data;
    }
    return null;
  }

  static Future<void> clearUserSession() async {
    await session.remove(StorageKeys.userSession);
  }

  static bool hasUserSession() {
    return session.hasData(StorageKeys.userSession);
  }
}
