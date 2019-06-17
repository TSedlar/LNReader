import 'dart:async';
import 'package:html/parser.dart';
import 'package:interactive_webview/interactive_webview.dart';
import 'package:ln_reader/scopes/global_scope.dart' as globals;
import 'package:ln_reader/novel/struct/ln_chapter.dart';
import 'package:ln_reader/novel/struct/ln_download.dart';
import 'package:ln_reader/novel/struct/ln_entry.dart';
import 'package:ln_reader/novel/struct/ln_preview.dart';
import 'package:ln_reader/novel/struct/ln_source.dart';

class NovelUpdates extends LNSource {
  static final Map<String, String> _genreMapping = {
    'Action': '8',
    'Adult': '280',
    'Adventure': '13',
    'Comedy': '17',
    'Drama': '9',
    'Ecchi': '292',
    'Fantasy': '5',
    'Gender Bender': '168',
    'Harem': '3',
    'Historical': '330',
    'Horror': '343',
    'Josei': '324',
    'Martial Arts': '14',
    'Mature': '4',
    'Mecha': '10',
    'Mystery': '245',
    'Psychological': '486',
    'Romance': '15',
    'School Life': '6',
    'Sci-fi': '11',
    'Seinen': '18',
    'Shoujo': '157',
    'Shoujo Ai': '851',
    'Shounen': '12',
    'Shounen Ai': '1692',
    'Slice of Life': '7',
    'Smut': '281',
    'Sports': '1357',
    'Supernatural': '16',
    'Tragedy': '132',
    'Wuxia': '479',
    'Xianxia': '480',
    'Xuanhuan': '3954',
    'Yaoi': '560',
    'Yuri': '922',
  };

  NovelUpdates()
      : super(
          id: 'novel_updates',
          name: 'Novel Updates',
          lang: 'EN',
          baseURL: 'https://novelupdates.com',
          logoAsset: 'assets/images/aggregators/novel_updates.png',
          tabCategories: [
            'Updated',
            'Popular',
          ],
          genres: _genreMapping.keys.toList(),
        );

  @override
  Future<List<String>> fetchPreviews() async {
    // Popular link
    return [
      // Updated
      await readFromView(
          mkurl(
            '/latest-series/',
          ),
          needsCompleteLoad: true),
      // Popular
      await readFromView(
          mkurl(
            '/series-ranking/',
          ),
          needsCompleteLoad: true)
    ];
  }

  // Sadly you can't search by both genre+name on this source
  @override
  Future<String> search(String query, List<String> genres) {
    if (query != null) {
      return readFromView(mkurl('/?s=$query'));
    } else {
      String genreString = genres.map((g) => _genreMapping[g]).join(',');
      return readFromView(mkurl(
        '/series-finder/?sf=1&gi=$genreString&mgi=or&&sort=sread&order=desc}',
      ));
    }
  }

  @override
  Future<String> fetchEntry(LNPreview preview) {
    final activateWaitMillis = 10000;
    return readFromView(
      preview.link,
      onLoad: (view) async {
        // We have to manually activate the chapter listing button..
        await waitForChapterActivation(view, activateWaitMillis);
        return true;
      },
      timeout: Duration(
        milliseconds: globals.timeoutLength.inMilliseconds + activateWaitMillis,
      ),
      encodeURL: false,
    );
  }

  @override
  Map<String, List<LNPreview>> parsePreviews(List<String> html) {
    final updatedDocument = parse(html[0]);
    final popularDocument = parse(html[1]);
    return {
      // Updated
      tabCategories[0]: _parseTable(updatedDocument),
      // Popular
      tabCategories[1]: _parseTable(popularDocument),
    };
  }

  List<LNPreview> _parseTable(document) {
    final list = <LNPreview>[];
    final items = document.querySelectorAll('tr[class*="bdrank"]');
    items.forEach((item) {
      final anchor = item.querySelector('div[class*="searchpic"] a');
      final cover = item.querySelector('div[class*="searchpic"] a > img');
      if (anchor != null && cover != null) {
        final genres = item.querySelectorAll('span[class*="gennew"]');

        final preview = LNPreview();

        preview.sourceId = this.id;
        preview.link = mkurl(anchor.attributes['href']);
        preview.name = cover.attributes['alt'];
        preview.coverURL = mkurl(cover.attributes['src']);

        genres
            .forEach((genre) => preview.data['genres'].add(genre.text.trim()));

        list.add(preview);
      }
    });
    return list;
  }

