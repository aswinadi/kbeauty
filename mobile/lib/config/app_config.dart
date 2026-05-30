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

  static String formatUrl(String url) {
    if (env == 'dev') {
      return url
          .replaceAll('localhost:8000', '10.0.2.2:8000')
          .replaceAll('127.0.0.1:8000', '10.0.2.2:8000')
          .replaceAll('localhost', '10.0.2.2')
          .replaceAll('127.0.0.1', '10.0.2.2');
    }
    return url;
  }
}
