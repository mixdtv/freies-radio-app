import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:radiozeit/features/location/model/location_city.dart';

class CityPreview extends StatelessWidget {
  final LocationCity city;
  final Function() onSelect;

  const CityPreview({super.key, required this.city, required this.onSelect});

  static Widget placeholder(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.6,
            height: 17,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Colors.white
            ),
          ),
          Expanded(child: const SizedBox(width: 10,)),
          SvgPicture.asset("assets/icons/ic_arrow_right.svg",width: 24,color: Theme.of(context).colorScheme.onBackground,)
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelect,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(child: Text(city.city.name, style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w500),)),
            const SizedBox(width: 10,),
            SvgPicture.asset("assets/icons/ic_arrow_right.svg",width: 24,color: Theme.of(context).colorScheme.onBackground,)
          ],
        ),
      ),
    );
  }
}
