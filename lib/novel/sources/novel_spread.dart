import 'package:html/parser.dart';
import 'package:ln_reader/novel/struct/ln_chapter.dart';
import 'package:ln_reader/novel/struct/ln_download.dart';
import 'package:ln_reader/novel/struct/ln_entry.dart';
import 'package:ln_reader/novel/struct/ln_preview.dart';
import 'package:ln_reader/novel/struct/ln_source.dart';
import 'package:ln_reader/util/string_normalizer.dart';

class NovelSpread extends LNSource {
  NovelSpread()
      : super(
          id: 'novel_spread',
          name: 'Novel Spread',
          lang: 'EN',
          baseURL: 'https://novelspread.com/',
          logoAsset: 'assets/images/aggregators/novel_spread.png',
          tabCategories: [
            'Updated',
            'New',
            'Popular',
          ],
          genres: [],
          needsCompleteLoad: true,
        );

  @override
  Future<String> fetchPreviews() {
    return readFromView(baseURL);
  }

  @override
  Future<String> search(String query, List<String> genres) {
    return readFromView(mkurl('/novels/search/$query'));
  }

  @override
  Future<String> fetchEntry(LNPreview preview) {
    return readFromView(preview.link);
  }

  @override
  Map<String, List<LNPreview>> parsePreviews(String html) {
    final document = parse(html);

    return {
      // Updated
      tabCategories[0]: _parsePreviewList(
        document.querySelector('div[id="js-daily-updates-tag-slide"]'),
      ),
      // New
      tabCategories[1]: _parsePreviewList(
        document.querySelector('div[id="js-new-release-tag-slide"]'),
      ),
      // Popular
      tabCategories[2]: _parsePreviewList(
        document.querySelector('div[id="js-popular-tag-slide"]'),
      ),
    };
  }

  List<LNPreview> _parsePreviewList(containerElement) {
    final previews = <LNPreview>[];
    if (containerElement != null) {
      final anchors = containerElement.querySelectorAll(
        'li[class*="swiper-slide"] > a',
      );
      anchors.forEach((anchor) {
        final preview = LNPreview();

        preview.sourceId = this.id;

        preview.link = mkurl(anchor.attributes['href']);

        final cover = anchor.querySelector('img');
        if (cover != null) {
          preview.name = cover.attributes['title'];
          preview.coverURL = mkurl(cover.attributes['data-src']);
        }

        previews.add(preview);
      });
    }
    return previews;
  }

  @override
  List<LNPreview> parseSearchPreviews(String html) {
    final previews = <LNPreview>[];
    final document = parse(html);
    final matches = document.querySelectorAll(
      'ul[class*="match"]',
    );
    matches.forEach((match) {
      final anchor = match.querySelector('div[class*="pic"] a');
      final cover = match.querySelector('div[class*="pic"] a > img');
      if (anchor != null && cover != null) {
        final preview = LNPreview();
        preview.sourceId = this.id;
        preview.name = cover.attributes['title'];
        preview.link = mkurl(anchor.attributes['href']);
        preview.coverURL = mkurl(cover.attributes['data-src']);
        previews.add(preview);
      }
    });
    return previews;
  }

  @override
  LNEntry parseEntry(LNSource source, String html) {
    final document = parse(html);
    final entry = LNEntry();

    entry.sourceId = source.id;

    final genres = document.querySelector('div[class*="novel-classInto"]');
    if (genres != null) {
      entry.genres.add(genres.text.trim());
    }

    final ongoingStatus = document.querySelector(
      'div[class*="unfinished-Trans"]',
    );
    if (ongoingStatus != null) {
      entry.status = ongoingStatus.text.trim();
    }

    final completeStatus = document.querySelector(
      'div[class*="stateOfTranslation"]',
    );
    if (completeStatus != null) {
      entry.status = completeStatus.text.trim();
    }

    final people = document.querySelectorAll(
      'div[class*="main-left"] div[class*="person"]',
    );

    people.forEach((person) {
      final type = person.querySelector('h3');
      final value = person.querySelector('h4');
      if (type != null && value != null) {
        final typeString = type.text.trim();
        if (typeString == 'Author') {
          entry.authors.add(value.text.trim());
        } else if (typeString == 'Translator') {
          entry.translator = value.text.trim();
        }
      }
    });

    final description = document.querySelector('div[class*="syn"]');
    if (description != null) {
      entry.description = description.text.trim();
    }

    final chapters = document.querySelectorAll('div[class*="volumeBox"] ul li');
    if (chapters != null) {
      int idx = 0;
      chapters.forEach((chElement) {
        final link = chElement.querySelector('a');
        if (link != null) {
          final chapter = LNChapter();
          chapter.sourceId = source.id;
          chapter.index = (chapters.length - idx);
          // Use the mobile chapter as parsing is quicker
          chapter.link =
              mkurl(link.attributes['href']).replaceFirst('www.', 'm.');
          chapter.title = chElement.text.trim();
          // novel spread is in standard order, we need descending
          entry.chapters.insert(0, chapter);
        }
        idx++;
      });
    }
    return entry;
  }

  @override
  String makeReaderContent(String chapterHTML) {
    final document = parse(chapterHTML);
    print('parsed reader document...');
    final content = document.querySelector('article div[class*="content"]');
    if (content != null) {
      print('parsed reader document content.......');
      print('normalizing document reader...');
      String normalized = StringNormalizer.normalize(content.innerHtml);
      print('normalized...');
      return normalized;
    }
    return null;
  }

  @override
  Future<LNDownload> handleNonTextDownload(
      LNPreview preview, LNChapter chapter) {
    // TODO: find a case of this source hosting non-text content
    return null;
  }
}
