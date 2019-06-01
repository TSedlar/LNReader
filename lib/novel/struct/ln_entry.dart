import 'package:ln_reader/novel/struct/ln_chapter.dart';
import 'package:ln_reader/novel/struct/ln_source.dart';

class LNEntry {

  LNSource source;
  String url;
  String name;
  List<String> aliases = [];
  List<String> genres = [];
  String releaseDate = 'N/A';
  int popularity = 0;
  List<String> authors = [];
  String status = 'N/A';
  String translator = 'N/A';
  String description = '';
  List<LNChapter> chapters = []; // must be descending order

  LNChapter firstChapter() {
    return chapters[chapters.length - 1];
  }

  LNChapter nextChapter(LNChapter current) {
    final nextIndex = current.index - 1;
    return nextIndex >= 0 ? chapters[nextIndex] : null;
  }
}