library globals;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ln_reader/novel/sources/box_novel.dart';
import 'package:ln_reader/novel/sources/novel_spread.dart';
import 'package:ln_reader/novel/sources/novel_updates.dart';
import 'package:ln_reader/novel/sources/wuxia_world.dart';
import 'package:ln_reader/novel/struct/ln_preview.dart';
import 'package:ln_reader/util/ui/hex_color.dart';
import 'package:ln_reader/util/ui/themes.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ln_reader/novel/struct/ln_source.dart';
import 'package:ln_reader/novel/sources/novel_planet.dart';
import 'package:ln_reader/util/observable.dart';

final timeoutLength = Duration(seconds: 10);

final Map<String, LNSource> sources = Map.fromIterable(
  [
    // English sources
    NovelUpdates(),
    NovelPlanet(),
    WuxiaWorld(),
    NovelSpread(),
    BoxNovel(),
  ],
  key: (item) => (item as LNSource).id,
  value: (item) => (item as LNSource),
);

final appDir = ObservableValue<Directory>();

final String _dataFile = '/persisted_data.json';
bool _runningWatcher = false; // needs to be non-mutable publicly
bool get runningWatcher => _runningWatcher;

final homeContext = ObservableValue<BuildContext>();

final offline = ObservableValue<bool>(true);

// START DEFAULT VALUES

// keep readerMode off by default..? would respect potential ads and trouble
// if it arose with Apple/Google, even though we are not in control
// of the content hosted on the sites..
bool firstRun = true;
bool _defaultLibHome = false; // Use library as home page instead
bool _defaultHideRead = true; // Hide read chapters by default
bool _defaultDeleteMode = true; // delete chapters after reading
bool _defaultReaderMode = true; // similar to chrome/safari "article mode"
double _defaultReaderFontSize = 14.0; // small size
String _defaultFontFamily = 'Barlow'; // included asset font

Map<String, String> _defaultTheme = Themes.deepBlue;

// END DEFAULT VALUES

// START OBSERVABLE VALUES
// - Used for global changes and persistent storage

final source = ObservableValue<LNSource>(sources.values.first);

final libHome = ObservableValue<bool>(_defaultLibHome);
final hideRead = ObservableValue<bool>(_defaultHideRead);
final deleteMode = ObservableValue<bool>(_defaultDeleteMode);
final readerMode = ObservableValue<bool>(_defaultReaderMode);
final readerFontFamily = ObservableValue<String>(_defaultFontFamily);
final readerFontSize = ObservableValue<double>(_defaultReaderFontSize);

final theme = ObservableValue.fromMap<String, String>({})
  ..val.addAll(_defaultTheme);

// END OBSERVABLE VALUES

startWatcher() async {
  // Quit if already watching
  if (_runningWatcher) {
    return;
  }

  // Set watching variable
  _runningWatcher = true;

  // Read globals and set variables
  await readFromFile();

  // Bind to all globals for file syncing
  source.listen((_) => writeToFile());
  libHome.listen((_) => writeToFile());
  deleteMode.listen((_) => writeToFile());
  readerMode.listen((_) => writeToFile());
  readerFontFamily.listen((_) => writeToFile());
  readerFontSize.listen((_) => writeToFile());
  theme.listen((_) => writeToFile());
  sources.values.forEach((source) {
    source.readPreviews.listen((_) => writeToFile());
    source.favorites.listen((_) => writeToFile());
  });
}

writeToFile() async {
  print('syncing data to file...');
  final appDir = await getApplicationDocumentsDirectory();
  final jsonDest = File(appDir.path + _dataFile);

  final Map data = {
    'lib_home': libHome.val,
    'hide_read': hideRead.val,
    'delete_mode': deleteMode.val,
    'reader_mode': readerMode.val,
    'reader_font_family': readerFontFamily.val,
    'reader_font_size': readerFontSize.val,
    'theme': theme.val,
    'source': source.val.id,
    'sources': {},
    'cookies': {},
  };

  // Set map data for each source
  sources.keys.forEach((sourceId) {
    final Map sourceData = {};
    final List previews = [];
    final List favorites = [];

    // Add preview data
    sources[sourceId].readPreviews.val.forEach((preview) {
      previews.add(preview.toJson());
    });
    sourceData['read_previews'] = previews;

    // Add favorite data
    sources[sourceId].favorites.val.forEach((favorite) {
      favorites.add(favorite.toJson());
    });
    sourceData['favorites'] = favorites;

    // Set the source data
    data['sources'][sourceId] = sourceData;
  });

  // Write to local file
  jsonDest.writeAsStringSync(json.encode(data));
  print('synced');
}

