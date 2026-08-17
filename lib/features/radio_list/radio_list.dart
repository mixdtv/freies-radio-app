import 'package:flutter/material.dart';
import 'package:radiozeit/app/widgets/error_load.dart';
import 'package:radiozeit/app/widgets/shimmer.dart';
import 'package:radiozeit/data/model/now_playing.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/features/radio_list/radio_list_item.dart';
import 'package:radiozeit/features/radio_list/widget/radio_not_found_info.dart';

class RadioList extends StatelessWidget {
  final List<AppRadio> list;
  final List<String> favorites;
  final String error;
  final bool shrinkWrap;
  final bool isLoading;
  final ScrollPhysics? physics;
  final Future Function()? reload;
  final Function(AppRadio,bool) setFavorite;
  final Function(AppRadio) openRadio;

  /// Who currently has each aggregated station's stream, keyed by EPG slug.
  /// Arrives after the list itself, so rows render without it.
  final Map<String, NowPlaying> nowPlaying;

  const RadioList({super.key,
    required this.list,
    this.error ="",
    required this.isLoading,
    this.reload, required this.favorites, required this.setFavorite, required this.openRadio, this.shrinkWrap = false, this.physics, this.nowPlaying = const {}});


  @override
  Widget build(BuildContext context) {

    if(isLoading) {
      return Shimmer(
        child: ListView.separated(
          shrinkWrap: shrinkWrap,
          physics: physics,
          itemBuilder: (context, index) {
            return ShimmerLoading(child: RadioListItem.placeholder());
          },
          separatorBuilder: (context, index) => const SizedBox(height: 16,),
          itemCount: 10,
          padding: const EdgeInsets.all(16),
        ),
      );
    }

    if(list.isEmpty && error.isNotEmpty && reload != null) {
      return ErrorLoad(error: error, load: () => reload!(),);
    }
    if(reload != null) {
      return RefreshIndicator(
        onRefresh: reload!,
        color: Theme.of(context).colorScheme.onBackground,
        child: _content(),
      );
    } else {
      return _content();
    }

  }

  _content() {
    // Once per list, not once per row: a getter here read as free and was
    // rebuilding the whole index for every aggregated station on screen.
    final byEpgPrefix = NowPlaying.byEpgPrefix(list);

    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemBuilder: (context, index) {
        if(index == list.length) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: RadioNotFoundInfo(),
          );
        }
        var radio = list[index];
        var isFavorite = favorites.contains(radio.id);
        var onAir = nowPlaying[radio.epgPrefix];
        return RadioListItem(
          radio: radio,
          isFavorite: isFavorite,
          toggleFavorite: () => setFavorite(radio,!isFavorite),
          openRadio: () => openRadio(radio),
          nowPlaying: onAir,
          nowPlayingStudio: onAir?.studioOf(radio, byEpgPrefix),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 16,),
      itemCount: list.length + 1,
      padding: const EdgeInsets.symmetric(vertical: 16),
    );
  }
}
