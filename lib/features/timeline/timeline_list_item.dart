import 'dart:math';

import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:radiozeit/app/style.dart';
import 'package:radiozeit/config/app_config.dart';
import 'package:radiozeit/data/model/radio_program.dart';
import 'package:radiozeit/utils/colors.dart';
import 'package:radiozeit/utils/extensions.dart';

class TimelineListItem extends StatefulWidget {
  final RadioEpg program;
  final bool isActive;
  final String stationName;
  final Function() onPlay;
  final Function()? onLive;

  const TimelineListItem({
    super.key,
    required this.program,
    required this.onPlay,
    required this.stationName,
    this.onLive,
    required this.isActive,
  });

  @override
  State<TimelineListItem> createState() => _TimelineListItemState();
}

class _TimelineListItemState extends State<TimelineListItem> {
  bool _isDescExpanded = false;

  /// Whether this program is in the past and can be played from archive
  bool get canPlayArchive => widget.program.end.isBefore(DateTime.now());

  /// Whether this program is in the future (hasn't started yet)
  bool get isFutureShow => widget.program.start.isAfter(DateTime.now());

  /// Whether this item is tappable (archive playback or live)
  bool get isTappable => (AppConfig.enableArchivePlayback && canPlayArchive) || widget.isActive;

  void _addToCalendar() async {
    final event = Event(
      title: widget.program.title,
      description: '${widget.program.subheadline}${widget.program.desc.isNotEmpty ? '\n\n${widget.program.desc}' : ''}',
      location: widget.stationName,
      startDate: widget.program.start,
      endDate: widget.program.end,
    );
    debugPrint('Adding to calendar: ${widget.program.title} at ${widget.program.start}');
    try {
      final success = await Add2Calendar.addEvent2Cal(event);
      debugPrint('Calendar result: $success');
    } catch (e) {
      debugPrint('Calendar error: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    TextTheme textTheme = Theme.of(context).textTheme;
    return Stack(
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              _mark(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6,left: 16,right: 16,bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${widget.program.start.toFormat("HH:mm")} ", //- ${widget.program.type}
                        style: textTheme.bodyLarge?.copyWith(
                            fontFamily: isDark ? AppStyle.fontInter : AppStyle.fontDMMono,
                            color:textTheme.bodyLarge?.color?.withOpacity(0.6)
                        )),
                      const SizedBox(height: 9,),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isTappable ? () {
                            if (!_isDescExpanded && widget.program.desc.isNotEmpty) {
                              setState(() => _isDescExpanded = true);
                            }
                            if (widget.isActive) {
                              widget.onLive?.call();
                            } else {
                              widget.onPlay();
                            }
                          } : null,
                          borderRadius: BorderRadius.circular(12),
                          splashColor: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.04),
                          highlightColor: isDark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.black.withOpacity(0.02),
                          child: Ink(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: AppGradient.getPanelGradient(context),
                              borderRadius: BorderRadius.circular(12)
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 62,
                                      height: 62,
                                      clipBehavior: Clip.hardEdge,
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(9),
                                          color: isDark ? Color(0xff2A272D) : Colors.white
                                      ),
                                      child: Image.network(widget.program.icon,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                        return Center(
                                            child: SvgPicture.asset("assets/icons/ic_on_air.svg",color: isDark ? Colors.white : Colors.black,));
                                      },),
                                    ),
                                    const SizedBox(width: 16,),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(widget.program.subheadline,style: textTheme.bodyLarge?.copyWith(
                                              fontFamily: isDark ? AppStyle.fontInter : AppStyle.fontDMMono,
                                              color:textTheme.bodyLarge?.color?.withOpacity(0.6) ),),
                                          Text(widget.program.title,style: textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w700)),
                                          Text(widget.program.hosts.join(" "),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: textTheme.bodyLarge?.copyWith(
                                              fontFamily: isDark ? AppStyle.fontInter : AppStyle.fontDMMono,
                                              color:textTheme.bodyLarge?.color?.withOpacity(0.6) )),
                                        ],
                                      ),
                                    ),
                                    if (AppConfig.enableArchivePlayback && canPlayArchive)
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: SvgPicture.asset(
                                          "assets/icons/ic_program_play.svg",
                                          color: isDark ? Colors.white : Colors.black54,
                                        ),
                                      ),
                                    if (isFutureShow)
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: _addToCalendar,
                                          borderRadius: BorderRadius.circular(20),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Icon(
                                              Icons.calendar_month_outlined,
                                              color: isDark ? Colors.white70 : Colors.black54,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (widget.program.desc.isNotEmpty)
                                  _buildDescription(textTheme)
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
        if(widget.isActive)
          Positioned(
            right: 32,
            top: 20,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 7,vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(20)
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset("assets/icons/ic_on_air.svg"),
                  const SizedBox(width: 8,),
                  const Text("ON AIR",style: TextStyle(
                    fontSize: 11,
                    height: 16/11,
                    color: Colors.white,
                    fontFamily: AppStyle.fontInter
                  ),)
                ],
              ),
            ),
          )
      ],
    );
  }




  Widget _buildDescription(TextTheme textTheme) {
    final descStyle = textTheme.bodyMedium?.copyWith(
      color: textTheme.bodyMedium?.color?.withOpacity(0.6),
    );
    // Heuristic: ~40 chars per line on mobile, 2 lines ≈ 80 chars
    final isLongText = widget.program.desc.length > 80;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          widget.program.desc,
          maxLines: _isDescExpanded ? 100 : 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.left,
          style: descStyle,
        ),
        if (isLongText)
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _isDescExpanded = !_isDescExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _isDescExpanded ? "weniger" : "mehr",
                  style: descStyle?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  _mark() {
    int type = Random().nextInt(4);
    Color colorType;
    switch (type) {
      case 0: colorType = Colors.yellow;
      case 1: colorType = Colors.green;
      case 2: colorType = Colors.blue;
      case 3: colorType = Colors.orange;
      default : colorType = Colors.red;
    }
    return Container(
      width: 6,
      color: colorType,
    );
  }
}
