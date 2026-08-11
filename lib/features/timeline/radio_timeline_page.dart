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
import 'package:radiozeit/l10n/app_localizations.dart';
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
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
  bool isScrolled = false;

  /// Fraction of the viewport kept free above a programme we scroll to.
  static const double _listAlignment = 0.09;
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
    String targetId = state.scrollToId ?? _currentTargetId(state);
    _log.fine('targetId: $targetId, activeEpg.id: ${state.activeEpg.id}, allEpg.length: ${state.allEpg.length}');
    if(targetId.isNotEmpty) {
      int index = state.allEpg.indexWhere((e) => e.id == targetId);
      _log.fine('Found index: $index');
      if(index >= 0) {
        isScrolled = true;
        try {
          itemScrollController.jumpTo(index: index, alignment: _listAlignment);
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
      _log.fine('No program to scroll to');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<TimeLineCubit, TimeLineState>(
          listenWhen: (p, c) =>
              p.activeEpg.id != c.activeEpg.id ||
              (p.futureEpg.isEmpty && c.futureEpg.isNotEmpty),
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
        // Redirect to About page if station has no program data (only on first load)
        BlocListener<TimeLineCubit, TimeLineState>(
          listenWhen: (p, c) => p.isLoading && !c.isLoading,
          listener: (context, state) {
            final cubit = context.read<TimeLineCubit>();
            if (state.allEpg.isEmpty && !state.isLoading && !cubit.skipEmptyEpgRedirect) {
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
                return Center(
                  child: Text(AppLocalizations.of(context)?.timeline_no_shows ?? ''),
                );
              }

              return Stack(
                children: [
                  RefreshIndicator(
                onRefresh: () async => await context.read<TimeLineCubit>().loadFirstPage(),
                child: ScrollablePositionedList.builder(
                    itemScrollController: itemScrollController,
                    itemPositionsListener: itemPositionsListener,
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
              ),
                  ValueListenableBuilder<Iterable<ItemPosition>>(
                    valueListenable: itemPositionsListener.itemPositions,
                    builder: (context, positions, _) {
                      final day = _topmostDay(positions, allEpg);
                      final targetIndex = allEpg.indexWhere(
                          (e) => e.id == _currentTargetId(
                              context.read<TimeLineCubit>().state));
                      final targetVisible = positions.any((p) =>
                          p.index == targetIndex &&
                          p.itemTrailingEdge > 0 &&
                          p.itemLeadingEdge < 1);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (day != null) _buildPinnedDateHeader(context, day),
                          const Spacer(),
                          if (targetIndex >= 0 && !targetVisible)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: _buildJumpToCurrentButton(context, allEpg),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
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

  /// What "now" means for this timeline: the programme on air, or — for a
  /// station that has nothing scheduled at the moment — the next one.
  String _currentTargetId(TimeLineState state) {
    if (state.activeEpg.id.isNotEmpty) return state.activeEpg.id;
    if (state.futureEpg.isNotEmpty) return state.futureEpg.first.id;
    return '';
  }

  /// Scroll back to that programme on demand, animated (the initial positioning
  /// on page load jumps instead, so the list doesn't fly past days of content).
  void _jumpToCurrent(List<RadioEpg> allEpg) {
    final state = context.read<TimeLineCubit>().state;
    final targetId = _currentTargetId(state);
    final index = allEpg.indexWhere((e) => e.id == targetId);
    if (index < 0 || !itemScrollController.isAttached) return;
    itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      // Leave room for the pinned date header, so the programme isn't clipped
      // underneath it (its ON AIR badge sits at the top edge of the card).
      alignment: _listAlignment,
    );
  }

  /// The day the topmost visible programme belongs to — drives the pinned
  /// header, so the date stays readable instead of scrolling away with its
  /// section.
  DateTime? _topmostDay(Iterable<ItemPosition> positions, List<RadioEpg> allEpg) {
    final visible = positions.where((p) => p.itemTrailingEdge > 0);
    if (visible.isEmpty || allEpg.isEmpty) return null;
    final top = visible.reduce((a, b) => a.itemLeadingEdge <= b.itemLeadingEdge ? a : b);
    if (top.index < 0 || top.index >= allEpg.length) return null;
    return allEpg[top.index].start;
  }

  /// Same label as the inline separator, but on an opaque bar pinned to the top
  /// of the list so it survives scrolling.
  Widget _buildPinnedDateHeader(BuildContext context, DateTime date) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.only(bottom: 4),
      child: _buildDateHeader(context, date),
    );
  }

  Widget _buildJumpToCurrentButton(BuildContext context, List<RadioEpg> allEpg) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: AppColors.green,
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _jumpToCurrent(allEpg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.my_location, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)?.timeline_jump_to_current ?? '',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context, DateTime date) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();

    final locale = Localizations.localeOf(context).toLanguageTag();

    String dateText;
    if (_isSameDay(date, now)) {
      dateText = AppLocalizations.of(context)?.date_today ?? '';
    } else if (_isSameDay(date, now.add(const Duration(days: 1)))) {
      dateText = AppLocalizations.of(context)?.date_tomorrow ?? '';
    } else {
      // Skeleton instead of a literal pattern: "Donnerstag, 13. August" in
      // German, "Thursday, August 13" in English.
      dateText = DateFormat.MMMMEEEEd(locale).format(date);
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