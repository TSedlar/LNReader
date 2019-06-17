import 'package:ln_reader/novel/struct/ln_chapter.dart';
import 'package:ln_reader/novel/struct/ln_download.dart';
import 'package:ln_reader/novel/struct/ln_entry.dart';
import 'package:ln_reader/novel/struct/ln_preview.dart';
import 'package:ln_reader/novel/struct/ln_source.dart';

class NeuManga extends LNSource {
  NeuManga()
      : super(
          id: 'neu_manga',
          name: 'Neu Manga',
          lang: 'IN',
          baseURL: 'https://neumanga.tv',
          logoAsset: 'assets/images/aggregators/neu_manga.png',
          tabCategories: [],
          genres: [],
        );

  @override
  Future<List<String>> fetchPreviews() {
    // TODO: implement fetchPreviews
    return null;
  }

  @override
  Future<String> search(String query, List<String> genres) {
    // TODO: implement search
    return null;
  }

  @override
  Future<String> fetchEntry(LNPreview preview) {
    // TODO: implement fetchEntry
    return null;
  }

  @override
  Map<String, List<LNPreview>> parsePreviews(List<String> html) {
    // TODO: implement parsePreviews
    return null;
  }

  @override
  List<LNPreview> parseSearchPreviews(String html) {
    // TODO: implement parseSearchPreviews
    return null;
  }

  @override
  LNEntry parseEntry(LNSource source, String html) {
    // TODO: implement parseEntry
    return null;
  }

  @override
  String makeReaderContent(String chapterHTML) {
    // TODO: implement makeReaderContent
    return null;
  }

  @override
  Future<LNDownload> handleNonTextDownload(
    LNPreview preview,
    LNChapter chapter,
  ) {
    // TODO: find a case of this source hosting non-text content
    return null;
  }
}
