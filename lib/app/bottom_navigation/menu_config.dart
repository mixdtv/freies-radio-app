import 'package:radiozeit/config/app_config.dart';
import 'package:radiozeit/features/podcast/podcast_list_page.dart';
import 'package:radiozeit/features/radio_about/radio_about_page.dart';
import 'package:radiozeit/features/timeline/radio_timeline_page.dart';
import 'package:radiozeit/features/transcript/radio_transcript_page.dart';
import 'package:radiozeit/features/visual/radio_visual_page.dart';

/// Configuration for the bottom navigation menu
/// Handles menu item indices and page routing
class MenuConfig {
  /// Map menu item names to their indices
  static const Map<String, int> _menuItemIndices = {
    'transcript': 0,
    'timeline': 1,
    'podcasts': 2,
    'visual': 3,
    'about': 4,
  };

  /// Map menu item names to their page paths
  static const Map<String, String> _menuPaths = {
    'transcript': RadioTranscriptPage.path,
    'timeline': RadioTimeLinePage.path,
    'podcasts': PodcastListPage.path,
    'visual': RadioVisualPage.path,
    'about': RadioAboutPage.path,
  };

  /// Get the index of the first visible menu item
  static int getDefaultPageIndex() {
    if (AppConfig.visibleMenuItems.isEmpty) return 0;
    return _menuItemIndices[AppConfig.visibleMenuItems.first] ?? 0;
  }

  /// Get the default page path based on the first visible menu item
  static String getDefaultPagePath() {
    if (AppConfig.visibleMenuItems.isEmpty) return RadioTranscriptPage.path;
    return _menuPaths[AppConfig.visibleMenuItems.first] ?? RadioTranscriptPage.path;
  }
}