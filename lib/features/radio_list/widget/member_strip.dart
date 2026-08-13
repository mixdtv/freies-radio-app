import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/utils/extensions.dart';

/// Logos of the stations that share an aggregated station's programme, shown
/// under the genre line in the station list.
///
/// The logos are wordmarks with aspect ratios from 1:1 to about 3:1, so they
/// are laid out at a fixed height with the width left free — squeezing them
/// into squares either crops them to nonsense or shrinks them to illegibility.
///
/// A list row leaves 232 logical pixels for this column on a 390 pt phone
/// (390 less the 16/6 padding, the 64 pt logo, both 16 pt gaps and the 40 pt
/// favourite button). At [logoHeight] four logos fill about 224 of it, so four
/// is all that fits on one line — hence [Wrap] rather than a [Row]: a fifth
/// member starts a second line instead of being clipped away.
///
/// Each logo sits on its own `logoBgColor`. Without that backing the members
/// whose artwork is an opaque black tile lose their edges on the dark theme's
/// ground, and one of them all but disappears.
///
/// That backing is sized to the artwork exactly, with no padding, because the
/// two kinds of logo in the wild need opposite things from it. Artwork that is
/// a full-bleed tile (colaboradio's black square, Radio Słubfurt's red mosaic)
/// covers the plate completely, so no rim of a not-quite-matching colour can
/// show — a mosaic has no single edge colour to match in the first place. A
/// mark on transparency (frrapó, Studio Ansage, and Pi Radio, whose ring is
/// cut out of the tile rather than painted white) gets the plate directly
/// behind its ink, which is what makes it readable on the dark theme. Padding
/// would serve the second kind and betray the first.
class MemberStrip extends StatelessWidget {
  static const double logoHeight = 22;
  static const double _chipPadding = 6;
  static const double _spacing = 6;
  static const double _radius = 3;

  final List<RadioMember> members;

  const MemberStrip({super.key, required this.members});

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Wrap(
        spacing: _spacing,
        runSpacing: 5,
        children: members.map(_chip).toList(),
      ),
    );
  }

  Widget _chip(RadioMember member) {
    if (member.logo.isEmpty) return _NameChip(member: member);

    // ClipRRect and ColoredBox both take their size from the child, so the
    // plate ends exactly where the artwork does. Note neither may be swapped
    // for a Container with an alignment or a Center: those expand to the width
    // they are offered, which makes every chip as wide as the row and turns
    // the strip into a vertical stack.
    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: ColoredBox(
        color: CustomColor.parseCss(member.logoBgColor) ?? Colors.white,
        child: CachedNetworkImage(
          imageUrl: member.logo,
          // A plain Image given only a height sizes to the intrinsic ratio;
          // CachedNetworkImage on its own fills the offered width instead.
          imageBuilder: (context, provider) => Image(
            image: provider,
            height: logoHeight,
            fit: BoxFit.contain,
          ),
          // A member is worth naming even when its logo will not load.
          errorWidget: (context, url, error) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: _chipPadding),
            child: _NameLabel(member: member),
          ),
          // Square while loading, so the strip does not reflow as logos arrive.
          placeholder: (context, url) => const SizedBox(
            height: logoHeight,
            width: logoHeight,
          ),
        ),
      ),
    );
  }
}

/// A member with no logo of its own — most guests that are not stations in the
/// app. Rendered as its name in a chip so the list stays complete.
class _NameChip extends StatelessWidget {
  final RadioMember member;

  const _NameChip({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: MemberStrip._chipPadding,
      ),
      constraints: const BoxConstraints(minHeight: MemberStrip.logoHeight),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MemberStrip._radius),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.25),
        ),
      ),
      child: _NameLabel(member: member),
    );
  }
}

class _NameLabel extends StatelessWidget {
  final RadioMember member;

  const _NameLabel({required this.member});

  @override
  Widget build(BuildContext context) {
    return Text(
      member.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
