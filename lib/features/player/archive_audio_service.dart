import 'package:radiozeit/config/app_config.dart';
import 'package:radiozeit/data/model/radio_program.dart';
import 'package:radiozeit/utils/app_logger.dart';

final _log = getLogger('ArchiveAudioService');

/// Represents an HLS archive playback configuration.
class ArchivePlaybackInfo {
  final RadioEpg program;
  final String playlistUrl;
  final Map<String, String> headers;

  ArchivePlaybackInfo({
    required this.program,
    required this.playlistUrl,
    required this.headers,
  });
}

/// Service for building HLS archive playback URLs.
///
/// Uses the backend's HLS playlist endpoint which serves m3u8 playlists
/// pointing to individual 1-minute m4a segments. This provides:
/// - Instant response (no FFmpeg processing)
/// - Gapless playback with native buffering
/// - Full seeking support
class ArchiveAudioService {
  String _deviceId = '';

  ArchiveAudioService();

  /// Initialize with device ID (must be called before building sources).
  void setDeviceId(String deviceId) {
    _deviceId = deviceId;
  }

  /// Gets the authentication headers required for archive API requests.
  Map<String, String> get authHeaders => {
    'X-API-KEY': AppConfig.apiKey,
    'X-App-User': _deviceId,
  };

  /// Builds archive playback info for the given program.
  ///
  /// Returns null if the program has no valid time range.
  ArchivePlaybackInfo? buildPlaybackInfo({
    required RadioEpg program,
    required String streamPrefix,
  }) {
    if (program.start.isAfter(program.end) || program.start == program.end) {
      _log.warning('Invalid program time range: ${program.start} - ${program.end}');
      return null;
    }

    final playlistUrl = _buildHlsPlaylistUrl(
      streamPrefix: streamPrefix,
      start: program.start,
      end: program.end,
    );

    _log.info('Built HLS playlist URL for "${program.title}" '
        '(${_formatDuration(program.end.difference(program.start))})');
    _log.info('Playlist URL: $playlistUrl');

    return ArchivePlaybackInfo(
      program: program,
      playlistUrl: playlistUrl,
      headers: Map.from(authHeaders),
    );
  }

  /// Builds the HLS playlist URL for the given time range.
  String _buildHlsPlaylistUrl({
    required String streamPrefix,
    required DateTime start,
    required DateTime end,
  }) {
    final baseUrl = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final fromStr = start.toUtc().toIso8601String();
    final toStr = end.toUtc().toIso8601String();

    return '$baseUrl/api/${AppConfig.apiVersion}/audio/archive/playlist.m3u8'
        '?station=$streamPrefix'
        '&from=$fromStr'
        '&to=$toStr';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
