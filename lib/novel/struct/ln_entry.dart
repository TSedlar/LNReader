import 'package:ln_reader/scopes/global_scope.dart' as globals;
import 'package:ln_reader/novel/struct/ln_chapter.dart';
import 'package:ln_reader/novel/struct/ln_source.dart';

class LNEntry {
  String sourceId;
  String url;
  String name;
  List<String> aliases = [];
  List<String> genres = [];
  String views = 'N/A';
  String lastUpdated = 'N/A';
  String releaseDate = 'N/A';
  String ranking = 'N/A';
  List<String> authors = [];
  String status = 'N/A';
  String translator = 'N/A';
  String description = '';
  String hdCoverURL;
  List<LNChapter> chapters = []; // must be descending order

  LNSource get source => globals.sources[sourceId];

  LNChapter firstChapter() {
    return chapters[chapters.length - 1];
  }

  LNChapter nextChapter(LNChapter current) {
    final nextIndex = current.index - 1;
    return nextIndex >= 0 ? chapters[nextIndex] : null;
  }

  Map toJson() {
    return {
      'source': sourceId,
      'url': url,
      'name': name,
      'aliases': aliases,
      'genres': genres,
      'views': views,
      'last_updated': lastUpdated,
      'release_date': releaseDate,
      'ranking': ranking,
      'authors': authors,
      'status': status,
      'translator': translator,
      'description': description,
      'hd_cover_url': hdCoverURL,
      'chapters': chapters.map((ch) => ch.toJson()).toList(),
    };
  }

  static Future<LNEntry> fromJson(json) async {
    final entry = LNEntry();

    if (json['source'] != null) {
      entry.sourceId = json['source'];
    }

    if (json['url'] != null) {
      entry.url = json['url'];
    }

    if (json['name'] != null) {
      entry.name = json['name'];
    }

    if (json['aliases'] != null) {
      json['aliases'].forEach((a) => entry.aliases.add(a));
    }

    if (json['genres'] != null) {
      json['genres'].forEach((g) => entry.genres.add(g));
    }

    if (json['views'] != null) {
      entry.views = json['views'];
    }

    if (json['last_updated'] != null) {
      entry.lastUpdated = json['last_updated'];
    }

    if (json['release_date'] != null) {
      entry.releaseDate = json['release_date'];
    }

    if (json['ranking'] != null) {
      entry.ranking = json['ranking'];
    }

    if (json['authors'] != null) {
      json['authors'].forEach((a) => entry.authors.add(a));
    }

    if (json['status'] != null) {
      entry.status = json['status'];
    }

    if (json['translator'] != null) {
      entry.translator = json['translator'];
    }

    if (json['description'] != null) {
      entry.description = json['description'];
    }

    if (json['hd_cover_url'] != null) {
      entry.hdCoverURL = json['hd_cover_url'];
    }

    if (json['chapters'] != null) {
      json['chapters'].forEach(
        (ch) async => entry.chapters.add(await LNChapter.fromJson(ch)),
      );
    }

    return entry;
  }
}
