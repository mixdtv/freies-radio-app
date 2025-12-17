import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:bloc_presentation/bloc_presentation.dart';
import 'package:dio/dio.dart';
import 'package:radiozeit/data/api/repository.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/data/model/transcript_chunk.dart';
import 'package:radiozeit/data/model/transcript_chunk_line.dart';
import 'package:radiozeit/data/model/transcript_chunk_word.dart';
import 'package:radiozeit/data/model/translate_lang.dart';
import 'package:radiozeit/features/player/media_player.dart';
import 'package:radiozeit/features/transcript/transcript_helper.dart';
import 'package:radiozeit/features/visual/visual_helper.dart';
import 'package:radiozeit/utils/consts.dart';
import 'package:radiozeit/utils/extensions.dart';
import 'package:radiozeit/utils/settings.dart';

const int timeTrOffset = 20 ;  // sec
const double chunkDuration = 30; // sec
const int maxOldLines = 20;

enum TranscriptFontSize {
  small(24),
  medium(30),
  big(45);

  const TranscriptFontSize(this.size);
  final double size;
}
enum TranscriptSpeed {
  speed05(0.5),
  speed075(0.75),
  speedNormal(1);
  const TranscriptSpeed(this.speed);
  final double speed;
}

class TranscriptEvent {
  
}




class TranscriptCubit extends Cubit<TranscriptState> with BlocPresentationMixin<TranscriptState,TranscriptEvent>  {
  final Repository repo = Repository.getInstance();
  final AppSettings settings = AppSettings.getInstance();
  final MediaPlayer player;

  CancelToken? _loadChunkToken;
  String _slug = "";
  int lastPositionUpdate = 0;
  Timer? _updateProgress;
  Timer? _restartUpdateProgress;
  bool isChunkIsNotReady = false;
  bool isServerInError = false;
  DateTime errorTime = DateTime.now();

  TranscriptCubit({
    required this.player,
  }) : super(TranscriptState.init(
    speed: AppSettings.getInstance().getSpeed(),
    fontSize: AppSettings.getInstance().getTextSize(),
    //selectedLang: AppSettings.getInstance().getLang()
  ));

  @override
  Future<void> close() {
    stopProgressUpdate();
    return super.close();
  }

