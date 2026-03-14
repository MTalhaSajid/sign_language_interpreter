enum AppEnvironment { dev, prod }

class AppConfig {
  static late AppEnvironment environment;
  static late String baseUrl;

  static void setup(AppEnvironment env) {
    environment = env;
    baseUrl = env == AppEnvironment.dev
        ? 'https://jsonplaceholder.typicode.com'
        : 'https://api.example.com';
  }

  static bool get isDev => environment == AppEnvironment.dev;
}
