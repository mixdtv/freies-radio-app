import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:radiozeit/app/bottom_navigation/bottom_navigation_cubit.dart';
import 'package:radiozeit/app/widgets/error_load.dart';
import 'package:radiozeit/app/widgets/shimmer.dart';
import 'package:radiozeit/data/model/podcast.dart';
import 'package:radiozeit/features/player/player_cubit.dart';
import 'package:radiozeit/features/podcast/bloc/podcast_cubit.dart';
import 'package:radiozeit/features/podcast/podcast_list_page.dart';
import 'package:radiozeit/features/radio_list/radio_list_page.dart';
import 'package:radiozeit/features/timeline/bloc/timeline_cubit.dart';
import 'package:radiozeit/utils/colors.dart';

class PodcastEpisodesPage extends StatelessWidget {
  static const String path = "/PodcastEpisodesPage";

  /// Optional podcast - if not provided, will use first podcast from PodcastCubit
  final Podcast? podcast;

  const PodcastEpisodesPage({
    super.key,
    this.podcast,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<PodcastCubit, PodcastState>(
        builder: (context, state) {
          final selectedRadio = context.read<TimeLineCubit>().state.activeRadio;
          final radioFeedUrls = selectedRadio?.podcasts ?? [];

          // Get podcast - either passed in or from cubit state
          // But only use cubit state if it matches current radio's feed URLs
          Podcast? activePodcast = podcast;
          if (activePodcast == null && state.podcasts.isNotEmpty) {
            final firstPodcast = state.podcasts.first;
            if (radioFeedUrls.contains(firstPodcast.feedUrl)) {
              activePodcast = firstPodcast;
            }
          }

          // Handle error state
          if (state.error != null) {
            return _buildErrorState(context, state.error!);
          }

          // Trigger load if not loading and no valid podcast available
          if (!state.isLoading && activePodcast == null) {
            _triggerLoadIfNeeded(context);
          }

          if (state.isLoading || activePodcast == null) {
            return _buildLoadingState(context);
          }

          return _buildContent(context, activePodcast);
        },
      ),
    );
  }

  void _triggerLoadIfNeeded(BuildContext context) {
    final selectedRadio = context.read<TimeLineCubit>().state.activeRadio;
    if (selectedRadio?.podcasts?.isNotEmpty == true) {
      // Use addPostFrameCallback to avoid calling during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<PodcastCubit>().loadPodcasts(selectedRadio!.podcasts!);
      });
    }
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Column(
      children: [
        _buildAppBar(context, null),
        Expanded(
          child: Center(
            child: ErrorLoad(
              error: error,
              load: () {
                final selectedRadio = context.read<TimeLineCubit>().state.activeRadio;
                if (selectedRadio?.podcasts?.isNotEmpty == true) {
                  context.read<PodcastCubit>().loadPodcasts(selectedRadio!.podcasts!);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Column(
      children: [
        _buildAppBar(context, null),
        Expanded(
          child: Shimmer(
            child: ListView(
              children: [
                _buildLoadingHeader(),
                for (int i = 0; i < 5; i++) _buildLoadingEpisode(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
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
                  height: 18,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 14,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 4),
                Container(
                  width: 150,
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

  Widget _buildLoadingEpisode() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
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
                  width: 100,
                  height: 12,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, Podcast activePodcast) {
    return Column(
      children: [
        _buildAppBar(context, activePodcast),
        _buildPodcastHeader(activePodcast),
        Expanded(
          child: activePodcast.episodes.isEmpty
              ? const Center(
                  child: Text('No episodes available'),
                )
              : ListView.builder(
                  itemCount: activePodcast.episodes.length,
                  itemBuilder: (context, index) {
                    final episode = activePodcast.episodes[index];
                    return _buildEpisodeItem(context, episode, activePodcast);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, Podcast? activePodcast) {
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
                final selectedRadio = context.read<TimeLineCubit>().state.activeRadio;
                if (selectedRadio?.podcasts?.length == 1) {
                  // Single podcast: go back to radio list
                  context.go(RadioListPage.path);
                } else {
                  // Multiple podcasts: go back to podcast list
                  context.read<BottomNavigationCubit>().toPage(2);
                  context.go(PodcastListPage.path);
                }
              },
            ),
            Expanded(
              child: Text(
                activePodcast?.title ?? '',
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 46),
          ],
        ),
      ),
    );
  }

  Widget _buildPodcastHeader(Podcast activePodcast) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          if (activePodcast.imageUrl.isNotEmpty && Uri.tryParse(activePodcast.imageUrl)?.hasAbsolutePath == true)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: activePodcast.imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey.shade300,
                ),
                errorWidget: (context, url, error) => Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
          if (activePodcast.imageUrl.isEmpty || Uri.tryParse(activePodcast.imageUrl)?.hasAbsolutePath != true)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.podcasts, size: 50, color: Colors.grey),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activePodcast.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  activePodcast.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeItem(BuildContext context, PodcastEpisode episode, Podcast activePodcast) {
    return InkWell(
      onTap: () {
        if (episode.audioUrl.isNotEmpty) {
          context.read<PlayerCubit>().playPodcastEpisode(
                episode,
                activePodcast.title,
              );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (episode.imageUrl.isNotEmpty && Uri.tryParse(episode.imageUrl)?.hasAbsolutePath == true)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: episode.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade300,
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image_not_supported, size: 30),
                  ),
                ),
              ),
            if (episode.imageUrl.isEmpty || Uri.tryParse(episode.imageUrl)?.hasAbsolutePath != true)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.mic, size: 30, color: Colors.grey),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    episode.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (episode.pubDate != null)
                    Text(
                      DateFormat('MMM d, yyyy').format(episode.pubDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  if (episode.duration != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatDuration(episode.duration!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    episode.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.play_circle_outline,
              color: AppColors.orange,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
