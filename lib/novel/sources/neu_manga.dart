import 'dart:async';

import 'package:html/parser.dart';
import 'package:interactive_webview/interactive_webview.dart';
import 'package:ln_reader/scopes/global_scope.dart' as globals;
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
          tabCategories: [
            'Updated',
            'Popular',
          ],
          multiGenre: false,
          // Sadly only 1 genre can be seen at a time on NeuManga
          genres: [
            "Action",
            "Adventure",
            "Comedy",
            "Drama",
            "Ecchi",
            "Fantasy",
            "Harem",
            "Isekai",
            "Martial Arts",
            "Mature",
            "Psychological",
            "Romance",
            "School Life",
            "Sci-fi",
            "Seinen",
            "Shounen",
            "Slice Of Life",
            "Supernatural",
            "Tragedy",
            "Xuanhuan",
          ],
        );

  @override
  Future<List<String>> fetchPreviews() async {
    return [
      await readFromView(baseURL),
    ];
  }

  @override
  Future<String> search(String query, List<String> genres) {
    if (query != null) {
      return readFromView(mkurl(
        '/lightnovel/advanced_search?mode=image&sortby=views&name_search_mode=contain&name_search_query=$query',
      ));
    } else {
      final genre = genres.first;
      return readFromView(
        mkurl(
          '/lightnovel/advanced_search?mode=image&sortby=views&genre1=%5B"$genre"%5D',
        ),
        encodeURL: false,
      );
    }
  }

  @override
  Future<String> fetchEntry(LNPreview preview) {
    final loadWaitMillis = 5000;
    return readFromView(
      preview.link,
      onLoad: (view) async {
        // We have to wait for the chapter table to load before parsing
        await _waitForChapterTable(view, loadWaitMillis);
        return true;
      },
      timeout: Duration(
        milliseconds: globals.timeoutLength.inMilliseconds + loadWaitMillis,
      ),
    );
  }

  @override
  Map<String, List<LNPreview>> parsePreviews(List<String> html) {
    final document = parse(html.first);
    final updatedList = <LNPreview>[];
    final popularList = <LNPreview>[];

    final upItems = document.querySelectorAll(
      '#home-lightnovel-container div[class*="mcp"]',
    );
    final popItems = document.querySelectorAll('#tab-pop-ln div[class*="lts"]');

    // Handle updated
    upItems.forEach((upItem) {
      final anchor = upItem.querySelector('a[class*="tle"]');
      final coverImg = upItem.querySelector('img');
      if (anchor != null && coverImg != null) {
        final preview = LNPreview();

        preview.sourceId = this.id;
        preview.link = mkurl(anchor.attributes['href']);
        preview.name = anchor.text.trim();

        String coverURL = mkurl(coverImg.attributes['src']);
        if (coverURL.contains('?resize=')) {
          coverURL = coverURL.substring(0, coverURL.indexOf('?resize='));
        }

        preview.coverURL = coverURL;

        updatedList.add(preview);
      }
    });

    // Handle popular
    popItems.forEach((popItem) {
      final anchor = popItem.querySelector('div[class*="title"] > a');
      final coverImg = popItem.querySelector('div[class*="img"] > img');

      if (anchor != null && coverImg != null) {
        final preview = LNPreview();

        preview.sourceId = this.id;
        preview.link = mkurl(anchor.attributes['href']);
        preview.name = anchor.text.trim();

        String coverURL = mkurl(coverImg.attributes['src']);
        if (coverURL.contains('?resize=')) {
          coverURL = coverURL.substring(0, coverURL.indexOf('?resize='));
        }

        preview.coverURL = coverURL;

        popularList.add(preview);
      }
    });

    return {
      // Updated
      tabCategories[0]: updatedList,
      // Popular
      tabCategories[1]: popularList,
    };
  }

  @override
  List<LNPreview> parseSearchPreviews(String html) {
    final document = parse(html);
    final list = <LNPreview>[];

    final items = document.querySelectorAll('#gov-result div[class*="bolx"]');

    items.forEach((item) {
      final anchor = item.querySelector('h2 > a');
      final coverImg = item.querySelector('div > img');

      if (anchor != null && coverImg != null) {
        final preview = LNPreview();

        preview.sourceId = this.id;
        preview.link = mkurl(anchor.attributes['href']);
        preview.name = anchor.text.trim();

        String coverURL = mkurl(coverImg.attributes['src']);
        if (coverURL.contains('?resize=')) {
          coverURL = coverURL.substring(0, coverURL.indexOf('?resize='));
        }

        preview.coverURL = coverURL;

        list.add(preview);
      }
    });

    return list;
  }

  @override
  LNEntry parseEntry(LNSource source, String html) {
    final document = parse(html);
    final entry = LNEntry();

    entry.sourceId = source.id;

    final info = document.querySelector('div[class*="info"]');
    final description = document.querySelector('div[class*="summary"] > p');
    final chapters = document.querySelectorAll(
      'li > span[class*="lnc-title"] > a',
    );

    if (info != null) {
      final alias = info.querySelector('span[itemprop="text"]');
      final genres = info.querySelector('#genres');
      final authors = info.querySelector('#authors');
      final ranking = info.querySelector('span[class*="rating-value"]');
      final dataSpans = info.querySelectorAll('span');

      if (alias != null) {
        String aliasText = alias.text.trim();
        if (aliasText.toLowerCase().startsWith('alternative name:')) {
          aliasText = aliasText.substring(17).trim();
        }
        entry.aliases.add(aliasText);
      }

      if (genres != null) {
        entry.genres.addAll(
          genres.text.trim().split(',').map((g) => g.trim()),
        );
      }

      if (authors != null) {
        entry.authors.addAll(
          authors.text.trim().split(',').map((a) => a.trim()),
        );
      }

      if (ranking != null) {
        entry.ranking = ranking.text.trim() + '/5';
      }

      dataSpans.forEach((dataSpan) {
        final spanText = dataSpan.text.trim();
        final lower = spanText.toLowerCase();

        if (lower.contains('status:')) {
          entry.status = lower.split('status:')[1].trim();
        } else if (lower.contains('viewer:')) {
          entry.views = lower.split('viewer:')[1].trim();
        }
      });
    }

    if (description != null) {
      entry.description = description.text.trim();
    }

    print(chapters.length);

    int idx = 0;
    chapters.forEach((chElement) {
      final chapter = LNChapter();

      chapter.sourceId = source.id;
      chapter.index = (chapters.length - idx);
      chapter.link = mkurl(chElement.attributes['href']);
      chapter.title = chElement.text.trim();

      // NeuManga is in standard order, we need descending
      entry.chapters.insert(0, chapter);

      idx++;
    });

    return entry;
  }

  @override
  Future<LNDownload> handleNonTextDownload(
    LNPreview preview,
    LNChapter chapter,
  ) {
    // TODO: find a case of this source hosting non-text content
    return null;
  }

  _waitForChapterTable(InteractiveWebView view, int timeoutMillis) async {
    final completer = Completer();

    final loadListener = view.didReceiveMessage.listen((msg) {
      final data = msg.data as Map;

      if (!completer.isCompleted && data.containsKey('loaded')) {
        completer.complete();
      }
    });

    final timeoutStart = DateTime.now();

    await Future.doWhile(() async {
      await Future.delayed(Duration(milliseconds: 250));

      view.evalJavascript('''
        var loaded = document.querySelectorAll(
          'li > span[class*="lnc-title"] > a',
        ).length > 0;
        if (loaded) {
          console.log('Loaded chapter table');
          var nativeCommunicator = typeof webkit !== 'undefined' ? webkit.messageHandlers.native : window.native;
          nativeCommunicator.postMessage(JSON.stringify({ "loaded": true }));
        }
      ''');

      final difference = DateTime.now().difference(timeoutStart).inMilliseconds;

      if (difference >= timeoutMillis) {
        return false;
      }

      return difference < timeoutMillis && !completer.isCompleted;
    });

    loadListener.cancel();
  }
}
