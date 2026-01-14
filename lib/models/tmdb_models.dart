class TmdbMedia {
  final int id;
  final String? name; // For TV shows
  final String? title; // For movies
  final String? originalName;
  final String? originalTitle;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String mediaType;
  final double? voteAverage;
  final String? firstAirDate;
  final String? releaseDate;
  final List<String>? originCountry;

  TmdbMedia({
    required this.id,
    this.name,
    this.title,
    this.originalName,
    this.originalTitle,
    this.overview,
    this.posterPath,
    this.backdropPath,
    required this.mediaType,
    this.voteAverage,
    this.firstAirDate,
    this.releaseDate,
    this.originCountry,
  });

  String get displayName => name ?? title ?? 'Unknown';
  String get displayOriginalName =>
      originalName ?? originalTitle ?? displayName;
  String get year => (firstAirDate ?? releaseDate ?? '').split('-').first;
  String? get posterUrl =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : null;
  String? get backdropUrl => backdropPath != null
      ? 'https://image.tmdb.org/t/p/original$backdropPath'
      : null;

  factory TmdbMedia.fromJson(Map<String, dynamic> json) {
    return TmdbMedia(
      id: json['id'],
      name: json['name'],
      title: json['title'],
      originalName: json['original_name'],
      originalTitle: json['original_title'],
      overview: json['overview'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      mediaType: json['media_type'] ?? 'tv',
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      firstAirDate: json['first_air_date'],
      releaseDate: json['release_date'],
      originCountry: json['origin_country'] != null
          ? List<String>.from(json['origin_country'])
          : null,
    );
  }
}

class TmdbSeason {
  final int id;
  final String name;
  final String? overview;
  final String? posterPath;
  final int seasonNumber;
  final int episodeCount;

  TmdbSeason({
    required this.id,
    required this.name,
    this.overview,
    this.posterPath,
    required this.seasonNumber,
    required this.episodeCount,
  });

  factory TmdbSeason.fromJson(Map<String, dynamic> json) {
    return TmdbSeason(
      id: json['id'],
      name: json['name'] ?? '',
      overview: json['overview'],
      posterPath: json['poster_path'],
      seasonNumber: json['season_number'],
      episodeCount: json['episode_count'],
    );
  }
}

class TmdbDetails {
  final int id;
  final List<TmdbSeason>? seasons;
  final List<String> genres;
  final String? status;
  final int? numberOfEpisodes;
  final int? numberOfSeasons;
  final String? tagline;

  TmdbDetails({
    required this.id,
    this.seasons,
    required this.genres,
    this.status,
    this.numberOfEpisodes,
    this.numberOfSeasons,
    this.tagline,
  });

  factory TmdbDetails.fromJson(Map<String, dynamic> json) {
    return TmdbDetails(
      id: json['id'],
      seasons: json['seasons'] != null
          ? (json['seasons'] as List)
                .map((s) => TmdbSeason.fromJson(s))
                .toList()
          : null,
      genres:
          (json['genres'] as List?)?.map((g) => g['name'] as String).toList() ??
          [],
      status: json['status'],
      numberOfEpisodes: json['number_of_episodes'],
      numberOfSeasons: json['number_of_seasons'],
      tagline: json['tagline'],
    );
  }
}
