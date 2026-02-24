import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_presentation/bloc_presentation.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:radiozeit/data/api/repository.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/data/model/radio_program.dart';
import 'package:radiozeit/utils/extensions.dart';

class TimeLineEvent {

}
class TimeLineUpdateEvent extends TimeLineEvent {
  List<RadioEpg> epg;
  TimeLineUpdateEvent(this.epg);
}


class TimeLineCubit extends Cubit<TimeLineState> with BlocPresentationMixin<TimeLineState,TimeLineEvent>{
  Repository repo = Repository.getInstance();
  String epgSlug = "";
  int lastUpdateListTime = 0;
  Timer? updateProgress;
  CancelToken? cancelToken;

  TimeLineCubit() : super(TimeLineState.init());

  DateTime getPlayingDate() {
    return DateTime.now();
  }

  @override
  close() async {
    updateProgress?.cancel();
    cancelToken?.cancel();
    super.close();
  }

  selectRadio(AppRadio radio) {
    if(epgSlug != radio.epgPrefix) {
      cancelToken?.cancel();
      epgSlug = radio.epgPrefix;
      emit(state.copyWith(
          allEpg: [],
          futureEpg: [],
          activeRadio: radio,
          progress: 0,
          activeEpg: RadioEpg.empty()
      ));
      loadFirstPage();
      _startProgressTimer();
    }
  }

  /// Set a target program to scroll to when the timeline loads.
  scrollToProgram(String programId) {
    emit(state.copyWith(scrollToId: programId));
  }

  clearScrollTarget() {
    emit(state.copyWith(clearScrollToId: true));
  }

  pauseView() {
    updateProgress?.cancel();
  }

  unPauseView() {
    if(state.activeRadio != null) {
      _startProgressTimer();
      _updateEpg();
    }
  }

  _startProgressTimer() {
    updateProgress?.cancel();
    updateProgress = Timer.periodic(const Duration(seconds: 5), (timer) {
      //print("Update progress");
      _updateEpg();
    });
  }

  /// Lookback window matching the backend's EPG_LOOKBACK_DAYS.
  static const int _lookbackDays = 7;

  Future<void> loadFirstPage() async {
    await _load();
  }

  _load() async {
    emit(state.copyWith(isLoading: true,errorLoad: ""));
    cancelToken = CancelToken();
    final now = DateTime.now();
    var response = await repo.loadEpg(
        epgSlug: epgSlug,
        from: now.subtract(const Duration(days: _lookbackDays)),
        to: now.add(const Duration(days: _lookbackDays)),
      cancelToken: cancelToken
    );
    lastUpdateListTime = DateTime.now().millisecondsSinceEpoch;
    if(response.success) {
      DateTime playingDate = getPlayingDate();
      List<RadioEpg> allEpg = state.allEpg.combineWith(response.list);
      allEpg.sort((a, b) => a.start.compareTo(b.start));
      List<RadioEpg> futureEpg = allEpg.where((e) => playingDate.isBefore(e.end)).toList();

      emit(state.copyWith(
          isLoading: false,
          allEpg: allEpg,
          futureEpg: futureEpg
      ));
      _updateEpg();
    } else {
      if(!response.isCanceled) {
        emit(state.copyWith(isLoading: false, errorLoad: response.message));
      }
    }
  }



  _updateEpg() {
    DateTime now = getPlayingDate();

    if(state.activeEpg.id.isEmpty  || !state.activeEpg.isOnAir(now)) {
      int activeEpgIndex = state.futureEpg.indexWhere((epg) => epg.isOnAir(now));

      if(activeEpgIndex >= 0) {
        var activeEpg = state.futureEpg[activeEpgIndex];
        emit(state.copyWith(
            progress: activeEpg.getProgress(now),
            activeEpg: activeEpg,
            futureEpg: state.futureEpg.sublist(activeEpgIndex)
        ));
      } else {
        _needUpdateEpgList();
      }
    } else {
      emit(state.copyWith(
          progress: state.activeEpg.getProgress(now),

      ));
    }
  }

  _needUpdateEpgList() {
    if(!state.isLoading && DateTime.now().millisecondsSinceEpoch - lastUpdateListTime > 1 * 60000 ) {
      loadFirstPage();
    }
  }
}

@immutable
class TimeLineState {
  final List<RadioEpg> allEpg;
  final List<RadioEpg> futureEpg;
  final RadioEpg activeEpg;
  final AppRadio? activeRadio;
  final String errorLoad;
  final bool isLoading;
  final int progress;
  /// If set, the timeline page should scroll to this program ID instead of activeEpg.
  final String? scrollToId;

  const TimeLineState({
    required this.activeRadio,
    required this.allEpg,
    required this.errorLoad,
    required this.isLoading,
    required this.activeEpg,
    required this.futureEpg,
    required this.progress,
    this.scrollToId,
  });

  TimeLineState.init({
     this.allEpg = const [],
     this.futureEpg = const [],
     this.errorLoad = "",
     this.isLoading = false,
     this.progress = 0,
     this.activeRadio,
     this.scrollToId,
  }) : this.activeEpg = RadioEpg.empty();

  TimeLineState copyWith({
    List<RadioEpg>? allEpg,
    List<RadioEpg>? futureEpg,
    String? errorLoad,
    bool? isLoading,
    int? progress,
    RadioEpg? activeEpg,
    AppRadio? activeRadio,
    String? scrollToId,
    bool clearScrollToId = false,
  }) {
    return TimeLineState(
      allEpg: allEpg ?? this.allEpg,
      errorLoad: errorLoad ?? this.errorLoad,
      isLoading: isLoading ?? this.isLoading,
      activeEpg: activeEpg ?? this.activeEpg,
      futureEpg: futureEpg ?? this.futureEpg,
      progress: progress ?? this.progress,
      activeRadio: activeRadio ?? this.activeRadio,
      scrollToId: clearScrollToId ? null : (scrollToId ?? this.scrollToId),
    );
  }

}
