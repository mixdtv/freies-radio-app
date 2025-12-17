/// Application-wide configuration
/// These values can be overridden at build/run time using --dart-define flags
class AppConfig {
  static const String _apiBaseUrl = String.fromEnvironment('API_URL');

  static const String _epgBaseUrl = String.fromEnvironment('EPG_URL');

  /// Main API base URL (sanitized with trailing slash)
  static String get apiBaseUrl {
    if (_apiBaseUrl.isEmpty) {
      throw StateError('API_URL must be set via --dart-define-from-file=.env.json');
    }
    return _ensureTrailingSlash(_apiBaseUrl);
  }

  /// API version path segment
  static const String apiVersion = 'v1';

  /// API key for authentication
  static const String apiKey = String.fromEnvironment('API_KEY');

  /// EPG (Electronic Program Guide) API base URL (sanitized with trailing slash)
  /// The epgSlug from radio.epgPrefix is appended to this URL
  static String get epgBaseUrl {
    if (_epgBaseUrl.isEmpty) {
      throw StateError('EPG_URL must be set via --dart-define-from-file=.env.json');
    }
    return _ensureTrailingSlash(_epgBaseUrl);
  }

  /// Ensures URL ends with a trailing slash
  static String _ensureTrailingSlash(String url) {
    return url.endsWith('/') ? url : '$url/';
  }

  /// Stream source toggle
  /// - false (default): Use HLS stream (widely compatible)
  /// - true: Use source stream (original quality from broadcaster)
  ///
  /// Usage:
  /// flutter run --dart-define=USE_SOURCE_STREAM=true
  /// flutter build apk --dart-define=USE_SOURCE_STREAM=true
  static const bool useSourceStream = bool.fromEnvironment(
    'USE_SOURCE_STREAM',
    defaultValue: true,
  );

  /// Visible detail page menu items
  /// Configure which submenu tabs are shown in the broadcast detail page
  ///
  /// Available menu items:
  /// - 'transcript': Transcript (Transkript)
  /// - 'timeline': Timeline (Zeitstrahl)
  /// - 'podcasts': Podcasts (only shown if station has podcasts)
  /// - 'visual': Visual (Visuell)
  /// - 'about': About (Über)
  ///
  /// Examples:
  /// Show only Timeline and About:
  static const List<String> visibleMenuItems = ['timeline', 'podcasts', 'about'];

  /// Show all menu items:
  // static const List<String> visibleMenuItems = ['transcript', 'timeline', 'podcasts', 'visual', 'about'];
}