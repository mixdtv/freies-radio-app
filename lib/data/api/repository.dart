import 'dart:developer' as developer;
import 'package:logging/logging.dart';
import 'package:dart_rss/dart_rss.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:radiozeit/config/app_config.dart';
import 'package:radiozeit/data/api/http_api.dart';
import 'package:radiozeit/data/api/response/city_list_response.dart';
import 'package:radiozeit/data/api/response/city_response.dart';
import 'package:radiozeit/data/api/response/epg_response_response.dart';
import 'package:radiozeit/data/api/response/lang_list_response.dart';
import 'package:radiozeit/data/api/response/radio_list_response.dart';
import 'package:radiozeit/data/api/response/server_response.dart';
import 'package:radiozeit/data/api/response/transcript_response.dart';
import 'package:radiozeit/data/api/response/visual_bands_response.dart';
import 'package:radiozeit/data/model/podcast.dart';
import 'package:radiozeit/features/location/model/location.dart';

/// Top-level function for parsing RSS feed in a separate isolate.
/// Must be top-level or static to work with compute().
Map<String, dynamic> _parsePodcastFeedIsolate(Map<String, dynamic> params) {
  final data = params['data'] as String;
  final feedUrl = params['feedUrl'] as String;

  final rssFeed = RssFeed.parse(data);

  final episodes = rssFeed.items.map((item) {
    final imageUrl = item.itunes?.image?.href ??
        rssFeed.itunes?.image?.href ??
        rssFeed.image?.url ??
        '';

    return {
      'title': item.title ?? '',
      'description': item.description ?? '',
      'imageUrl': imageUrl,
      'audioUrl': item.enclosure?.url ?? '',
      'pubDate': item.pubDate != null ? DateTime.tryParse(item.pubDate!)?.toIso8601String() : null,
      'duration': null,
    };
  }).toList();

  return {
    'title': rssFeed.title ?? '',
    'description': rssFeed.description ?? '',
    'imageUrl': rssFeed.itunes?.image?.href ?? rssFeed.image?.url ?? '',
    'feedUrl': feedUrl,
    'episodes': episodes,
  };
}

class Repository {

  static Repository? _instance;
  static Repository getInstance() {
    _instance ??= Repository._();
    return _instance!;
  }

  late HttpApi api;
  final _log = Logger('Repository');

  // Podcast feed cache
  final Map<String, _CachedPodcast> _podcastCache = {};
  static const Duration _cacheExpiration = Duration(minutes: 5);

  Repository._();

  init(String id) {
    api = HttpApi(
      baseServer: "${AppConfig.apiBaseUrl}/api/${AppConfig.apiVersion}/",
      key: AppConfig.apiKey,
      deviceId: id,
    );
  }



  Future<RadioListResponse> loadRadioList({
    Location? location,
    String? query,
    CancelToken? cancel,
  }) {
    Map<String,dynamic> data = {
      "source":"mobile_app",
    };

    if(location != null) {
      data["lat"] = location.latitude;
      data["lng"] = location.longitude;
    }

    if(query != null) {
      data["q"] = query;
    }

    final url = "${AppConfig.apiBaseUrl}/api/${AppConfig.apiVersion}/broadcasters";
    _log.info('loadRadioList: requesting $url with data: $data');

    return api.get(
        patch: "broadcasters",
      cancelToken: cancel,
      data: data
    ).then((value) {
      final response = RadioListResponse(value);
      _log.info('loadRadioList: received ${response.radioList.length} stations');
      return response;
    }).catchError((error) {
      _log.severe('loadRadioList: error $error');
      throw error;
    });
  }

  Future<CityResponse> loadCityByCoordinates({
    required Location location,
  }) {
    Map<String,dynamic> data = {
      "source":"mobile_app",
      "lat" : location.latitude,
      "lng" : location.longitude
    };

    return api.get(
        patch: "get_city",
      data: data
    ).then((value) => CityResponse(value));
  }

  Future<CityListResponse> loadCityList({
    required String query,
    CancelToken? cancel,
  }) {
    Map<String,dynamic> data = {
      "source":"mobile_app",
      "query" : query,
    };

    return api.get(
        patch: "broadcasters/cities",
      cancelToken: cancel,
      data: data
    ).then((value) => CityListResponse(value));
  }

