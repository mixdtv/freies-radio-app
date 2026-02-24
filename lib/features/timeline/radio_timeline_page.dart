import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:radiozeit/app/bottom_navigation/bottom_navigation_cubit.dart';
import 'package:radiozeit/app/widgets/shimmer.dart';
import 'package:radiozeit/app/style.dart';
import 'package:radiozeit/data/model/radio_program.dart';
import 'package:radiozeit/features/player/player_cubit.dart';
import 'package:radiozeit/features/radio_about/radio_about_page.dart';
import 'package:radiozeit/features/radio_list/radio_list_page.dart';
import 'package:radiozeit/features/timeline/bloc/timeline_cubit.dart';
import 'package:radiozeit/features/timeline/timeline_list_item.dart';
import 'package:radiozeit/features/timeline/timeline_list_item_loading.dart';
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
    var cubit = context.read<TimeLineCubit>();
    var state = cubit.state;
    // Prefer scrollToId (from search) over activeEpg
    final targetId = state.scrollToId ?? state.activeEpg.id;
    _log.fine('targetId: $targetId, activeEpg.id: ${state.activeEpg.id}, allEpg.length: ${state.allEpg.length}');
    if(targetId.isNotEmpty) {
      int index = state.allEpg.indexWhere((e) => e.id == targetId);
      _log.fine('Found index: $index');
      if(index >= 0) {
        isScrolled = true;
        try {
          itemScrollController.jumpTo(index: index);
          _log.fine('Scrolled to index: $index');
          if (state.scrollToId != null) cubit.clearScrollTarget();
        } catch (e) {
          _log.warning('Failed to scroll: $e, retrying...');
          isScrolled = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !isScrolled) {
              _scrollToCurrent();
            }
          });
        }
      }
    } else {
      _log.fine('activeEpg is empty, cannot scroll');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<TimeLineCubit, TimeLineState>(
          listenWhen: (p, c) => p.activeEpg.id != c.activeEpg.id,
          listener: (context, state) {
            _log.fine('BlocListener triggered, isScrolled: $isScrolled, activeEpg: ${state.activeEpg.id}');
            if(!isScrolled) {
              _scrollToCurrent();
            }
          },
        ),
        // Scroll to searched program when data loads with a pending scroll target
        BlocListener<TimeLineCubit, TimeLineState>(
          listenWhen: (p, c) =>
              c.scrollToId != null &&
              (p.scrollToId != c.scrollToId || p.allEpg.length != c.allEpg.length),
          listener: (context, state) {
            _log.fine('Scroll target pending: ${state.scrollToId}, allEpg: ${state.allEpg.length}');
            isScrolled = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !isScrolled) {
                _scrollToCurrent();
              }
            });
          },
        ),
        // Redirect to About page if station has no program data
        BlocListener<TimeLineCubit, TimeLineState>(
          listenWhen: (p, c) => p.isLoading && !c.isLoading,
          listener: (context, state) {
            if (state.allEpg.isEmpty && !state.isLoading) {
              _log.info('No EPG data, navigating to About page');
              context.read<BottomNavigationCubit>().toPage(4);
              context.pushReplacement(RadioAboutPage.path);
            }
          },
        ),
      ],
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
              String stationName = context.select((TimeLineCubit cubit) => cubit.state.activeRadio?.name ?? '',);

              if (allEpg.isEmpty) {
                if (isLoading) {
                  return Shimmer(
                    child: ListView.builder(
                      itemCount: 5,
                      itemBuilder: (context, index) => const TimelineListItemLoading(),),
                  );
                }
                // BlocListener will redirect to About page
                return const SizedBox.shrink();
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
                            stationName: stationName,
                            onPlay: () => _playProgram(item),
                            onLive: () => _switchToLive(),
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

  _switchToLive() {
    context.read<PlayerCubit>().switchToLiveRadio();
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