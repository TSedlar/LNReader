import 'dart:io';

import 'package:ln_reader/novel/struct/ln_chapter.dart';
import 'package:ln_reader/novel/struct/ln_preview.dart';

class LNDownload {
  LNDownload({this.type, this.htmlPath, this.pdfPath});

  LNDownloadType type;
  File htmlPath;
  File pdfPath;

  File fileFor(LNPreview preview, LNChapter chapter) {
    preview.chapterDir.createSync(recursive: true);
    return File(preview.chapterDir.path + '/${chapter.index}.${type.ext}');
  }
}

class LNDownloadType {
  static const HTML = LNDownloadType('html');
  static const PDF = LNDownloadType('pdf');

  final String ext;

  const LNDownloadType(this.ext);
}
