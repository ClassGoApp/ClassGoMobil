class PerformanceConfig {
  // Configuración de cache
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const Duration cacheExpiration = Duration(hours: 24);

  // Configuración de imágenes
  static const int imageCacheSize = 50 * 1024 * 1024; // 50MB
  static const Duration imageCacheExpiration = Duration(hours: 12);

  // Configuración de paginación
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Configuración de debounce
  static const Duration searchDebounce = Duration(milliseconds: 500);
  static const Duration scrollDebounce = Duration(milliseconds: 100);

  // Configuración de animaciones
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Configuración de timeouts
  static const Duration apiTimeout = Duration(seconds: 10);
  static const Duration connectionTimeout = Duration(seconds: 5);

  // Configuración de lazy loading
  static const int lazyLoadThreshold = 3; // Cargar cuando quedan 3 items
  static const int maxConcurrentRequests = 3;

  // Configuración de memoria
  static const int maxWidgetRebuilds = 100; // Límite de rebuilds por widget
  static const bool enableWidgetOptimization = true;

  // Configuración de debug
  static const bool enablePerformanceLogging = false;
  static const bool enableRebuildLogging = false;
}
