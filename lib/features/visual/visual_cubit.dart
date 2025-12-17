import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:radiozeit/data/api/repository.dart';
import 'package:radiozeit/data/model/visual_chunk.dart';
import 'package:radiozeit/features/player/media_player.dart';
import 'package:radiozeit/features/visual/visual_helper.dart';


class RadioVisualCubit extends Cubit<RadioVisualState> {
  final MediaPlayer player;
  CancelToken? _loadChunkToken;
  String _slug = "";
  int lastPositionUpdate = 0;

  final Repository repo = Repository.getInstance();
  Timer? _updateProgress;
  Timer? _restartUpdateProgress;
  bool isStart = false;

  RadioVisualCubit(this.player) : super(RadioVisualState.init());

  start(String slug) {
    isStart = true;
    _slug = slug;
    lastPositionUpdate = 0;
    _startProgressUpdate();
  }


  _startProgressUpdate() {
    _stopProgressUpdate();
    _updateProgress = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      _progressUpdated();
    });
  }

  _restartProgressUpdate() {
    _stopProgressUpdate();
    _restartUpdateProgress = Timer(const Duration(seconds: 3), () {
      _startProgressUpdate();
    });
  }

  _stopProgressUpdate() {
    _updateProgress?.cancel();
    _restartUpdateProgress?.cancel();
  }

  _progressUpdated() {

    int currentChunk = VisualHelper.getChunkId(player.position.value);
    int nextChunk = VisualHelper.getNextChunkId(player.position.value);
    print("visual: currentChunk $currentChunk nextChunk $nextChunk");
    // skip if chunk is to early
    if(currentChunk < 0) {
      return;
    }

    if(!state.isLoading) {
      if(state.lastLoadedChunk < 0 || state.lastLoadedChunk < currentChunk) { // load current chunk
        print("visual: loadCurent");
        _loadChunks(currentChunk);
      } else {// load next chunk in buffer
        if(state.lastLoadedChunk != nextChunk) {
          print("visual: loadNext");
          _loadChunks(nextChunk);
        }
      }
    }
  }

  _loadChunks(int chunkId) async {

    emit(state.copyWith(isLoading: true,error: ""));
    _loadChunkToken?.cancel();
    _loadChunkToken = CancelToken();
    var response = await repo.loadVisualChunkInfo(
        radioSlug: _slug,
        chunkId: chunkId,
        cancelToken:_loadChunkToken
    );
    if(response.success) {
      double startTime = VisualHelper.getTimeById(chunkId);

      for (var e in response.chunks) {
        e.id = chunkId;
        e.startTime += startTime;
        e.endTime += startTime;
      }

      // clear old chunks
      int currentChunk = VisualHelper.getChunkId(player.position.value);
      print("visual: currentChunk $currentChunk");
      int oldIndex = state.chunks.indexWhere((e) => e.id >= currentChunk);

      List<VisualChunk> newList = oldIndex > 0 ? state.chunks.sublist(oldIndex) : List.from(state.chunks);
      newList.addAll(response.chunks);


      emit(state.copyWith(
        isLoading: false,
        lastLoadedChunk: chunkId,
        chunks: newList,
      ));
    } else {
      _restartProgressUpdate();
      emit(state.copyWith(
          isLoading: false,
          error: response.message
      ));
    }
  }


  @override
  Future<void> close() {
    isStart = false;
    _stopProgressUpdate();
    _loadChunkToken?.cancel();
    return super.close();
  }
}

class RadioVisualState {
  List<VisualChunk> chunks;
  bool isLoading;
  int lastLoadedChunk;
  String error;

  RadioVisualState({
    required this.chunks,
    required this.isLoading,
    required this.lastLoadedChunk,
    required this.error,
  });

  RadioVisualState.init({
    this.chunks = const [],
    this.isLoading = false,
    this.lastLoadedChunk = -1,
    this.error = "",
  });

  RadioVisualState copyWith({
    List<VisualChunk>? chunks,
    bool? isLoading,
    int? lastLoadedChunk,
    String? error,
  }) {
    return RadioVisualState(
      chunks: chunks ?? this.chunks,
      isLoading: isLoading ?? this.isLoading,
      lastLoadedChunk: lastLoadedChunk ?? this.lastLoadedChunk,
      error: error ?? this.error,
    );
  }
}
