import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:radiozeit/features/location/location_cubit.dart';
import 'package:radiozeit/features/radio_list/cubit/radio_list_cubit.dart';
import 'package:radiozeit/features/timeline/bloc/timeline_cubit.dart';

class AppState extends StatefulWidget {
  final Widget child;

  const AppState({super.key, required this.child});
  @override
  _AppStateState createState() => _AppStateState();
}

class _AppStateState extends State<AppState> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {

    _listener = AppLifecycleListener(
        onPause: _pauseApp,
        onRestart: _unPauseApp,
        onDetach: _stopApp
    );
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _startApp();
    },);
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  _startApp() {
    context.read<RadioListCubit>().startLoadRadio();
    context.read<LocationCubit>().onStartApp();
  }

  _pauseApp() {
    context.read<TimeLineCubit>().pauseView();
  }

  _unPauseApp() {
    context.read<RadioListCubit>().unPauseView();
    context.read<TimeLineCubit>().unPauseView();
    context.read<LocationCubit>().onStartApp();
  }

  _stopApp() {

  }
}
