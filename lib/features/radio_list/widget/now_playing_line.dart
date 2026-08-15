import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:radiozeit/data/model/now_playing.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/features/radio_list/widget/member_strip.dart';
import 'package:radiozeit/utils/extensions.dart';

/// Which studio currently has an aggregated station's stream.
///
/// An aggregated station broadcasts on one line that its members take turns
/// filling, so the useful fact is not who the members are but which of them is
/// on it now — this is what you would hear on pressing play.
///
/// Shown in place of the [MemberStrip] once known. Until then, and for good if
/// the EPG never answers, the strip stays: it needs no second request, since
/// the members arrive with the station list itself.
class NowPlayingLine extends StatelessWidget {
  static const double _logoHeight = 20;
  static const double _dot = 7;

  final NowPlaying nowPlaying;

  /// The member this belongs to, when it could be identified — carries the
  /// logo and the station's own name. Null when the studio has no member entry,
  /// in which case the EPG's display name is shown alone.
  final RadioMember? studio;

  const NowPlayingLine({super.key, required this.nowPlaying, this.studio});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.color?.withOpacity(0.6);

    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Container(
            width: _dot,
            height: _dot,
            margin: const EdgeInsets.only(right: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFE0632F),
              shape: BoxShape.circle,
            ),
          ),
          Text(
            "JETZT",
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: muted,
            ),
          ),
          const SizedBox(width: 7),
          if (studio != null && studio!.logo.isNotEmpty) ...[
            _logo(studio!),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              studio?.name ?? nowPlaying.studioName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (nowPlaying.until != null) ...[
            const SizedBox(width: 8),
            Text(
              "bis ${_hhmm(nowPlaying.until!)}",
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _logo(RadioMember member) {
    // Same seating as the member strip: the plate is sized to the artwork, so
    // a full-bleed tile shows no rim and a transparent mark still gets its
    // backing. See MemberLogoStyle.
    return ClipRRect(
      borderRadius: BorderRadius.circular(MemberLogoStyle.radius),
      child: ColoredBox(
        color: CustomColor.parseCss(member.logoBgColor) ?? Colors.white,
        child: CachedNetworkImage(
          imageUrl: member.logo,
          imageBuilder: (context, provider) => Image(
            image: provider,
            height: _logoHeight,
            fit: BoxFit.contain,
          ),
          errorWidget: (context, url, error) => const SizedBox.shrink(),
          placeholder: (context, url) => const SizedBox(
            height: _logoHeight,
            width: _logoHeight,
          ),
        ),
      ),
    );
  }

  static String _hhmm(DateTime t) =>
      "${t.hour}:${t.minute.toString().padLeft(2, '0')}";
}
