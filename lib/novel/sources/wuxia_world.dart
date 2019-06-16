import 'package:html/parser.dart';
import 'package:ln_reader/novel/struct/ln_chapter.dart';
import 'package:ln_reader/novel/struct/ln_download.dart';
import 'package:ln_reader/novel/struct/ln_entry.dart';
import 'package:ln_reader/novel/struct/ln_preview.dart';
import 'package:ln_reader/novel/struct/ln_source.dart';
import 'package:ln_reader/util/string_normalizer.dart';

class WuxiaWorld extends LNSource {
  WuxiaWorld()
      : super(
          id: 'wuxia_world',
          name: 'Wuxia World',
          lang: 'EN',
          baseURL: 'https://wuxiaworld.online',
          logoAsset: 'assets/images/aggregators/wuxia_world_online.png',
          tabCategories: [
            'Updated',
            'New',
            'Popular',
          ],
          multiGenre: false,
          genres: [
            "Academy",
            "Action",
            "Adventure",
            "Chinese",
            "Comedy",
            "Cultivation",
            "Demons",
            "Drama",
            "English",
            "Fantasy",
            "Futuristic",
            "Ghosts",
            "Gods",
            "Harem",
            "Historical",
            "Horror",
            "Japanese",
            "Korean",
            "Martial Arts",
            "Martialarts",
            "Mature",
            "Mystery",
            "Original",
            "Psychological",
            "Reincarnation",
            "Romance",
            "Schoollife",
            "Sci-Fi",
            "Scifi",
            "Sliceoflife",
            "Supernatural",
            "Thriller",
            "Xianxia",
            "Xuanhuan",
          ],
        );

  @override
  Future<String> fetchPreviews() {
    return readFromView(mkurl('/?view=list'));
  }

  // Wuxia world does not have searching with a query along with
  // a genre, so this will act as a search for the query if it exists
  // otherwise a search for a single genre, since this source also
  // does not support searching multiple genre at a time.
  @override
  Future<String> search(String query, List<String> genres) {
    if (query != null) {
      return readFromView(mkurl('/search.ajax?query=$query'));
    } else if (genres.isNotEmpty) {
      return readFromView(mkurl(
        '/wuxia-list?view=list&genres_include=' + genres.first,
      ));
    } else {
      return null;
    }
  }

  @override
  Future<String> fetchEntry(LNPreview preview) {
    return readFromView(preview.link);
  }

  @override
  Map<String, List<LNPreview>> parsePreviews(String html) {
    final document = parse(html);

    final updateList = <LNPreview>[];
    final newList = <LNPreview>[];
    final popularList = <LNPreview>[];

    updateList.addAll(_parseMainList(document));

    final releases = document.querySelectorAll(
      'div[class*="newest-released"]',
    );

    if (releases.length >= 3) {
      newList.addAll(_parseList(releases[2]));
      popularList.addAll(_parseList(releases[1]));
    }

    return {
      // Updated
      tabCategories[0]: updateList,
      // New
      tabCategories[1]: newList,
      // Popular
      tabCategories[2]: popularList,
    };
  }

  List<LNPreview> _parseMainList(containerElement) {
    final list = <LNPreview>[];

    final updatedElements = containerElement.querySelectorAll(
      'div[class*="update_item"]',
    );

    updatedElements.forEach((updatedElement) {
      final anchor = updatedElement.querySelector(
        'div[class*="update_image"] a',
      );
      final cover = updatedElement.querySelector(
        'div[class*="update_image"] a > img',
      );

      if (anchor != null && cover != null) {
        final preview = LNPreview();
        preview.sourceId = this.id;
        preview.link = mkurl(anchor.attributes['href']);
        preview.name = cover.attributes['alt'];
        preview.coverURL = proxiedImage(mkurl(cover.attributes['src']));
        list.add(preview);
      }
    });

    return list;
  }

  List<LNPreview> _parseList(containerElement) {
    final list = <LNPreview>[];
    final anchors = containerElement.querySelectorAll('a[class*="tooltip"]');
    anchors.forEach((anchor) {
      final cover = anchor.querySelector('img');
      if (cover != null) {
        final preview = LNPreview();
        preview.sourceId = this.id;
        preview.link = mkurl(anchor.attributes['href']);
        preview.name = cover.attributes['alt'];
        preview.coverURL = proxiedImage(mkurl(cover.attributes['src']));
        list.add(preview);
      }
    });
    return list;
  }

  @override
  List<LNPreview> parseSearchPreviews(String html) {
    final list = <LNPreview>[];
    final document = parse(html);

    list.addAll(_parseMainList(document));

    final queryItems = document.querySelectorAll('li[class*="option"]');

    queryItems.forEach((item) {
      final anchor = item.querySelector('a');
      final cover = item.querySelector('img');
      if (anchor != null && cover != null) {
        final preview = LNPreview();
        preview.sourceId = this.id;
        preview.link = mkurl(anchor.attributes['href']);
        preview.name = anchor.text.trim();
        preview.coverURL = proxiedImage(mkurl(cover.attributes['src']));
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

    // Setup queries
    final infoContainer = document.querySelector(
      'ul[class*="truyen_info_right"]',
    );

    final description = document.querySelector('#noidungm');
    final chapters = document.querySelectorAll(
      'div[class*="chapter-list"] div[class*="row"]',
    );

    if (infoContainer != null) {
      final infoItems = infoContainer.querySelectorAll('li');
      final ranking = infoContainer.querySelector('span[rel*="v:rating"]');

      infoItems.forEach((infoItem) {
        final fullText = infoItem.text.toLowerCase().trim();
        if (fullText.startsWith('genres')) {
          final anchors = infoItem.querySelectorAll('a');
          anchors.forEach((a) => entry.genres.add(a.text.trim()));
        } else if (fullText.startsWith('status')) {
          final statusLink = infoItem.querySelector('a');
          if (statusLink != null) {
            entry.status = statusLink.text.trim();
          }
        } else if (fullText.startsWith('last updated')) {
          final updateTime = infoItem.querySelector('em');
          if (updateTime != null) {
            entry.lastUpdated = updateTime.text.trim();
          }
        } else if (fullText.startsWith('views')) {
          if (infoItem.nodes.length >= 2) {
            entry.views = infoItem.nodes[1].text.trim();
          }
        }
      });

      if (ranking != null) {
        entry.ranking = ranking.text.trim();
      }
    }

    if (description != null) {
      entry.description = description.nodes[1].text.trim();
    }

    int idx = 0;
    chapters.forEach((chapter) {
      final spans = chapter.querySelectorAll('span');
      if (spans.length >= 2) {
        final anchor = spans[0].querySelector('a');
        if (anchor != null) {
          final chapter = LNChapter();
          chapter.sourceId = source.id;
          chapter.index = idx;
          chapter.link = anchor.attributes['href'];
          chapter.title = anchor.text.trim();
          chapter.date = spans[1].text.trim();
          entry.chapters.add(chapter);
        }
      }
      idx++;
    });

    return entry;
  }

  @override
  String makeReaderContent(String chapterHTML) {
    final document = parse(chapterHTML);
    print('parsed reader document...');
    final content = document.querySelector(
      '#list_chapter div[class*="content-area"]',
    );
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
    LNPreview preview,
    LNChapter chapter,
  ) {
    // TODO: find a case of this source hosting non-text content
    return null;
  }
}
