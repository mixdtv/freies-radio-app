import 'dart:developer' as developer;

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:radiozeit/data/api/repository.dart';
import 'package:radiozeit/data/model/podcast.dart';

class PodcastState {
  final List<Podcast> podcasts;
  final bool isLoading;
  final String? error;

  PodcastState({
    this.podcasts = const [],
    this.isLoading = false,
    this.error,
  });

  PodcastState copyWith({
    List<Podcast>? podcasts,
    bool? isLoading,
    String? error,
  }) {
    return PodcastState(
      podcasts: podcasts ?? this.podcasts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PodcastCubit extends Cubit<PodcastState> {
  final Repository repository;
  CancelToken? _cancelToken;
  Future<void>? _currentPreload;
  List<String>? _currentFeedUrls;

  PodcastCubit({required this.repository}) : super(PodcastState());

  Future<void> loadPodcasts(List<String> feedUrls, {bool silent = false, String? radioName}) async {
    final radioLabel = radioName != null ? ' for "$radioName"' : '';

    // If preload is in progress for the same feeds, wait for it instead of restarting
    if (_currentPreload != null && _listEquals(_currentFeedUrls, feedUrls)) {
      developer.log(
        'Waiting for existing preload$radioLabel to complete',
        name: 'PodcastCubit',
      );
      if (!silent) {
        emit(state.copyWith(isLoading: true, error: null));
      }
      await _currentPreload;
      return;
    }

    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    final stopwatch = Stopwatch()..start();
    developer.log(
      'Loading ${feedUrls.length} podcast feed(s)$radioLabel, silent: $silent',
      name: 'PodcastCubit',
    );

    if (!silent) {
      emit(state.copyWith(isLoading: true, error: null));
    }

    try {
      final podcasts = await Future.wait(
        feedUrls.map((url) => repository.loadPodcastFeed(
          feedUrl: url,
          cancelToken: _cancelToken,
        )),
      );

      stopwatch.stop();
      developer.log(
        'All ${podcasts.length} podcast(s) loaded in ${stopwatch.elapsedMilliseconds}ms',
        name: 'PodcastCubit',
      );

      emit(state.copyWith(
        podcasts: podcasts,
        isLoading: false,
      ));
    } catch (e) {
      stopwatch.stop();
      developer.log(
        'Podcast loading failed after ${stopwatch.elapsedMilliseconds}ms: $e',
        name: 'PodcastCubit',
        level: 900, // Warning level
      );

      if (!silent) {
        emit(state.copyWith(
          isLoading: false,
          error: e.toString(),
        ));
      }
      // Silent failures are ignored - data will be in cache for next load
    }
  }

  Future<void> preloadPodcasts(List<String> feedUrls, {String? radioName}) async {
    final radioLabel = radioName != null ? ' for "$radioName"' : '';

    // Check if we're already preloading the same feeds
    if (_currentPreload != null && _listEquals(_currentFeedUrls, feedUrls)) {
      developer.log(
        'Skipping duplicate preload$radioLabel - already in progress',
        name: 'PodcastCubit',
      );
      return _currentPreload!;
    }

    developer.log(
      'Preloading ${feedUrls.length} podcast feed(s)$radioLabel in background',
      name: 'PodcastCubit',
    );

    _currentFeedUrls = feedUrls;
    _currentPreload = loadPodcasts(feedUrls, silent: true, radioName: radioName).whenComplete(() {
      _currentPreload = null;
      _currentFeedUrls = null;
    });

    return _currentPreload!;
  }

  bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void clear() {
    _cancelToken?.cancel();
    emit(PodcastState());
  }

  @override
  Future<void> close() {
    _cancelToken?.cancel();
    return super.close();
  }
}
