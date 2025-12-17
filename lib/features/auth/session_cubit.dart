import 'package:bloc/bloc.dart';
import 'package:bloc_presentation/bloc_presentation.dart';
import 'package:radiozeit/utils/settings.dart';

class SessionEvents {}

class SessionStartEvent extends SessionEvents {
  String deviceId;
  SessionStartEvent(this.deviceId);
}

class SessionEndEvent extends SessionEvents {}

class SessionCubit extends Cubit<SessionState>
    with BlocPresentationMixin<SessionState, SessionEvents> {
  AppSettings settings;
  final String deviceId;

  SessionCubit({
    required this.settings,
    required this.deviceId,
  }) : super(SessionState(lang: settings.getAppLang()));

  void initializeSession() {
    emitPresentation(SessionStartEvent(deviceId));
  }

  selectLang(String lang) {
    if (state.lang == lang) return;

    settings.setAppLang(lang);
    emit(state.copyWith(lang: lang));
  }
}

class SessionState {
  final String lang;

  const SessionState({
    this.lang = "en",
  });

  SessionState copyWith({
    String? lang,
  }) {
    return SessionState(
      lang: lang ?? this.lang,
    );
  }
}
