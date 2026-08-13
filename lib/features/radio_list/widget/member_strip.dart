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

    return Container(
      height: logoHeight + _chipPadding * 2,
      padding: const EdgeInsets.symmetric(horizontal: _chipPadding),
      decoration: BoxDecoration(
        color: CustomColor.parseCss(member.logoBgColor) ?? Colors.white,
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: Center(
        child: CachedNetworkImage(
          imageUrl: member.logo,
          height: logoHeight,
          fit: BoxFit.contain,
          // A member is worth naming even when its logo will not load.
          errorWidget: (context, url, error) => _NameLabel(member: member),
          placeholder: (context, url) => const SizedBox(height: logoHeight),
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
      height: MemberStrip.logoHeight + MemberStrip._chipPadding * 2,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MemberStrip._radius),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.25),
        ),
      ),
      child: Center(child: _NameLabel(member: member)),
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
