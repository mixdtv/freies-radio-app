import 'dart:developer' as developer;

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:radiozeit/data/api/repository.dart';
import 'package:radiozeit/data/model/podcast.dart';

class PodcastState {
  final List<Podcast> podcasts;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  PodcastState({
    this.podcasts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  PodcastState copyWith({
    List<Podcast>? podcasts,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) {
    return PodcastState(
      podcasts: podcasts ?? this.podcasts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

class PodcastCubit extends Cubit<PodcastState> {
  final Repository repository;
  CancelToken? _cancelToken;
  Future<void>? _currentLoad;
  List<String>? _currentFeedUrls;
  List<Podcast> _loadedPodcasts = [];
  bool _silent = false;

  PodcastCubit({required this.repository}) : super(PodcastState());

  Future<void> loadPodcasts(List<String> feedUrls, {bool silent = false, String? radioName}) async {
    final radioLabel = radioName != null ? ' for "$radioName"' : '';

    // If a load is already in progress for the same feeds, join it
    if (_currentLoad != null && _listEquals(_currentFeedUrls, feedUrls)) {
      developer.log(
        'Joining existing load$radioLabel (silent: $_silent -> $silent)',
        name: 'PodcastCubit',
      );
      // Switch from silent to non-silent: emit current state immediately
      if (_silent && !silent) {
        _silent = false;
        if (_loadedPodcasts.isNotEmpty) {
          emit(state.copyWith(
            podcasts: List.of(_loadedPodcasts),
            isLoading: false,
            isLoadingMore: true,
            error: null,
          ));
        } else {
          emit(state.copyWith(isLoading: true, error: null));
        }
      }
      await _currentLoad;
      return;
    }

    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    _silent = silent;
    _currentFeedUrls = feedUrls;

    final stopwatch = Stopwatch()..start();
    developer.log(
      'Loading ${feedUrls.length} podcast feed(s)$radioLabel, silent: $silent',
      name: 'PodcastCubit',
    );

    if (!silent) {
      emit(state.copyWith(isLoading: true, isLoadingMore: false, error: null));
    }

    _loadedPodcasts = [];
    int completed = 0;
    final total = feedUrls.length;

    // Start all feeds concurrently, emit as each one completes
    _currentLoad = Future.wait(feedUrls.map((url) async {
      try {
        final podcast = await repository.loadPodcastFeed(
          feedUrl: url,
          cancelToken: _cancelToken,
        );
        completed++;
        _loadedPodcasts.add(podcast);

        if (!_silent) {
          emit(state.copyWith(
            podcasts: List.of(_loadedPodcasts),
            isLoading: false,
            isLoadingMore: completed < total,
          ));
        }
      } catch (e) {
        completed++;
        developer.log(
          'Failed to load feed $url: $e',
          name: 'PodcastCubit',
          level: 900,
        );

        if (!_silent) {
          emit(state.copyWith(
            isLoading: _loadedPodcasts.isEmpty && completed < total,
            isLoadingMore: completed < total,
          ));
        }
      }
    }));

    await _currentLoad;
    _currentLoad = null;
    _currentFeedUrls = null;

    stopwatch.stop();
    developer.log(
      '${_loadedPodcasts.length}/${total} podcast(s) loaded in ${stopwatch.elapsedMilliseconds}ms',
      name: 'PodcastCubit',
    );

    if (_loadedPodcasts.isEmpty) {
      emit(state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: 'Failed to load podcasts',
      ));
    } else {
      emit(state.copyWith(
        podcasts: _loadedPodcasts,
        isLoading: false,
        isLoadingMore: false,
      ));
    }
  }

  Future<void> preloadPodcasts(List<String> feedUrls, {String? radioName}) async {
    final radioLabel = radioName != null ? ' for "$radioName"' : '';

    // Check if we're already loading the same feeds
    if (_currentLoad != null && _listEquals(_currentFeedUrls, feedUrls)) {
      developer.log(
        'Skipping duplicate preload$radioLabel - already in progress',
        name: 'PodcastCubit',
      );
      return _currentLoad!;
    }

    developer.log(
      'Preloading ${feedUrls.length} podcast feed(s)$radioLabel in background',
      name: 'PodcastCubit',
    );

    return loadPodcasts(feedUrls, silent: true, radioName: radioName);
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