  _startProgressUpdate() {
    stopProgressUpdate();
    _updateProgress = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      _progressUpdated();
    });
  }

  _restartProgressUpdate() {
    print("progress: _restartProgressUpdate");
    stopProgressUpdate();
    _restartUpdateProgress = Timer(const Duration(seconds: 3), () {
      _startProgressUpdate();
    });
  }

  stopProgressUpdate() {
    _loadChunkToken?.cancel();
    _updateProgress?.cancel();
    _restartUpdateProgress?.cancel();
  }

  loadLangList() async {
    var response = await repo.loadLangList();
    if(response.success) {
      emit(state.copyWith(langs: response.langs));
    }
  }

  selectLang(TranslateLang? lang) {
    if(lang == null) return;

    if(state.selectedLang?.code != lang.code) {
      settings.saveLang(lang);
      // remove old listeners
     stopProgressUpdate();
      // clear state
      emit(state.copyWith(
          selectedLang: lang,
          isLoading: false,
          isLangChanging: true,
          lastLoadedChunk: 0,
          lastDate: 0,
          list: [],
          wordList: [],
        progressMs: 0,
        lastLoadedFreeChunk: 0,

        //  chunks:[]
      ));
      lastPositionUpdate = 0;
      //start load with new lang
     _startProgressUpdate();
    }
  }


  startTranscript({
    required String slug,
    required String langCode
  }) async {
    if(state.langs.isEmpty) {
      loadLangList();
    }
    if(_slug != slug) {
      var lang = TranslateLang(code: langCode, title: langList[langCode]?.capitalize() ?? "");
      stopProgressUpdate();

      Future.delayed(const Duration( // wait stop player listener
        milliseconds: 300
      )).then((value) {
        emit(state.copyWith(
            isLoading: false,
            isLangChanging:false,
            isNotLoaded:false,
            lastLoadedChunk: 0,
            lastDate: 0,
            progressMs: 0,
            lastLoadedFreeChunk: 0,
            list: [],
            wordList: [],
            selectedLang: lang,
            radioLang: lang
        ));
        _slug = slug;
        lastPositionUpdate = 0;
        _startProgressUpdate();
      });
    } else {
      _startProgressUpdate();
    }
  }


  setSpeed(TranscriptSpeed speed) {

    if(state.speed != speed) {
      emit(state.copyWith(speed: speed));
      settings.setSpeed(speed);
      player.setSpeed(speed.speed);
    }
  }

  setFontSize(TranscriptFontSize size) {
    if(state.fontSize != size) {
      settings.setTextSize(size);
      emit(state.copyWith(fontSize: size));
    }
  }


  _progressUpdated() {

    int currentChunk = TranscriptHelper.getChunkId(player.position.value);
    int nextChunk = TranscriptHelper.getNextChunkId(player.position.value);

    //print("update progress currentChunk ${currentChunk}  nextChunk $nextChunk ${(player.position.value-TranscriptHelper.ADDED_DELAY) / TranscriptHelper.CHUNK_DURATION}");

    if(currentChunk < 0) {
      if(state.progressMs > 0) {
        emit(state.copyWith(progressMs:0));
      }
      return;
    }

    emit(state.copyWith(progressMs:player.position.value - timeTrOffset));


    if(!state.isLoading) {

      if(isChunkIsNotReady) {
        if(DateTime.now().difference(errorTime).inSeconds < 3) {
          return;
        }
        isChunkIsNotReady = false;
      }
      if(isServerInError) {
        if(DateTime.now().difference(errorTime).inSeconds < 5) {
          return;
        }
        isServerInError = false;
      }

      if(state.lastLoadedChunk < 0 || state.lastLoadedChunk < currentChunk) { // load current chunk
       // print("trascript: loadCurent");
        _loadChunks(currentChunk);
      } else {// load next chunk in buffer
        if(state.lastLoadedChunk != nextChunk) {
         // print("trascript: loadNext");
          _loadChunks(nextChunk);
        }
      }
    }
  }

  _loadChunks(int chunkId) async {
    print("progress: _loadChunks $chunkId");
    emit(state.copyWith(isLoading: true,error: ""));
    _loadChunkToken?.cancel();
    _loadChunkToken = CancelToken();
    var response = await repo.loadTranscript(
        radioSlug: _slug,
        chunkId: chunkId,
        lang:state.selectedLang?.code ?? "",
        cancelToken:_loadChunkToken
    );
    if(response.success) {
      List<TranscriptChunkLine> currentList = [];
      // if(state.list.length <= maxOldLines) {
      //   currentList = List.from(state.list);
      // } else {
      //   currentList = state.list.sublist(state.list.length - maxOldLines);
      // }

      currentList = List.from(state.list);


      List<TranscriptChunkLine> allLines = currentList + response.chunkList;
      List<TranscriptChunkWord> wordList = state.wordList
          //.where((e) => e.chunks.last.to < time)
          .toList() + response.wordList;
      // List<TranscriptChunk> chunks = [];
      // print("loadCHubk: wordList ${wordList.length}");
      // for (var line in allLines) {
      //   for (var e in line.words) {
      //     chunks.add(e);
      //     if(e.content.contains(".") || e.content.contains("!") || e.content.contains("?")) {
      //       chunks.add(TranscriptChunk.breakLine());
      //     }
      //   }
      // }
      print("progress: _loadChunks success $chunkId");
      emit(state.copyWith(
        isLoading: false,
        isLangChanging:false,
        isNotLoaded:allLines.isEmpty,
        lastLoadedChunk: chunkId,
        list: allLines,
          wordList:wordList,
          //chunks:chunks
      ));
    } else {
      print("progress: error load chunk ${chunkId} code ${response.code} isCancel ${response.isCanceled}");
      if(!response.isCanceled) {
        errorTime = DateTime.now();
        if(response.code == 404) {
          isChunkIsNotReady = true;
          isServerInError = false;
          print("progress: error load chunk ${chunkId} Wait 3 sec to restart");
        } else {
          isChunkIsNotReady = false;
          isServerInError = true;
          print("progress: error load chunk ${chunkId} Wait 5 sec to restart");
        }

        emit(state.copyWith(
            isLoading: false,
            isNotLoaded:state.list.isEmpty,
            error: response.message
        ));
      } else {
        emit(state.copyWith(
            isLoading: false
        ));
      }

    }
  }



}

