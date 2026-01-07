import 'package:after_layout/after_layout.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:radiozeit/app/bottom_navigation/bottom_navigation_cubit.dart';
import 'package:radiozeit/app/widgets/error_load.dart';
import 'package:radiozeit/app/widgets/shimmer.dart';
import 'package:radiozeit/data/model/podcast.dart';
import 'package:radiozeit/features/player/player_cubit.dart';
import 'package:radiozeit/features/podcast/bloc/podcast_cubit.dart';
import 'package:radiozeit/features/podcast/podcast_episodes_page.dart';
import 'package:radiozeit/features/radio_list/radio_list_page.dart';
import 'package:radiozeit/features/timeline/bloc/timeline_cubit.dart';
import 'package:radiozeit/utils/colors.dart';

class PodcastListPage extends StatefulWidget {
  static const String path = "/PodcastListPage";

  const PodcastListPage({super.key});

  @override
  State<PodcastListPage> createState() => _PodcastListPageState();
}

class _PodcastListPageState extends State<PodcastListPage> with AfterLayoutMixin {
  @override
  void afterFirstLayout(BuildContext context) {
    final selectedRadio = context.read<TimeLineCubit>().state.activeRadio;
    if (selectedRadio?.podcasts != null && selectedRadio!.podcasts!.isNotEmpty) {
      context.read<PodcastCubit>().loadPodcasts(selectedRadio.podcasts!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          _appBar(),
        Expanded(
          child: BlocBuilder<PodcastCubit, PodcastState>(
            builder: (context, state) {
              if (state.isLoading) {
                return Shimmer(
                  child: ListView.builder(
                    itemCount: 3,
                    itemBuilder: (context, index) => _buildLoadingItem(),
                  ),
                );
              }

              if (state.error != null) {
                return ErrorLoad(
                  error: state.error!,
                  load: () {
                    final selectedRadio = context.read<TimeLineCubit>().state.activeRadio;
                    if (selectedRadio?.podcasts != null && selectedRadio!.podcasts!.isNotEmpty) {
                      context.read<PodcastCubit>().loadPodcasts(selectedRadio.podcasts!);
                    }
                  },
                );
              }

              if (state.podcasts.isEmpty) {
                return const Center(
                  child: Text('No podcasts available'),
                );
              }

              return ListView.builder(
                itemCount: state.podcasts.length,
                itemBuilder: (context, index) {
                  final podcast = state.podcasts[index];
                  return _buildPodcastItem(context, podcast);
                },
              );
            },
          ),
        ),
      ],
      ),
    );
  }

  Widget _appBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradient.getPanelGradient(context)
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BackButton(
              onPressed: () {
                context.read<BottomNavigationCubit>().openMenu(false);
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(RadioListPage.path);
                }
              },
            ),
            Builder(
              builder: (context) {
                String radioName = context.select((PlayerCubit cubit) => cubit.state.selectedRadio?.name ?? "");
                return Text(
                  radioName,
                  style: Theme.of(context).textTheme.displayLarge,
                );
              }
            ),
            SizedBox(width: 46),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingItem() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 14,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodcastItem(BuildContext context, Podcast podcast) {
    return InkWell(
      onTap: () {
        context.push(
          PodcastEpisodesPage.path,
          extra: podcast,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: podcast.imageUrl.isNotEmpty && Uri.tryParse(podcast.imageUrl)?.hasAbsolutePath == true
                ? CachedNetworkImage(
                    imageUrl: podcast.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade300,
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image_not_supported),
                    ),
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.podcasts, size: 40, color: Colors.grey),
                  ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    podcast.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    podcast.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${podcast.episodes.length} episodes',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
