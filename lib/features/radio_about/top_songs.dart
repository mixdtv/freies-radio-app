import 'package:flutter/material.dart';
import 'package:radiozeit/app/style.dart';

import '../../data/model/song_info.dart';
import 'package:radiozeit/l10n/app_localizations.dart';

class TopSongs extends StatelessWidget {
  final List<SongInfo> songs;
  const TopSongs({super.key, required this.songs});

  @override
  Widget build(BuildContext context) {
    if(songs.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.page_about_title_top_song,style: Theme.of(context).textTheme.displayLarge,),
        ListView.separated(
          shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
                return _songView(context: context,index: index,info: songs[index]);
            },
            separatorBuilder: (context, index) {
              return Divider(color: Colors.black.withOpacity(0.1),height: 24,thickness: 1,);
            },
            itemCount: songs.length
        ),
      ],
    );
  }

  Widget _songView({
    required BuildContext context,
    required int index,
    required SongInfo info
}) {
    TextTheme textTheme = Theme.of(context).textTheme;
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Text(index.toString(),style: textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w900)),
        Container(
          clipBehavior: Clip.hardEdge,
          width: 48,height: 48,
          margin: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9)
          ),
          child: Image.network(info.icon,width: 48,height: 48,),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(info.name,style:textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w600)),
              Text(info.artist,style:textTheme.titleSmall?.copyWith(
                  fontFamily: isDark ? AppStyle.fontInter : AppStyle.fontDMMono,
                  color: textTheme.titleSmall?.color?.withOpacity(0.6))),
            ],
          ),
        )
      ],
    );
  }
}
