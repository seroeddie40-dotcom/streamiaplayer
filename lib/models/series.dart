class Series {
  final String id;
  final String title;
  final String? plot;
  final String? posterUrl;
  final List<Season> seasons;

  Series({
    required this.id,
    required this.title,
    this.plot,
    this.posterUrl,
    required this.seasons,
  });
}

class Season {
  final int number;
  final List<Episode> episodes;
  Season({required this.number, required this.episodes});
}

class Episode {
  final String id;
  final String title;
  final int number;
  final String streamUrl;
  final int? durationSeconds;

  Episode({
    required this.id,
    required this.title,
    required this.number,
    required this.streamUrl,
    this.durationSeconds,
  });
}
