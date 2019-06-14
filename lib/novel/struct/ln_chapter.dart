import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:ln_reader/novel/struct/ln_download.dart';
import 'package:ln_reader/novel/struct/ln_preview.dart';
import 'package:ln_reader/scopes/global_scope.dart' as globals;
import 'package:ln_reader/novel/struct/ln_source.dart';
import 'package:ln_reader/util/ui/retry.dart';
import 'package:ln_reader/views/widget/loader.dart';

class LNChapter {
  String sourceId;
  int index;
  String title;
  String date;
  String link;

  double lastPosition = 0;
  double scrollLength = 1;

  LNSource get source => globals.sources[sourceId];

  bool nearCompletion() {
    // 95% complete should count as completed.
    // 100% offset might not be reached..
    // This also accounts for people not reading translator notes etc.
    return percentRead() >= 95.0;
  }

  double percentRead() {
    try {
      if (scrollLength == 0 ||
          scrollLength == double.nan ||
          scrollLength == double.infinity) {
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

  bool isHTMLDownloaded(LNPreview preview) {
    final chapterFile = File(preview.chapterDir.path + '/$index.html');
    return chapterFile.existsSync();
  }

  bool isPDFDownloaded(LNPreview preview) {
    final chapterFile = File(preview.chapterDir.path + '/$index.pdf');
    return chapterFile.existsSync();
  }

  bool isDownloaded(LNPreview preview) {
    return isHTMLDownloaded(preview) || isPDFDownloaded(preview);
  }

  deleteFile(LNPreview preview) {
    final files = [
      File(preview.chapterDir.path + '/$index.html'),
      File(preview.chapterDir.path + '/$index.pdf'),
    ];

    files.forEach((file) => file.deleteSync());
  }

  String percentReadString() {
    return percentRead().toStringAsFixed(1) + '%';
  }

  bool isTextFormat() {
    String lowTitle = title.toLowerCase();
    return !lowTitle.endsWith(".pdf");
  }

  Future<LNDownload> download(BuildContext context, LNPreview preview) async {
    if (isTextFormat()) {
      Loader.text.val = 'Downloading chapter...';

      // Expected html
      final html = await Retry.exec(context, () => source.readFromView(link));

      Loader.text.val = 'Downloaded!';

      // Store for offline use
      if (html != null) {
        final download = LNDownload(type: LNDownloadType.HTML);
        download.htmlPath = download.fileFor(preview, this);
        await download.htmlPath.writeAsString(html);
        return download;
      }
    } else {
      Loader.text.val = 'Downloading PDF...';
      // Probably a pdf, haven't seen epub/etc
      final data = await Retry.exec(
        context,
        () => source.handleNonTextDownload(preview, this),
      );

      Loader.text.val = 'Downloaded!';

      return data;
    }
    // These is no match or download failed
    return null;
  }

  Map toJson() {
    final json = {
      'source': source.id,
      'index': index,
      'title': title,
      'date': date,
      'link': link,
      'last_position': lastPosition,
      'scroll_length': scrollLength,
    };

    return json;
  }

  static Future<LNChapter> fromJson(json) async {
    LNChapter chapter = LNChapter();

    // Safely parse arguments in case of structure change or additions to be added

    if (json['source'] != null) {
      chapter.sourceId = json['source'];
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
