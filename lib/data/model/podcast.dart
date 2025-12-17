class Podcast {
  final String title;
  final String description;
  final String imageUrl;
  final String feedUrl;
  final List<PodcastEpisode> episodes;

  Podcast({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.feedUrl,
    this.episodes = const [],
  });

  Podcast copyWith({
    String? title,
    String? description,
    String? imageUrl,
    String? feedUrl,
    List<PodcastEpisode>? episodes,
  }) {
    return Podcast(
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      feedUrl: feedUrl ?? this.feedUrl,
      episodes: episodes ?? this.episodes,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'imageUrl': imageUrl,
    'feedUrl': feedUrl,
    'episodes': episodes.map((e) => e.toJson()).toList(),
  };

  factory Podcast.fromJson(Map<String, dynamic> json) => Podcast(
    title: json['title'] as String,
    description: json['description'] as String,
    imageUrl: json['imageUrl'] as String,
    feedUrl: json['feedUrl'] as String,
    episodes: (json['episodes'] as List)
        .map((e) => PodcastEpisode.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class PodcastEpisode {
  final String title;
  final String description;
  final String imageUrl;
  final String audioUrl;
  final DateTime? pubDate;
  final Duration? duration;

  PodcastEpisode({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.audioUrl,
    this.pubDate,
    this.duration,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'imageUrl': imageUrl,
    'audioUrl': audioUrl,
    'pubDate': pubDate?.toIso8601String(),
    'duration': duration?.inMilliseconds,
  };

  factory PodcastEpisode.fromJson(Map<String, dynamic> json) => PodcastEpisode(
    title: json['title'] as String,
    description: json['description'] as String,
    imageUrl: json['imageUrl'] as String,
    audioUrl: json['audioUrl'] as String,
    pubDate: json['pubDate'] != null ? DateTime.parse(json['pubDate'] as String) : null,
    duration: json['duration'] != null ? Duration(milliseconds: json['duration'] as int) : null,
  );
}
