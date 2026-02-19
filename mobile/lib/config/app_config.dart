class AppConfig {
  static const String env = String.fromEnvironment('ENV', defaultValue: 'dev');
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: env == 'prod' 
      ? 'https://inventory.maxmar.net/api' 
      : 'http://10.0.2.2:8000/api',
  );

  static bool get isProduction => env == 'prod';
  static bool get isDevelopment => env == 'dev';
}
