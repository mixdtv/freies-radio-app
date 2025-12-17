import 'package:flutter/material.dart';
import 'package:radiozeit/app/widgets/shimmer.dart';
import 'package:radiozeit/features/location/model/location_city.dart';
import 'package:radiozeit/features/location/widgets/city_preview.dart';

class CityList extends StatelessWidget {
  final bool shrinkWrap;
  final bool isLoading;
  final ScrollPhysics? physics;
  final Function(LocationCity) onSelectCity;
  final List<LocationCity> list;

  const CityList({super.key,
    required this.shrinkWrap,
    this.physics,
    required this.onSelectCity,
    required this.isLoading,
    required this.list,
  });

  @override
  Widget build(BuildContext context) {
    if(isLoading) {
      return Shimmer(
        child: ListView.separated(
          shrinkWrap: shrinkWrap,
          physics: physics,
          itemBuilder: (context, index) {
            return ShimmerLoading(child: CityPreview.placeholder(context));
          },
          separatorBuilder: (context, index) => const Divider(height: 1,),
          itemCount: 3,
          padding: const EdgeInsets.all(16),
        ),
      );
    }

    return ListView.separated(
        shrinkWrap: shrinkWrap,
        physics: physics,
        itemBuilder: (context, index) => CityPreview(
            city:list[index],
            onSelect:() => onSelectCity(list[index])
        ),
        separatorBuilder: (context, index) => const Divider(height: 1,),
        itemCount: list.length,
      padding: const EdgeInsets.all(16),
    );
  }


}