  @override
  List<LNPreview> parseSearchPreviews(String html) {
    final list = <LNPreview>[];
    final document = parse(html);

    final entries = document.querySelectorAll('div[class*="w-blog-entry-h"]');

    list.addAll(_parseTable(document));

    entries.forEach((entryElement) {
      final anchor = entryElement.querySelector('a');
      final title = entryElement.querySelector('span[class*="entry-title"]');
      final cover = entryElement.querySelector('img');
      final genres = entryElement.querySelectorAll('span[class*="gennew"]');

      final preview = LNPreview();

      preview.sourceId = this.id;

      if (anchor != null) {
        preview.link = mkurl(anchor.attributes['href']);
      }

      if (title != null) {
        preview.name = title.text.trim();
      }

      if (cover != null) {
        preview.coverURL = mkurl(cover.attributes['src']);
      }

      genres.forEach((g) => preview.data['genres'].add(g.text.trim()));

      list.add(preview);
    });

    return list;
  }

  @override
  LNEntry parseEntry(LNSource source, String html) {
    final document = parse(html);
    final entry = LNEntry();

    entry.sourceId = source.id;

    final authors = document.querySelectorAll('#showauthors > a');
    final aliases = document.querySelector('#editassociated');
    final genres = document.querySelectorAll('#seriesgenre > a');
    final description = document.querySelector('#editdescription');
    final chapters = document.querySelectorAll('li[class*="sp_li_chp"]');
    final votes = document.querySelector('span[class*="uvotes"]');
    final translated = document.querySelector('#showtranslated');
    final hdCover = document.querySelector('span[property="image"]');

    if (authors != null) {
      authors.forEach((a) => entry.authors.add(a.text.trim()));
    }

    if (aliases != null) {
      aliases.nodes.forEach((node) {
        final text = node.text.trim();
        if (text.isNotEmpty) {
          entry.aliases.add(text);
        }
      });
    }

    if (translated != null) {
      final transTxt = translated.text.trim().toLowerCase();
      entry.status = transTxt == 'no' ? 'Ongoing' : 'Completed';
    }

    if (genres != null) {
      genres.forEach((g) => entry.genres.add(g.text.trim()));
    }

    if (votes != null) {
      try {
        entry.ranking = votes.text.trim().split(',')[0].replaceFirst('(', '');
      } catch (err) {
        print('err parsing votes');
      }
    }

    if (description != null) {
      entry.description = description.text.trim();
    }

    if (hdCover != null) {
      entry.hdCoverURL = hdCover.attributes['content'].trim();
    }

    int idx = 0;
    chapters.forEach((chElement) {
      final anchor = chElement.querySelector('a:last-child');
      if (anchor != null) {
        final chapter = LNChapter();
        chapter.sourceId = source.id;
        chapter.index = idx;
        chapter.link = mkurl(anchor.attributes['href']);
        chapter.title = anchor.text.trim();
        entry.chapters.add(chapter);
      }
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

  waitForChapterActivation(InteractiveWebView view, int timeoutMillis) async {
    final completer = Completer();

    final clickListener = view.didReceiveMessage.listen((msg) {
      final data = msg.data as Map;

      if (!completer.isCompleted && data.containsKey('clicked')) {
        completer.complete();
      }
    });

    final timeoutStart = DateTime.now();

    await Future.doWhile(() async {
      await Future.delayed(Duration(milliseconds: 250));

      view.evalJavascript('''
          if (typeof window.clicked === 'undefined') {
            window.clicked = false;
          }
          if (!window.clicked) {
            var chViewer = document.querySelector('span[class*="my_popupreading_open"]');
            if (chViewer != null) {
              console.log('Clicked chapter popup');
              window.clicked = true;
              chViewer.click();
              var nativeCommunicator = typeof webkit !== 'undefined' ? webkit.messageHandlers.native : window.native;
              nativeCommunicator.postMessage(JSON.stringify({ "clicked": true }));
            }
          }
      ''');

      final difference = DateTime.now().difference(timeoutStart).inMilliseconds;

      if (difference >= timeoutMillis) {
        return false;
      }

      return difference < timeoutMillis && !completer.isCompleted;
    });

    clickListener.cancel();

    // Wait for popup to show up
    await Future.delayed(Duration(milliseconds: 1500));
  }
}
