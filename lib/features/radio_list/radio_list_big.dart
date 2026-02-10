import 'package:flutter/material.dart';
import 'package:radiozeit/app/widgets/error_load.dart';
import 'package:radiozeit/app/widgets/shimmer.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/features/radio_list/radio_list_item.dart';
import 'package:radiozeit/features/radio_list/radio_list_item_big.dart';
import 'package:radiozeit/features/radio_list/widget/radio_not_found_info.dart';

class RadioListBig extends StatelessWidget {
  final List<AppRadio> list;
  final List<String> favorites;
  final String error;
  final bool isLoading;
  final Future Function()? reload;
  final Function(AppRadio,bool) setFavorite;
  final Function(AppRadio) openRadio;

  const RadioListBig({super.key,
    required this.list,
    this.error = "",
    required this.isLoading,
    this.reload, required this.favorites, required this.setFavorite, required this.openRadio});


  @override
  Widget build(BuildContext context) {

    if(isLoading) {
      return Column(
        children: [
          Container(

            padding: const EdgeInsets.only(top: 45),
            child: Shimmer(
              child:  SizedBox(
                width: 649,
                child: Wrap(
                    runSpacing: 16,
                    spacing: 16,
                    children: List.generate(8, (index) => RadioListItemBig.placeholder(context)),
                ),

            )),
          ),
        ],
      );
    }

    if(list.isEmpty && error.isNotEmpty && reload != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 45),
        child: ErrorLoad(error: error, load: () => reload!(),),
      );
    }
    if(reload != null) {
      return RefreshIndicator(
        onRefresh: reload!,
        color: Theme.of(context).colorScheme.onBackground,
        child: _content(),
      );
    }
    return _content();

  }

  Widget _content() {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 45,horizontal: 16),
        child: Column(
          children: [
            SizedBox(
              width: 649,
              child: Wrap(
                alignment: WrapAlignment.start,
                runSpacing: 16,
                spacing: 16,
                children: list.map((e) => _rowItem(e)).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: RadioNotFoundInfo(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowItem(AppRadio radio) {
    var isFavorite = favorites.contains(radio.id);
    return RadioListItemBig(
      radio: radio,
      isFavorite: isFavorite,
      toggleFavorite: () => setFavorite(radio,!isFavorite),
      openRadio: () => openRadio(radio),
    );
  }
}
