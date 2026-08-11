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

/// One line of the timeline. Headers, the "now" card and programmes are
/// separate entries instead of nested inside a programme, so scroll positions
/// map 1:1 to what is on screen — the pinned header can be derived exactly
/// instead of guessed from how far into an entry we have scrolled.
class _Row {
  _Row.header(this.day)
      : programme = null,
        isNowCard = false;
  _Row.nowCard(RadioEpg next, this.day)
      : programme = next,
        isNowCard = true;
  _Row.programme(RadioEpg this.programme, this.day) : isNowCard = false;

  final RadioEpg? programme;
  final DateTime day;
  final bool isNowCard;

  bool get isHeader => programme == null;
}

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

  /// Programmes we scroll to start flush at the top of the list. The date
  /// header and the "nothing on air" card belong to the same list entry, so
  /// they come along — and no sliver of the previous programme stays in view.
  static const double _listAlignment = 0.0;
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
      int index = _targetRow(_buildRows(state, state.allEpg), targetId);
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
        // Switching station keeps the page alive, so the one-shot scroll latch
        // would leave you wherever the previous station's list happened to be.
        BlocListener<TimeLineCubit, TimeLineState>(
          listenWhen: (p, c) => p.activeRadio?.id != c.activeRadio?.id,
          listener: (context, state) {
            isScrolled = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !isScrolled) _scrollToCurrent();
            });
          },
        ),
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

              final rows = _buildRows(
                  context.read<TimeLineCubit>().state, allEpg);

              return Column(
                children: [
                  // Pinned above the list rather than stacked on top of it, so
                  // nothing is hidden behind it and the day label always matches
                  // what you can actually see.
                  ValueListenableBuilder<Iterable<ItemPosition>>(
                    valueListenable: itemPositionsListener.itemPositions,
                    builder: (context, positions, _) {
                      final top = _topmostPosition(positions, rows.length);
                      if (top == null) return const SizedBox.shrink();
                      // A header row at the top prints its own date already;
                      // then the bar names the day above, so it always tells you
                      // what has scrolled out of view.
                      final row = rows[top.index];
                      final date = row.isHeader && top.index > 0
                          ? rows[top.index - 1].day
                          : row.day;
                      return _buildPinnedDateHeader(context, date);
                    },
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        RefreshIndicator(
                          onRefresh: () async =>
                              await context.read<TimeLineCubit>().loadFirstPage(),
                          child: ScrollablePositionedList.builder(
                              itemScrollController: itemScrollController,
                              itemPositionsListener: itemPositionsListener,
                              itemBuilder: (context, index) {
                                final row = rows[index];
                                if (row.isHeader) {
                                  return _buildDateHeader(context, row.day);
                                }
                                if (row.isNowCard) {
                                  return _buildNoCurrentShowCard(
                                      context, row.programme!);
                                }
                                return TimelineListItem(
                                  isActive: activeEpg?.id == row.programme!.id,
                                  program: row.programme!,
                                  stationName: stationName,
                                  onPlay: () => _playProgram(row.programme!),
                                  onLive: () => _switchToLive(),
                                );
                              },
                              itemCount: rows.length),
                        ),
                        ValueListenableBuilder<Iterable<ItemPosition>>(
                          valueListenable: itemPositionsListener.itemPositions,
                          builder: (context, positions, _) {
                            final targetIndex = _targetRow(rows,
                                _currentTargetId(context.read<TimeLineCubit>().state));
                            final targetVisible = positions.any((p) =>
                                p.index == targetIndex &&
                                p.itemTrailingEdge > 0 &&
                                p.itemLeadingEdge < 1);
                            if (targetIndex < 0 || targetVisible) {
                              return const SizedBox.shrink();
                            }
                            return Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildJumpToCurrentButton(context, rows),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
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
  void _jumpToCurrent(List<_Row> rows) {
    final state = context.read<TimeLineCubit>().state;
    final index = _targetRow(rows, _currentTargetId(state));
    if (index < 0 || !itemScrollController.isAttached) return;
    itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: _listAlignment,
    );
  }

  /// Flattens the programme list into rows, inserting a date header per day
  /// and the "now" card in front of the next programme when nothing is on air.
  List<_Row> _buildRows(TimeLineState state, List<RadioEpg> allEpg) {
    final rows = <_Row>[];
    final now = DateTime.now();
    final nextId = state.activeEpg.id.isEmpty && state.futureEpg.isNotEmpty
        ? state.futureEpg.first.id
        : null;
    DateTime? day;

    for (final programme in allEpg) {
      if (programme.id == nextId) {
        if (day == null || !_isSameDay(day, now)) {
          rows.add(_Row.header(now));
          day = now;
        }
        rows.add(_Row.nowCard(programme, day));
      }
      if (day == null || !_isSameDay(day, programme.start)) {
        rows.add(_Row.header(programme.start));
        day = programme.start;
      }
      rows.add(_Row.programme(programme, day));
    }
    return rows;
  }

  /// Row to land on: the "now" card when there is one, so the explanation is
  /// on screen, otherwise the programme itself.
  int _targetRow(List<_Row> rows, String targetId) {
    if (targetId.isEmpty) return -1;
    final card = rows.indexWhere((r) => r.isNowCard && r.programme?.id == targetId);
    if (card >= 0) return card;
    return rows.indexWhere(
        (r) => !r.isHeader && !r.isNowCard && r.programme?.id == targetId);
  }

  /// The topmost visible programme — drives the pinned header, so the date
  /// stays readable instead of scrolling away with its section.
  ItemPosition? _topmostPosition(Iterable<ItemPosition> positions, int rowCount) {
    final visible = positions
        .where((p) => p.itemTrailingEdge > 0 && p.index >= 0 && p.index < rowCount);
    if (visible.isEmpty || rowCount == 0) return null;
    return visible.reduce((a, b) => a.itemLeadingEdge <= b.itemLeadingEdge ? a : b);
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

  /// Shown in the list where "now" would be when the station has nothing on
  /// air, in the same visual language as a programme, so it reads as part of
  /// the schedule instead of an error bar bolted above it.
  Widget _buildNoCurrentShowCard(BuildContext context, RadioEpg next) {
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final when = '${DateFormat.MMMEd(locale).format(next.start)}, '
        '${DateFormat.Hm(locale).format(next.start)}';
    final muted = textTheme.bodySmall?.color?.withOpacity(0.6);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradient.getPanelGradient(context),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.schedule, size: 20, color: muted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // Deliberately about this moment, not about the day: "nothing
                    // today" would be wrong whenever the station broadcast this
                    // morning or starts again tonight.
                    AppLocalizations.of(context)?.timeline_no_current_show ?? '',
                    style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppLocalizations.of(context)?.timeline_next_show ?? ''}: $when',
                    style: textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJumpToCurrentButton(BuildContext context, List<_Row> rows) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: AppColors.green,
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _jumpToCurrent(rows),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.my_location, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                context.read<TimeLineCubit>().state.activeEpg.id.isNotEmpty
                    ? AppLocalizations.of(context)?.timeline_jump_to_current ?? ''
                    : AppLocalizations.of(context)?.timeline_next_show ?? '',
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