readFromFile() async {
  final jsonDest = File(appDir.val.path + _dataFile);

  if (jsonDest.existsSync()) {
    firstRun = false;
    final jsonString = jsonDest.readAsStringSync();
    final data = json.decode(jsonString);
    // set libHome variable
    if (data['lib_home'] != null) {
      libHome.val = data['lib_home'];
    }

    // set hideRead variable
    if (data['hide_read'] != null) {
      hideRead.val = data['hide_read'];
    }

    // Set deleteMode variable
    if (data['delete_mode'] != null) {
      deleteMode.val = data['delete_mode'];
    }

    // Set readerMode variable
    if (data['reader_mode'] != null) {
      readerMode.val = data['reader_mode'];
    }

    // Set readerFontFamily variable
    if (data['reader_font_family'] != null) {
      readerFontFamily.val = data['reader_font_family'];
    }

    // Set readerFontSize variable
    if (data['reader_font_size'] != null) {
      readerFontSize.val = data['reader_font_size'];
    }

    // Set readerColors variable
    if (data['theme'] != null) {
      data['theme'].keys.forEach((key) => theme.val[key] = data['theme'][key]);
    }

    // Set source variable
    if (data['source'] != null) {
      source.val = sources[data['source']];
    }

    // Set source data
    if (data['sources'] != null) {
      sources.keys.forEach((sourceId) {
        final source = data['sources'][sourceId];

        if (source != null) {
          // Set source readPreviews variable
          if (source['read_previews'] != null) {
            source['read_previews'].forEach((preview) async {
              sources[sourceId]
                  .readPreviews
                  .val
                  .add(await LNPreview.fromJson(preview));
            });
          }

          // Set source favorites variable
          if (source['favorites'] != null) {
            source['favorites'].forEach((favorite) async {
              sources[sourceId]
                  .favorites
                  .val
                  .add(await LNPreview.fromJson(favorite));
            });
          }
        }
      });
    }
  }
}

deleteFiles() async {
  final jsonDest = File(appDir.val.path + _dataFile);

  // Delete settings
  if (jsonDest.existsSync()) {
    await jsonDest.delete();
  }

  // Delete source files
  sources.keys.forEach((key) async {
    final dir = sources[key].dir;
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });
}

ThemeData createColorTheme() => ThemeData(
      brightness: Brightness.dark,
      primaryColor: HexColor(theme.val['background']),
      accentColor: HexColor(theme.val['background_accent']),
      backgroundColor: HexColor(theme.val['background_accent']),
      textTheme: TextTheme(
        body1: TextStyle(
          color: HexColor(theme.val['foreground']),
        ),
        body2: TextStyle(
          color: HexColor(theme.val['foreground']),
        ),
        headline: TextStyle(
          color: HexColor(theme.val['headings']),
        ),
        title: TextStyle(
          color: HexColor(theme.val['headings']),
        ),
        subhead: TextStyle(
          color: HexColor(theme.val['headings']),
        ),
        display1: TextStyle(
          color: HexColor(theme.val['headings']),
        ),
        display2: TextStyle(
          color: HexColor(theme.val['headings']),
        ),
        display3: TextStyle(
          color: HexColor(theme.val['headings']),
        ),
        display4: TextStyle(
          color: HexColor(theme.val['headings']),
        ),
      ),
    );

ThemeData createTheme() {
  final colorTheme = createColorTheme();
  return colorTheme.copyWith(
    textTheme: TextTheme(
      body1: colorTheme.textTheme.body1.copyWith(
        fontFamily: readerFontFamily.val,
      ),
      body2: colorTheme.textTheme.body2.copyWith(
        fontFamily: readerFontFamily.val,
      ),
      headline: colorTheme.textTheme.headline.copyWith(
        fontFamily: readerFontFamily.val,
      ),
      title: colorTheme.textTheme.title.copyWith(
        fontFamily: readerFontFamily.val,
      ),
      subhead: colorTheme.textTheme.subhead.copyWith(
        fontFamily: readerFontFamily.val,
      ),
      display1: colorTheme.textTheme.display1.copyWith(
        fontFamily: readerFontFamily.val,
      ),
      display2: colorTheme.textTheme.display2.copyWith(
        fontFamily: readerFontFamily.val,
      ),
      display3: colorTheme.textTheme.display3.copyWith(
        fontFamily: readerFontFamily.val,
      ),
      display4: colorTheme.textTheme.display4.copyWith(
        fontFamily: readerFontFamily.val,
      ),
    ),
  );
}
