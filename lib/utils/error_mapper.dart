import 'package:flutter/widgets.dart';
import 'package:radiozeit/l10n/app_localizations.dart';

/// Maps raw error messages to user-friendly localized strings
class ErrorMapper {
  /// Returns a localized error message for the given raw error string
  static String getLocalizedError(BuildContext context, String rawError) {
    final loc = AppLocalizations.of(context);
    if (loc == null) return rawError;

    final lowerError = rawError.toLowerCase();

    if (lowerError.contains('connection refused')) {
      return loc.error_connection_refused;
    }

    if (lowerError.contains('timeout') || lowerError.contains('timed out')) {
      return loc.error_connection_timeout;
    }

    if (lowerError.contains('no internet') ||
        lowerError.contains('network is unreachable') ||
        lowerError.contains('no address associated')) {
      return loc.error_no_internet;
    }

    if (lowerError.contains('503') || lowerError.contains('service unavailable')) {
      return loc.error_server_unavailable;
    }

    // For any other connection-related errors, use default message
    if (lowerError.contains('connection') ||
        lowerError.contains('socket') ||
        lowerError.contains('failed host lookup')) {
      return loc.error_connection_default;
    }

    // Return the original error if no pattern matches
    return rawError;
  }
}
