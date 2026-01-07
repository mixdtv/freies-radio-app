import 'package:android_id/android_id.dart';
import 'package:logging/logging.dart';
import 'package:radiozeit/utils/app_logger.dart';
import 'package:audio_service/audio_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:radiozeit/config/app_config.dart';
import 'package:radiozeit/features/auth/session_cubit.dart';
import 'package:radiozeit/features/location/location_request_page.dart';
import 'package:radiozeit/features/radio_list/radio_list_page.dart';
import 'package:radiozeit/app/router.dart';
import 'package:radiozeit/app/style.dart';
import 'package:radiozeit/app/theme_cubit.dart';
import 'package:radiozeit/data/api/repository.dart';
import 'package:radiozeit/features/location/location_cubit.dart';
import 'package:radiozeit/features/player/media_player.dart';
import 'package:radiozeit/features/player/player_cubit.dart';
import 'package:radiozeit/utils/settings.dart';
import 'package:radiozeit/l10n/app_localizations.dart';

// final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
// final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');
late AudioHandler _audioHandler;
Future<void> main() async {
   // Fail fast if environment is not configured
   AppConfig.validateEnv();

   initLogging(level: Level.INFO);

   WidgetsFlutterBinding.ensureInitialized();

  AppSettings settings =  AppSettings.getInstance();
  await settings.loadSettings();

  String deviceId = await settings.getDeviceId();

   Repository.getInstance().init(deviceId);

  String initPage;
  if (settings.isFirstStart) {
    initPage = LocationRequestPage.path;
  } else {
    initPage = RadioListPage.path;
  }
   GoRouter router = AppNavigation.initAppRouter(
      initPage: initPage
  );

  var mediaPlayer = MediaPlayer();

  // Initialize audio service in background (don't block UI)
  AudioService.init(
    builder: () => mediaPlayer,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'de.radiozeit.freiesradio.channel.audio',
      androidNotificationChannelName: 'Freies Radio',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidStopForegroundOnPause: true,
    ),
  ).then((handler) {
    _audioHandler = handler;
    mediaPlayer.setSpeed(settings.getSpeed().speed);
  });

  runApp(MultiBlocProvider(
    providers: [
      BlocProvider(create: (context) => SessionCubit(
          settings: AppSettings.getInstance(),
          deviceId: deviceId,
      )),
      BlocProvider(create: (context) => PlayerCubit(mediaPlayer, deviceId: deviceId)),
      BlocProvider(create: (context) => ThemeCubit(settings.getThemeType()),),
      BlocProvider(create: (context) => LocationCubit(),),
    ],
    child: Builder(
      builder: (context) {
        String themeType = context.select((ThemeCubit bloc) => bloc.state.themeType);
        String lang = context.select((SessionCubit bloc) => bloc.state.lang);
        bool isDark;
        if(themeType == AppStyle.themeAuto) {
          isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
        } else {
          isDark = themeType == AppStyle.themeDark;
        }
        return MaterialApp.router(
          theme: AppStyle.light(),
          darkTheme: AppStyle.dark(),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          routerConfig: router,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: Locale(lang),
          supportedLocales: [
            Locale('en'), // English
            Locale('de'), // De
          ],
        );
      }
    ),
  ));
}

