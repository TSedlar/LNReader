import 'package:ln_reader/scopes/global_scope.dart' as globals;
import 'package:ln_reader/novel/struct/ln_source.dart';

class LNChapter {
  LNSource source;
  int index;
  String title;
  String date;
  String link;
  String content;
  double lastPosition = 0;
  double scrollLength = 1;

  bool nearCompletion() {
    // 95% complete should count as completed.
    // 100% offset might not be reached..
    // This also accounts for people not reading translator notes etc.
    return percentRead() >= 95.0;
  }

  double percentRead() {
    try {
      if (scrollLength == 0 || scrollLength == double.nan || scrollLength == double.infinity) {
        return 0;
      }
      double percent = ((lastPosition / scrollLength) * 100.0);
      if (percent == double.nan || percent == double.infinity) {
        return 0;
      } else {
        return percent;
      }
    } catch (mathErr) {
      return 0;
    }
  }

  bool started() {
    return percentRead().toInt() > 0;
  }

  String percentReadString() {
    return percentRead().toStringAsFixed(1) + '%';
  }

  bool isTextFormat() {
    return !title.endsWith(".pdf");
  }

  Map toJson() => {
        'source': source.id,
        'index': index,
        'title': title,
        'date': date,
        'link': link,
        'last_position': lastPosition,
        'scroll_length': scrollLength,
      };

  static LNChapter fromJson(json) {
    LNChapter chapter = LNChapter();

    // Safely parse arguments in case of structure change or additions to be added

    if (json['source'] != null) {
      chapter.source = globals.sources[json['source']];
    }

    if (json['index'] != null) {
      chapter.index = json['index'];
    }

    if (json['title'] != null) {
      chapter.title = json['title'];
    }

    if (json['date'] != null) {
      chapter.date = json['date'];
    }

    if (json['link'] != null) {
      chapter.link = json['link'];
    }

    if (json['last_position'] != null) {
      chapter.lastPosition = json['last_position'];
    }

    if (json['scroll_length'] != null) {
      chapter.scrollLength = json['scroll_length'];
    }

    return chapter;
  }
}
