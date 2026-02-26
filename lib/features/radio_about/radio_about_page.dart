import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:radiozeit/app/bottom_navigation/bottom_navigation_cubit.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/features/player/player_cubit.dart';
import 'package:radiozeit/features/radio_about/radio_description.dart';
import 'package:radiozeit/features/radio_about/top_songs.dart';
import 'package:radiozeit/features/radio_list/radio_list_page.dart';
import 'package:radiozeit/utils/adaptive/screen_type.dart';
import 'package:radiozeit/utils/colors.dart';
import 'package:radiozeit/utils/extensions.dart';

class RadioAboutPage extends StatelessWidget {
  static const String path = "/RadioAboutPage";

  const RadioAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    AppRadio? radio = context.select((PlayerCubit cubit) => cubit.state.selectedRadio);
    bool isBigScreen = ScreenType.getFormFactor(context) == ScreenType.big;
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          _appBar(context),
          Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 28),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isBigScreen ? 500 : double.infinity
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: isBigScreen ? MainAxisAlignment.center : MainAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: CustomColor.parseCss(radio?.iconColor ?? ''),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: CachedNetworkImage(
                          imageUrl: radio?.icon ?? "",
                          height: 72,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24,),
                  RadioDescription(text: radio?.desc?? ""),
                  const SizedBox(height: 38,),
                  TopSongs(songs: radio?.topSongs ?? []),

                ],
              ),
            ),
          ),
        )

      ],
      ),
    );
  }

  _appBar(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            gradient: AppGradient.getPanelGradient(context)
        ),
        child: SafeArea(child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BackButton(onPressed: () {
              context.read<BottomNavigationCubit>().openMenu(false);
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(RadioListPage.path);
              }
            },),
            Builder(
              builder: (context) {
                String radioName = context.select((PlayerCubit cubit) => cubit.state.selectedRadio?.name ?? "");
                return Text(radioName,style: Theme.of(context).textTheme.displayLarge,);
              }
            ),
            const SizedBox(width: 46,)
          ],
        )));
  }
}