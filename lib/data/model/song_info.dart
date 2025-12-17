class SongInfo {
  final String icon;
  final String name;
  final String artist;

  SongInfo({
    required this.icon,
    required this.name,
    required this.artist,
  });
  const SongInfo.test({
    this.icon = "",
    this.name = "Strangers",
    this.artist = "Kenya Grace",
  });
}