  Future<TranscriptResponse> loadTranscript({
    required String radioSlug,
    required String lang,
    required int chunkId,
    CancelToken? cancelToken,
}) {

    Map<String,dynamic> params = {};
    if(lang.isNotEmpty) {
      params["lang"] = lang;
    }

    return api.get(
        patch: "metadata/$radioSlug/chunks/$chunkId",
        cancelToken: cancelToken,
        data: params,
    ).then((value) => TranscriptResponse(value));
  }

  Future<VisualBandsResponse> loadVisualChunkInfo({
    required String radioSlug,
    required int chunkId,
    CancelToken? cancelToken,
  }) {

    return api.get(patch: "streams/$radioSlug/fft/$chunkId")
        .then((value) => VisualBandsResponse(value));
  }

  Future<EpgResponseResponse> loadEpg({
    required String epgSlug,
    DateTime? from,
    DateTime? to,
    CancelToken? cancelToken,
  }) {
    final Map<String, dynamic> data = {};
    if (from != null) {
      data['from'] = from.toUtc().toIso8601String();
    }
    if (to != null) {
      data['to'] = to.toUtc().toIso8601String();
    }

    return api.get(
      patch: "${AppConfig.epgBaseUrl}$epgSlug",
      data: data,
      cancelToken: cancelToken,
    ).then((value) => EpgResponseResponse(value));
  }

  Future<EpgResponseResponse> searchEpg({
    required String query,
    DateTime? from,
    DateTime? to,
    CancelToken? cancelToken,
  }) {
    final Map<String, dynamic> data = {"q": query, "limit": 20};
    if (from != null) {
      data['from'] = from.toUtc().toIso8601String();
    }
    if (to != null) {
      data['to'] = to.toUtc().toIso8601String();
    }
    return api.get(
      patch: "${AppConfig.epgBaseUrl}search",
      data: data,
      cancelToken: cancelToken,
    ).then((value) => EpgResponseResponse(value));
  }

  Future<LangListResponse> loadLangList({
    CancelToken? cancelToken,
  }) {

    return api.get(patch: "metadata/translations/languages")
        .then((value) => LangListResponse(value));
  }


  Future<Podcast> loadPodcastFeed({
    required String feedUrl,
    CancelToken? cancelToken,
  }) async {
    final totalStopwatch = Stopwatch()..start();

    // Check cache first
    final cachedPodcast = _podcastCache[feedUrl];
    if (cachedPodcast != null && !cachedPodcast.isExpired) {
      developer.log(
        'Podcast cache hit for $feedUrl',
        name: 'PodcastLoader',
      );
      return cachedPodcast.podcast;
    }

    developer.log(
      'Starting podcast fetch for $feedUrl',
      name: 'PodcastLoader',
    );

    // Fetch RSS feed
    final fetchStopwatch = Stopwatch()..start();
    final dio = Dio();
    final response = await dio.get(
      feedUrl,
      cancelToken: cancelToken,
    );
    fetchStopwatch.stop();

    developer.log(
      'Network fetch completed in ${fetchStopwatch.elapsedMilliseconds}ms (${response.data.toString().length} bytes)',
      name: 'PodcastLoader',
    );

    // Parse RSS feed in separate isolate to avoid blocking UI
    final parseStopwatch = Stopwatch()..start();
    final podcastJson = await compute(_parsePodcastFeedIsolate, {
      'data': response.data as String,
      'feedUrl': feedUrl,
    });
    parseStopwatch.stop();

    developer.log(
      'RSS parsing completed in ${parseStopwatch.elapsedMilliseconds}ms (isolate)',
      name: 'PodcastLoader',
    );

    final podcast = Podcast.fromJson(podcastJson);

    // Cache the podcast
    _podcastCache[feedUrl] = _CachedPodcast(
      podcast: podcast,
      timestamp: DateTime.now(),
    );

    totalStopwatch.stop();
    developer.log(
      'Podcast load complete: ${podcast.title} (${podcast.episodes.length} episodes) in ${totalStopwatch.elapsedMilliseconds}ms total',
      name: 'PodcastLoader',
    );

    return podcast;
  }

  void clearPodcastCache() {
    _podcastCache.clear();
  }
}

class _CachedPodcast {
  final Podcast podcast;
  final DateTime timestamp;

  _CachedPodcast({
    required this.podcast,
    required this.timestamp,
  });

  bool get isExpired {
    return DateTime.now().difference(timestamp) > Repository._cacheExpiration;
  }
}