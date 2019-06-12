import 'dart:convert' as convert;
import 'dart:io';
import 'package:ln_reader/novel/struct/ln_entry.dart';
import 'package:ln_reader/scopes/global_scope.dart' as globals;
import 'package:ln_reader/novel/struct/ln_chapter.dart';
import 'package:ln_reader/novel/struct/ln_source.dart';
import 'package:ln_reader/util/observable.dart';

class LNPreview {
  String sourceId;
  String name;
  String link;
  String coverURL;
  List<String> genres = [];

  final lastRead = ObservableValue<LNChapter>();
  final lastReadStamp = ObservableValue<int>(-1);
  final ascending = ObservableValue<bool>(true); // default ascending

  LNEntry entry;

  LNSource get source => globals.sources[sourceId];

  Directory get dir => Directory(source.dir.path + '/$name/');

  File get dataFile => File(dir.path + '/data.json');

  File get entryFile => File(dir.path + '/entry.json');

  Directory get chapterDir => Directory(dir.path + '/chapters/');

  loadExistingData() {
    int indexMatch =
        source.readPreviews.val.indexWhere((preview) => preview.link == link);
    if (indexMatch >= 0) {
      LNPreview match = source.readPreviews.val[indexMatch];
      if (match.lastRead.seen) {
        lastRead.val = match.lastRead.val;
      }
      if (match.lastReadStamp.seen) {
        lastReadStamp.val = match.lastReadStamp.val;
      }
      if (match.ascending.seen) {
        ascending.val = match.ascending.val;
      }
    }
    lastRead.listen((_) => globals.writeToFile());
    lastReadStamp.listen((_) => globals.writeToFile());
    ascending.listen((_) => globals.writeToFile());
  }

  markLastRead(LNChapter chapter) {
    lastRead.val = chapter;
    lastReadStamp.val = DateTime.now().millisecondsSinceEpoch;
    int existingIndex =
        source.readPreviews.val.indexWhere((preview) => preview.link == link);
    if (existingIndex >= 0) {
      ObservableValue<LNChapter> eLastRead =
          source.readPreviews.val[existingIndex].lastRead;
      eLastRead.val = chapter;
      eLastRead.listen((newVal) => lastRead.val = newVal);
    } else {
      source.readPreviews.val.add(this);
    }
  }

  bool isFavorite() {
    final idx = source.favorites.val.indexWhere(
      (preview) => preview.link == link,
    );
    return idx >= 0;
  }

  favorite() {
    if (!isFavorite()) {
      source.favorites.val.add(this);
    }
  }

  removeFromFavorites() {
    if (isFavorite()) {
      source.favorites.val.removeWhere((preview) => preview.link == link);
    }
  }

  Map toJson() => {
        'source': source.id,
        'name': name,
        'link': link,
        'cover_url': coverURL,
        'genres': genres,
        'last_read': lastRead.seen ? lastRead.val.toJson() : null,
        'last_read_stamp': lastReadStamp.seen ? lastReadStamp.val : -1,
        'ascending': ascending.seen ? ascending.val : false,
      };

  static Future<LNPreview> fromJson(json) async {
    final preview = LNPreview();

    // Safely parse json in case of structure change or additions to be added

    if (json['source'] != null) {
      preview.sourceId = json['source'];
    }

    if (json['name'] != null) {
      preview.name = json['name'];
    }

    if (json['link'] != null) {
      preview.link = json['link'];
    }

    if (json['cover_url'] != null) {
      preview.coverURL = json['cover_url'];
    }

    if (json['genres'] != null) {
      json['genres'].forEach((g) => preview.genres.add(g));
    }

    if (json['last_read'] != null) {
      preview.lastRead.val = await LNChapter.fromJson(json['last_read']);
    }

    if (json['last_read_stamp'] != null) {
      preview.lastReadStamp.val = json['last_read_stamp'];
    }

    if (json['ascending'] != null) {
      preview.ascending.val = json['ascending'];
    }

    if (preview.entryFile.existsSync()) {
      preview.entry = await LNEntry.fromJson(
        convert.json.decode(await preview.entryFile.readAsString()),
      );
    }

    return preview;
  }

  Future writeData() async {
    dir.createSync(recursive: true);
    return dataFile.writeAsString(convert.json.encode(toJson()));
  }

  Future writeEntryData(LNEntry entry) async {
    dir.createSync(recursive: true);
    if (entry == null) {
      return Future.value(false);
    }
    return entryFile.writeAsString(convert.json.encode(entry.toJson()));
  }

  Future writeChapterData(
    LNChapter chapter, {
    bool includeContent = false,
  }) async {
    chapterDir.createSync(recursive: true);
    final chapterFile = File(chapterDir.path + '/${chapter.index}.json');
    return await chapterFile.writeAsString(
      convert.json.encode(chapter.toJson(includeContent: includeContent)),
    );
  }

  Future setChapterData(LNChapter chapter) async {
    final chapterFile = File(chapterDir.path + '/${chapter.index}.json');
    if (chapterFile.existsSync()) {
      LNChapter offline = await LNChapter.fromJson(
        convert.json.decode(await chapterFile.readAsString()),
      );
      chapter.content = offline.content;
    }
  }
}
