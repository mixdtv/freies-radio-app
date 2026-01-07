import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:radiozeit/app/bottom_navigation/app_menu_bottom.dart';
import 'package:radiozeit/app/drawer/app_drawer.dart';
import 'package:radiozeit/app/global_cubit_connection.dart';
import 'package:radiozeit/data/model/radio_program.dart';
import 'package:radiozeit/features/player/widgets/player_controls.dart';
import 'package:radiozeit/features/player/widgets/player_progress.dart';
import 'package:radiozeit/features/radio_list/cubit/radio_list_cubit.dart';
import 'package:radiozeit/features/radio_list/radio_list_page.dart';
import 'package:radiozeit/features/timeline/bloc/timeline_cubit.dart';
import 'package:radiozeit/features/transcript/bloc/transcript_cubit.dart';
import 'package:radiozeit/utils/colors.dart';

class AppPage extends StatefulWidget {
  final Widget child;

  const AppPage({super.key, required this.child});

  @override
  _AppPageState createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        final location = GoRouter.of(context).routeInformationProvider.value.uri.path;
        if (location == RadioListPage.path) {
          // On RadioListPage - exit app
          Navigator.of(context, rootNavigator: true).maybePop();
        } else {
          // On other pages - go to RadioListPage
          context.go(RadioListPage.path);
        }
      },
      child: Scaffold(
        drawer: AppDrawer(),
        bottomNavigationBar: const AppMenuBottom(),
        body: widget.child,
      ),
    );
  }

}