class TranscriptState {
  final List<TranscriptChunkLine> list;
 // final List<TranscriptChunk> chunks;
  final List<TranscriptChunkWord> wordList;
  final List<TranslateLang> langs;
  final bool isLoading;
  final bool isNotLoaded;
  final bool isLangChanging;
  final int lastDate;
  final int lastLoadedChunk;
  final int lastLoadedFreeChunk;
  final String error;
  final double progressMs;
  final TranscriptFontSize fontSize;
  final TranscriptSpeed speed;
  final TranslateLang? selectedLang;
  final TranslateLang? radioLang;

  const TranscriptState({
    required this.list,
   // required this.chunks,
    required this.isLoading,
    required this.lastDate,
    required this.error,
    required this.lastLoadedChunk,
    required this.lastLoadedFreeChunk,
    required this.fontSize,
    required this.speed,
    required this.langs,
    required this.selectedLang,
    required this.radioLang,
    required this.wordList,
    required this.isLangChanging,
    required this.isNotLoaded,
    required this.progressMs,
  });

  const TranscriptState.init({
     this.list = const [],
     //this.chunks = const [],
     this.langs = const [],
     this.wordList = const [],
     this.isLoading = false,
     this.isNotLoaded = false,
     this.isLangChanging = false,
     this.lastDate = 0,
     this.lastLoadedChunk = 0,
     this.lastLoadedFreeChunk = 0,
     this.progressMs = 0,
     this.error = "",
     this.selectedLang,
     this.radioLang,
     this.fontSize = TranscriptFontSize.medium,
     this.speed = TranscriptSpeed.speedNormal,
  });

  TranscriptState copyWith({
    List<TranscriptChunkLine>? list,
    //List<TranscriptChunk>? chunks,
    List<TranscriptChunkWord>? wordList,
    List<TranslateLang>? langs,
    TranslateLang? selectedLang,
    TranslateLang? radioLang,
    bool? isLoading,
    bool? isNotLoaded,
    bool? isLangChanging,
    int? lastDate,
    int? lastLoadedChunk,
    int? lastLoadedFreeChunk,
    String? error,
    double? progressMs,
    TranscriptFontSize? fontSize,
    TranscriptSpeed? speed,
  }) {
    return TranscriptState(
      list: list ?? this.list,
      isLoading: isLoading ?? this.isLoading,
        isNotLoaded: isNotLoaded ?? this.isNotLoaded,
      lastDate: lastDate ?? this.lastDate,
      lastLoadedChunk: lastLoadedChunk ?? this.lastLoadedChunk,
        lastLoadedFreeChunk: lastLoadedFreeChunk ?? this.lastLoadedFreeChunk,
      error: error ?? this.error,
      fontSize: fontSize ?? this.fontSize,
      speed: speed ?? this.speed,
      //  chunks:chunks??this.chunks,
        langs:langs??this.langs,
        selectedLang:selectedLang ?? this.selectedLang,
        radioLang:radioLang ?? this.radioLang,
        wordList:wordList ?? this.wordList,
        isLangChanging:isLangChanging ?? this.isLangChanging,
        progressMs:progressMs ?? this.progressMs
    );
  }
}
