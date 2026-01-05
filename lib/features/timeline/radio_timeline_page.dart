import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:radiozeit/app/bottom_navigation/bottom_navigation_cubit.dart';
import 'package:radiozeit/app/widgets/shimmer.dart';
import 'package:radiozeit/app/style.dart';
import 'package:radiozeit/data/model/radio_program.dart';
import 'package:radiozeit/features/player/player_cubit.dart';
import 'package:radiozeit/features/radio_list/radio_list_page.dart';
import 'package:radiozeit/features/timeline/bloc/timeline_cubit.dart';
import 'package:radiozeit/features/timeline/timeline_list_item.dart';
import 'package:radiozeit/features/timeline/timeline_list_item_loading.dart';
import 'package:radiozeit/l10n/app_localizations.dart';
import 'package:radiozeit/utils/app_logger.dart';
import 'package:radiozeit/utils/colors.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

final _log = getLogger('Timeline');

class RadioTimeLinePage extends StatefulWidget {
  static const String path = "/RadioTimeLinePage";

  const RadioTimeLinePage({super.key});

  @override
  State<RadioTimeLinePage> createState() => _RadioTimeLinePageState();
}

class _RadioTimeLinePageState extends State<RadioTimeLinePage> {
  final ItemScrollController itemScrollController = ItemScrollController();
  bool isScrolled = false;
  @override
  void initState() {
    super.initState();
    _log.fine('initState called, isScrolled: $isScrolled');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TimeLineCubit>().loadFirstPage();
      context.read<PlayerCubit>().switchToLiveRadio();
      // Trigger scroll after data might already be loaded (e.g., returning to the page)
      _scrollToCurrent();
    });
  }

  _scrollToCurrent() {
    _log.fine('_scrollToCurrent called, isAttached: ${itemScrollController.isAttached}');
    if (!itemScrollController.isAttached) {
      _log.fine('Controller not attached, scheduling retry');
      // Retry after the next frame when the list should be built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !isScrolled) {
          _scrollToCurrent();
        }
      });
      return;
    }
    var state = context.read<TimeLineCubit>().state;
    _log.fine('activeEpg.id: ${state.activeEpg.id}, allEpg.length: ${state.allEpg.length}');
    if(state.activeEpg.id.isNotEmpty) {
      int index = state.allEpg.indexWhere((e) => e.id == state.activeEpg.id);
      _log.fine('Found index: $index');
      if(index >= 0) {
        isScrolled = true;
        itemScrollController.jumpTo(index: index);
        _log.fine('Scrolled to index: $index');
      }
    } else {
      _log.fine('activeEpg is empty, cannot scroll');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TimeLineCubit, TimeLineState>(
      listenWhen: (p, c) => p.activeEpg.id != c.activeEpg.id,
      listener: (context, state) {
        _log.fine('BlocListener triggered, isScrolled: $isScrolled, activeEpg: ${state.activeEpg.id}');
        if(!isScrolled) {
          _scrollToCurrent();
        }
      },
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            _appBar(),
            Expanded(
            child: Builder(builder: (context) {
              RadioEpg? activeEpg = context.select((TimeLineCubit cubit) => cubit.state.activeEpg,);
              bool isLoading = context.select((TimeLineCubit cubit) => cubit.state.isLoading,);
              List<RadioEpg> allEpg = context.select((TimeLineCubit cubit) => cubit.state.allEpg,);

              if (allEpg.isEmpty) {
                if (isLoading) {
                  return Shimmer(
                    child: ListView.builder(
                      itemCount: 5,
                      itemBuilder: (context, index) => const TimelineListItemLoading(),),
                  );
                }
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      AppLocalizations.of(context)!.timeline_no_shows,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => await context.read<TimeLineCubit>().loadFirstPage(),
                child: ScrollablePositionedList.builder(
                    itemScrollController: itemScrollController,
                    itemBuilder: (context, index) {
                      var item = allEpg[index];
                      final showDateHeader = index == 0 ||
                          !_isSameDay(allEpg[index - 1].start, item.start);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDateHeader) _buildDateHeader(context, item.start),
                          TimelineListItem(
                            isActive: activeEpg?.id == item.id,
                            program: item,
                            onPlay: () => _playProgram(item),
                          ),
                        ],
                      );
                    },
                    itemCount: allEpg.length
                ),
              );
            },),
          )
        ],
        ),
      ),
    );
  }

  _playProgram(RadioEpg program) {
    context.read<PlayerCubit>().playArchiveProgram(program);
  }

  _appBar() {
    return Container(
        decoration: BoxDecoration(
            gradient: AppGradient.getPanelGradient(context)
        ),
        child: SafeArea(child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BackButton(onPressed: () {
              context.read<BottomNavigationCubit>().openMenu(false);
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(RadioListPage.path);
              }
            },),
            Builder(
                builder: (context) {
                  String radioName = context.select((PlayerCubit cubit) => cubit.state.selectedRadio?.name ?? "");
                  return Text(radioName, style: Theme
                      .of(context)
                      .textTheme
                      .displayLarge,);
                }
            ),
            SizedBox(width: 46,)
          ],
        )));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateHeader(BuildContext context, DateTime date) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();

    String dateText;
    if (_isSameDay(date, now)) {
      dateText = 'Heute';
    } else if (_isSameDay(date, now.add(const Duration(days: 1)))) {
      dateText = 'Morgen';
    } else {
      dateText = DateFormat('EEEE, d. MMMM', 'de_DE').format(date);
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: textTheme.bodyLarge?.color?.withOpacity(0.2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              dateText,
              style: textTheme.bodyLarge?.copyWith(
                fontFamily: isDark ? AppStyle.fontInter : AppStyle.fontDMMono,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: textTheme.bodyLarge?.color?.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}