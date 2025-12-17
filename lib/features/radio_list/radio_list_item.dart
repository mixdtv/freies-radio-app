import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/utils/extensions.dart';

class RadioListItem extends StatelessWidget {
  final AppRadio radio;
  final bool isFavorite;
  final Function() toggleFavorite;
  final Function() openRadio;

  const RadioListItem({super.key, required this.radio, required this.isFavorite, required this.toggleFavorite, required this.openRadio});



  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;
    return InkWell(

      onTap: openRadio,
      child: Padding(
        padding: const EdgeInsets.only(left: 16,right: 6),
        child: Row(
          children: [
          Container(
              width: 64,
              height: 64,
              padding: EdgeInsets.all(2),
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: CustomColor.parseCss(radio.iconColor) ?? Theme.of(context).colorScheme.onBackground,
                  borderRadius: BorderRadius.circular(4)
              ),
              child: CachedNetworkImage(
                imageUrl: radio.thumbnail,
                width: double.infinity,
                height: double.infinity,
                errorWidget: (context, error, stackTrace) => Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(4)
                ),
              ),),
            ),
            const SizedBox(width: 16,),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(radio.name,style: textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w700)),
                  Text(radio.tags.join(", "),style: textTheme.bodySmall,),
                ],
              ),
            ),
            const SizedBox(width: 16,),
            InkWell(
              onTap: toggleFavorite,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 10),
                child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isFavorite
                        ? SvgPicture.asset("assets/icons/ic_favorite_fill.svg",color: Theme.of(context).colorScheme.onBackground,)
                        : SvgPicture.asset("assets/icons/ic_favorite.svg",color: Theme.of(context).colorScheme.onBackground,),
                ),
              ),
            )

          ],
        ),
      ),
    );
  }


  static Widget placeholder() {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4)
          ),
        ),
        const SizedBox(width: 16,),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                width: 100,
              height: 16,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2)
                )
            ),
            const SizedBox(height: 5,),
            Container(
              width: 150,
              height: 10,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2)
                )
            ),
          ],
        )

      ],
    );
  }

}
