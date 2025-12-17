import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:radiozeit/app/app_state.dart';
import 'package:radiozeit/app/bottom_navigation/bottom_navigation_cubit.dart';
import 'package:radiozeit/app/global_cubit_connection.dart';
import 'package:radiozeit/features/location/location_cubit.dart';
import 'package:radiozeit/features/player/player_cubit.dart';
import 'package:radiozeit/features/radio_list/cubit/radio_favorite_cubit.dart';
import 'package:radiozeit/features/radio_list/cubit/radio_list_cubit.dart';
import 'package:radiozeit/features/timeline/bloc/timeline_cubit.dart';
import 'package:radiozeit/features/transcript/bloc/transcript_cubit.dart';
import 'package:radiozeit/features/podcast/bloc/podcast_cubit.dart';
import 'package:radiozeit/data/api/repository.dart';

class AppScope extends StatelessWidget {
  final Widget child;

  const AppScope({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(providers: [

      BlocProvider(create: (context) => RadioListCubit(),),
      BlocProvider(create: (context) => RadioFavoriteCubit(),),
      BlocProvider(create: (context) => TimeLineCubit(),),
      BlocProvider(create: (context) => BottomNavigationCubit(),),
      BlocProvider(create: (context) {
        return TranscriptCubit(
          player: context.read<PlayerCubit>().player,
        );
      },),
      BlocProvider(create: (context) => PodcastCubit(repository: Repository.getInstance())),

    ], child: AppState(child: GlobalCubitConnection(child: child)));
  }
}
