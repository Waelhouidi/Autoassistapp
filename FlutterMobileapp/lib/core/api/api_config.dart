/// API Configuration
/// Centralized configuration for backend API
class ApiConfig {
  ApiConfig._();

  // ============================================
  // 🔧 NETWORK CONFIGURATION
  // ============================================

  // 1. FOR ANDROID EMULATOR: Use '10.0.2.2'
  // 2. FOR IOS SIMULATOR: Use 'localhost'
  // 3. FOR PHYSICAL DEVICE: Use your PC's Local IP (e.g., '192.168.1.x')

  // 👇 UNCOMMENT THE LINE THAT MATCHES YOUR SETUP:

  // static const String _host = '10.0.2.2'; // Android Emulator
  // static const String _host = 'localhost'; // iOS Simulator
  static const String _host =
      '192.168.1.199'; // Physical Device (Update if needed!)

  static const int _port = 3000;
  static const String baseUrl = 'http://$_host:$_port/api';

  // ============================================

  // Endpoints
  static const String auth = '/auth';
  static const String login = '$auth/login';
  static const String register = '$auth/register';
  static const String logout = '$auth/logout';
  static const String me = '$auth/me';
  static const String changePassword = '$auth/change-password';

  static const String todos = '/todos';
  static const String todoStats = '$todos/stats';

  static const String posts = '/posts';
  static const String enhance = '$posts/enhance';
  static const String publish = '$posts/publish';

  static const String health = '/health';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Headers
  static Map<String, String> getHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
