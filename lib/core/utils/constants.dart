/// Constantes de la aplicación
class AppConstants {
  AppConstants._();

  // Base de datos
  static const String databaseName = 'synkbudget.db';
  static const int databaseVersion = 1;

  // OneDrive / Microsoft Graph
  static const String graphApiBaseUrl = 'https://graph.microsoft.com/v1.0';
  static const String authBaseUrl = 'https://login.microsoftonline.com/common/oauth2/v2.0';
  static const String clientId = '2e49c731-dc21-4a33-b4e9-6e2baf78df1f'; // SynkBudget Client ID
  static const String redirectUri = 'msal2e49c731-dc21-4a33-b4e9-6e2baf78df1f://auth';
  static const List<String> scopes = [
    'Files.ReadWrite',
    'User.Read',
    'offline_access',
  ];

  // Archivos
  static const String syncFileName = 'synkbudget_sync.json';
  static const String backupFolderName = 'backups';
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int imageQuality = 85;

  // Sincronización
  static const Duration syncInterval = Duration(minutes: 15);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 5);

  // UI
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;

  // Validaciones
  static const double minAmount = 0.01;
  static const double maxAmount = 999999999.99;
  static const int maxDescriptionLength = 500;
  static const int maxCategoryNameLength = 50;
}

