class VodItem {
  final String id;
  final String title;
  final String? plot;
  final String? posterUrl;
  final String streamUrl;
  final int? durationSeconds;

  VodItem({
    required this.id,
    required this.title,
    this.plot,
    this.posterUrl,
    required this.streamUrl,
    this.durationSeconds,
  });
}
