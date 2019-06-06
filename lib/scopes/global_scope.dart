library globals;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ln_reader/novel/struct/ln_preview.dart';
import 'package:ln_reader/util/net/global_web_view.dart';
import 'package:ln_reader/util/ui/hex_color.dart';
import 'package:ln_reader/util/ui/themes.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ln_reader/novel/struct/ln_source.dart';
import 'package:ln_reader/novel/sources/novel_planet.dart';
import 'package:ln_reader/util/observable.dart';

final timeoutLength = Duration(seconds: 25);

final Map<String, LNSource> sources = Map.fromIterable(
  [
    NovelPlanet(),
  ],
  key: (item) => (item as LNSource).id,
  value: (item) => (item as LNSource),
);

final String _dataFile = '/persisted_data.json';
bool _runningWatcher = false; // needs to be non-mutable publicly
bool get runningWatcher => _runningWatcher;
final homeContext = ObservableValue<BuildContext>();

// START DEFAULT VALUES

// keep readerMode off by default..? would respect potential ads and trouble
// if it arose with Apple/Google, even though we are not in control
// of the content hosted on the sites..
bool _defaultReaderMode = true; // similar to chrome/safari "article mode"
double _defaultReaderFontSize = 14.0; // small size
String _defaultFontFamily = 'Barlow'; // included asset font

Map<String, String> _defaultTheme = Themes.deepBlue;

// END DEFAULT VALUES

// START OBSERVABLE VALUES
// - Used for global changes and persistent storage

final loading = ObservableValue<bool>(true);

final source = ObservableValue<LNSource>(sources.values.first);

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
  readerMode.listen((_) => writeToFile());
  readerFontFamily.listen((_) => writeToFile());
  readerFontSize.listen((_) => writeToFile());
  theme.listen((_) => writeToFile());
  sources.values.forEach((source) {
    source.readPreviews.listen((_) => writeToFile());
    source.favorites.listen((_) => writeToFile());
  });

  // Sync cookies
  GlobalWebView.cookieCache.listen((_) => writeToFile());
}

writeToFile() async {
  print('syncing data to file...');
  final appDir = await getApplicationDocumentsDirectory();
  final jsonDest = File(appDir.path + _dataFile);

  final Map data = {
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

  // Set cookie data
  GlobalWebView.cookieCache.val.forEach((host, cookies) {
    data['cookies'][host] = cookies;
  });

  // Write to local file
  jsonDest.writeAsStringSync(json.encode(data));
  print('synced');
}

readFromFile() async {
  final appDir = await getApplicationDocumentsDirectory();
  final jsonDest = File(appDir.path + _dataFile);
  final jsonExists = await jsonDest.exists();

  if (jsonExists) {
    final jsonString = jsonDest.readAsStringSync();
    final data = json.decode(jsonString);

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
            source['read_previews'].forEach((preview) {
              sources[sourceId]
                  .readPreviews
                  .val
                  .add(LNPreview.fromJson(preview));
            });
          }

          // Set source favorites variable
          if (source['favorites'] != null) {
            source['favorites'].forEach((favorite) {
              sources[sourceId].favorites.val.add(LNPreview.fromJson(favorite));
            });
          }
        }
      });
    }

    // Set cookie data
    if (data['cookies'] != null) {
      data['cookies'].forEach((host, cookies) {
        final Map<String, String> cookieMap = {};
        cookies.forEach((k, v) => cookieMap[k.toString()] = v.toString());
        GlobalWebView.cookieCache.val[host] = cookieMap;
      });

      print(GlobalWebView.cookieCache.val);
    }
  }
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
