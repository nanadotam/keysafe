abstract class ApiEndpoints {
  static const baseUrl = 'https://amoako-pass-go.onrender.com/api/v1';

  // Auth
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const refresh = '/auth/refresh';
  static const logout = '/auth/logout';

  // Vault
  static const vault = '/vault';
  static const vaultExport = '/vault/export';
  static String vaultEntry(String id) => '/vault/$id';

  // WiFi
  static const wifi = '/wifi';
  static String wifiEntry(String id) => '/wifi/$id';

  // User
  static const profile       = '/user/profile';
  static const loginHistory  = '/user/login-history';
  static String loginHistoryEntry(String id) => '/user/login-history/$id';

  // Security
  static const hibpCheck = '/util/hibp-check';
}
