import 'package:flutter/material.dart';
import 'package:radiozeit/app/widgets/error_load.dart';
import 'package:radiozeit/app/widgets/shimmer.dart';
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

  const RadioList({super.key,
    required this.list,
    this.error ="",
    required this.isLoading,
    this.reload, required this.favorites, required this.setFavorite, required this.openRadio, this.shrinkWrap = false, this.physics});


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
        return RadioListItem(
          radio: radio,
          isFavorite: isFavorite,
          toggleFavorite: () => setFavorite(radio,!isFavorite),
          openRadio: () => openRadio(radio),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 16,),
      itemCount: list.length + 1,
      padding: const EdgeInsets.symmetric(vertical: 16),
    );
  }
}
