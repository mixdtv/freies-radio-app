import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/utils/extensions.dart';

/// Every decision about how a member logo is seated, in one place.
///
/// This look is provisional and expected to change once the stations have seen
/// it, so the knobs live here rather than scattered through the widget below:
/// changing or reverting the presentation should be an edit to these constants
/// and nothing else. The alternatives were measured against the real logos, so
/// the notes below say what each dial actually costs.
///
/// The strip has 232 logical pixels on a 390 pt phone — 390 less the row's
/// 16/6 padding, the 64 pt station logo, both 16 pt gaps and the 40 pt
/// favourite button. Everything below is a trade against that budget.
class MemberLogoStyle {
  /// Logo height. The logos are wordmarks ranging from 1:1 to about 3:1, so
  /// they are laid out at a fixed height with the width left free — fitting
  /// them into squares either crops them to nonsense or shrinks them past
  /// legibility (14 is unusable, 18 is the floor).
  ///
  /// 26 is the largest size that costs no extra line: at 28 a nine-member
  /// strip wraps to three lines, and at 30 even a five-member one wraps to two.
  static const double height = 26;

  /// Space between the logo and the edge of its plate.
  ///
  /// Zero means the plate ends exactly where the artwork does, which is what
  /// keeps a full-bleed tile (colaboradio's black square, Radio Słubfurt's red
  /// mosaic) from showing a rim of not-quite-matching colour — a mosaic has no
  /// single edge colour to match in the first place.
  ///
  /// Raising this to 5–6 gives the "logo on a card" look. It costs more than it
  /// sounds: every chip grows by twice this in both directions, which took a
  /// nine-member strip from 57 px to 112 px and a five-member one from 26 px to
  /// 73 px. Pair it with [plate] so the rim is at least uniform.
  static const double padding = 0;

  /// One background for every member, or null to use each station's own
  /// `logoBgColor`.
  ///
  /// Only three logos need a plate at all — Studio Ansage, Radio Woltersdorf
  /// and Pi Radio, whose ring is cut out of its tile rather than painted white.
  /// The rest carry their own opaque background, so any plate is invisible
  /// behind them. Setting a uniform colour is therefore about calm in the
  /// strip, not legibility; `Color(0xFFE9E9E9)` was the muted grey we tried.
  ///
  /// It has to be opaque. A translucent plate resolves to whatever sits behind
  /// it, which on the dark theme's `#0E0E0F` is dark grey — the opposite of
  /// what a plate is for. Below about 85% opacity, dark lettering stops being
  /// readable on the dark theme.
  static const Color? plate = null;

  static const double radius = 3;

  /// Between chips on a line, and between lines.
  static const double gap = 6;
  static const double runGap = 5;

  /// Between the row's text and the first line of logos.
  static const double topGap = 5;
}

/// Logos of the stations that share an aggregated station's programme, shown
/// under the genre line in the station list.
///
/// A [Wrap] rather than a [Row]: a member that does not fit starts a new line
/// instead of being clipped away. See [MemberLogoStyle] for the sizing.
class MemberStrip extends StatelessWidget {
  final List<RadioMember> members;

  const MemberStrip({super.key, required this.members});

  /// Kept for callers and tests that reason about the strip's footprint.
  static double get logoHeight => MemberLogoStyle.height;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: MemberLogoStyle.topGap),
      child: Wrap(
        spacing: MemberLogoStyle.gap,
        runSpacing: MemberLogoStyle.runGap,
        children: members.map(_chip).toList(),
      ),
    );
  }

  Widget _chip(RadioMember member) {
    if (member.logo.isEmpty) return _NameChip(member: member);

    // ClipRRect and ColoredBox both take their size from the child, so the
    // plate ends where the artwork does. Neither may be swapped for a Container
    // with an alignment, or a Center: those expand to the width they are
    // offered, which makes every chip as wide as the row and turns the strip
    // into a vertical stack.
    return ClipRRect(
      borderRadius: BorderRadius.circular(MemberLogoStyle.radius),
      child: ColoredBox(
        color: MemberLogoStyle.plate ??
            CustomColor.parseCss(member.logoBgColor) ??
            Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(MemberLogoStyle.padding),
          child: CachedNetworkImage(
            imageUrl: member.logo,
            // A plain Image given only a height sizes to the intrinsic ratio;
            // CachedNetworkImage on its own fills the offered width instead.
            imageBuilder: (context, provider) => Image(
              image: provider,
              height: MemberLogoStyle.height,
              fit: BoxFit.contain,
            ),
            // A member is worth naming even when its logo will not load.
            errorWidget: (context, url, error) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _NameLabel(member: member),
            ),
            // Square while loading, so the strip does not reflow as logos land.
            placeholder: (context, url) => const SizedBox(
              height: MemberLogoStyle.height,
              width: MemberLogoStyle.height,
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      constraints: const BoxConstraints(minHeight: MemberLogoStyle.height),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MemberLogoStyle.radius),
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
