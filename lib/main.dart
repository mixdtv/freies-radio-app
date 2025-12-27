import 'package:android_id/android_id.dart';
import 'package:logging/logging.dart';
import 'package:radiozeit/utils/app_logger.dart';
import 'package:audio_service/audio_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:radiozeit/features/auth/session_cubit.dart';
import 'package:radiozeit/features/auth/splash_page.dart';
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
   initLogging(level: Level.INFO);

   WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
   FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  AppSettings settings =  AppSettings.getInstance();
  await settings.loadSettings();
    String deviceId = await settings.getDeviceId();

   Repository.getInstance().init(deviceId);


  String initPage;
  if (settings.isFirstStart) {
    initPage = SplashPage.path;
  } else {
    initPage = RadioListPage.path;
  }
   GoRouter router = AppNavigation.initAppRouter(
      initPage: initPage
  );

  var mediaPlayer = MediaPlayer();

  _audioHandler = await AudioService.init(
    builder: () => mediaPlayer,

    config: const AudioServiceConfig(
      androidNotificationChannelId: 'it.radiozeit.nkl.channel.audio',
      androidNotificationChannelName: 'Freies Radio',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'drawable/radio_icon',
      androidStopForegroundOnPause: true,
    ),
  );
 //  _audioHandler.configure(AudioSessionConfiguration.music());

   mediaPlayer.setSpeed(settings.getSpeed().speed);

  FlutterNativeSplash.remove();

  runApp(MultiBlocProvider(
    providers: [
      BlocProvider(create: (context) => SessionCubit(
          settings: AppSettings.getInstance(),
          deviceId: deviceId,
      )),
      BlocProvider(create: (context) => PlayerCubit(mediaPlayer)),
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

