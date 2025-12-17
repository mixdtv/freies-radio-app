import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:radiozeit/app/widgets/shimmer.dart';
import 'package:radiozeit/data/model/radio.dart';

class RadioListItemBig extends StatelessWidget {
  final AppRadio radio;
  final bool isFavorite;
  final Function() toggleFavorite;
  final Function() openRadio;

  const RadioListItemBig({super.key, required this.radio, required this.isFavorite, required this.toggleFavorite, required this.openRadio});



  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        InkWell(
          onTap: openRadio,
          child: Container(
            width: 150,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
             color: isDark ? Color(0xff2B282F) : Colors.white,
             borderRadius: BorderRadius.circular(6)
           ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 126,
                  height: 126,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    //  color: Theme.of(context).colorScheme.onBackground,
                      borderRadius: BorderRadius.circular(4)
                  ),
                  child: CachedNetworkImage(
                    imageUrl: radio.thumbnail,
                    width: 126,
                    height: 126,
                    errorWidget: (context, error, stackTrace) => Container(
                      width: 126,
                      height: 126,
                      decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(4)
                      ),
                    ),),
                ),
                const SizedBox(width: 16,),

                Text(radio.name,
                      maxLines: 1,
                      style: textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w700)),

                Text(radio.tags.join(", "),
                  maxLines:1,
                  style: textTheme.bodySmall?.copyWith(color: textTheme.bodySmall?.color?.withOpacity(0.5)),
                ),
              ],
            ),
          ),
        ),
        Positioned(
            top:0,
            right: 0,
            child:  InkWell(
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
        ))
      ],
    );
  }


  static Widget placeholder(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: isDark ? Color(0xff2B282F) : Colors.white,
          borderRadius: BorderRadius.circular(6)
      ),
      child: ShimmerLoading(
        child: Column(
          children: [
            Container(
              width: 126,
              height: 126,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4)
              ),
            ),
            const SizedBox(width: 16,),
            const SizedBox(height: 5,),
            Container(
                width: Random().nextInt(100) + 50,
                height: 16,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2)
                )
            ),
            const SizedBox(height: 5,),
            Container(
                width: Random().nextInt(150) + 50,
                height: 10,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2)
                )
            ),

          ],
        ),
      ),
    );
  }

}
