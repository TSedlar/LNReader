import 'package:html/parser.dart';
import 'package:ln_reader/novel/struct/ln_chapter.dart';
import 'package:ln_reader/novel/struct/ln_download.dart';
import 'package:ln_reader/novel/struct/ln_entry.dart';
import 'package:ln_reader/novel/struct/ln_preview.dart';
import 'package:ln_reader/novel/struct/ln_source.dart';
import 'package:ln_reader/util/string_normalizer.dart';

class BoxNovel extends LNSource {
  BoxNovel()
      : super(
          id: 'box_novel',
          name: 'Box Novel',
          lang: 'EN',
          baseURL: 'https://boxnovel.com',
          logoAsset: 'assets/images/aggregators/box_novel.png',
          tabCategories: ['Updated', 'Popular'],
          genres: [
            'Action',
            'Adventure',
            'Comedy',
            'Drama',
            'Ecchi',
            'Fantasy',
            'Gender Bender',
            'Harem',
            'Historical',
            'Horror',
            'Josei',
            'Martial Arts',
            'Mature',
            'Mecha',
            'Mystery',
            'Psychological',
            'Romance',
            'School Life',
            'Sci-fi',
            'Seinen',
            'Shoujo',
            'Shounen',
            'Slice of Life',
            'Smut',
            'Sports',
            'Supernatural',
            'Tragedy',
            'Wuxia',
            'Xianxia',
            'Xuanhuan',
            'Yaoi',
          ],
        );

  @override
  Future<String> fetchPreviews() {
    return readFromView(baseURL);
  }

  @override
  Future<String> fetchEntry(LNPreview preview) {
    return readFromView(preview.link);
  }

  @override
  Future<String> search(String query, List<String> genre) {
    String searchSlug = '/?post_type=wp-manga&m_orderby=views';
    if (query != null) {
      searchSlug += '&s=$query';
    }
    if (genre != null && genre.isNotEmpty) {
      genre.forEach((g) => searchSlug += '&genre%5B%5D=$g');
    }
    final searchURL = mkurl(searchSlug);
    return readFromView(searchURL);
  }

  @override
  Map<String, List<LNPreview>> parsePreviews(String html) {
    // sadly LNPreview#genres will not be filled for this site as
    // they do not include it on their home page

    final document = parse(html);
    final updated = <LNPreview>[];
    final popular = <LNPreview>[];

    // Get the queries for updated and popular
    final updatedItems = document.querySelectorAll(
      'div[class*="page-item-detail"] div[id^="manga-item-"]',
    );

    final popularItems = document.querySelectorAll(
      'div[class*="popular-item-wrap"]',
    );

    // Fill updated items array
    updatedItems.forEach((item) {
      final anchor = item.querySelector('a');
      final cover = item.querySelector('a > img');

      if (anchor != null && cover != null) {
        final preview = LNPreview();
        preview.sourceId = this.id;
        preview.link = mkurl(anchor.attributes['href']);
        preview.name = anchor.attributes['title'];
        preview.coverURL = proxiedImage(mkurl(cover.attributes['src']));
        updated.add(preview);
      }
    });

    // Fill popular items array
    popularItems.forEach((item) {
      final imgContainer = item.querySelector('div[class*="popular-img"]');
      if (imgContainer != null) {
        final anchor = imgContainer.querySelector('a');
        final cover = imgContainer.querySelector('a > img');
        if (anchor != null && cover != null) {
          final preview = LNPreview();
          preview.sourceId = this.id;
          preview.link = mkurl(anchor.attributes['href']);
          preview.name = anchor.attributes['title'];
          preview.coverURL = proxiedImage(mkurl(cover.attributes['src']));
          popular.add(preview);
        }
      }
    });

    return {
      // Updated
      tabCategories[0]: updated,
      // Popular
      tabCategories[1]: popular,
    };
  }

  @override
  LNEntry parseEntry(LNSource source, String html) {
    // Setup data
    final document = parse(html);
    final entry = LNEntry();

    // Set entry source
    entry.sourceId = source.id;

    // Setup main queries
    final content = document.querySelector(
      'div[class*="post-content"]',
    );
    final summaries = document.querySelectorAll(
      'div[class*="post-status"] div[class*="summary-content"]',
    );
    final description = document.querySelector('div[id="editdescription"]');
    final chapters = document.querySelectorAll('li[class*="wp-manga-chapter"]');

    // Parse popularity/aliases/authors/genres
    if (content != null) {
      // Setup data queries
      final info = content.querySelectorAll(
        'div[class*="post-content_item"] div[class*="summary-content"]',
      );
      // Parse info data
      if (info != null && info.length >= 6) {
        try {
          entry.ranking = RegExp(r'(\b[0-9]+\b)').firstMatch(info[1].text.trim()).group(1);
        } catch (err) {
          entry.ranking = 'N/A';
        }
        entry.aliases =
            info[2].text.trim().split(',').map((x) => x.trim()).toList();
        entry.authors =
            info[3].text.trim().split(',').map((x) => x.trim()).toList();
        entry.genres =
            info[5].text.trim().split(',').map((x) => x.trim()).toList();
      }
    }

    // Parse release/status data
    if (summaries != null && summaries.length >= 2) {
      entry.releaseDate = summaries[0].text.trim();
      entry.status = summaries[1].text.trim();
    }

    // Parse description
    if (description != null) {
      entry.description = description.text.trim();
    }

    // Parse chapters
    if (chapters != null) {
      int idx = 0;
      chapters.forEach((chElement) {
        final chapter = LNChapter();

        final anchor = chElement.querySelector('a');
        final release = chElement.querySelector(
          'span[class*="chapter-release-date"]',
        );

        chapter.sourceId = source.id;
        chapter.index = idx;

        if (anchor != null) {
          chapter.link = mkurl(anchor.attributes['href']);
          chapter.title = anchor.text.trim();
        }

        if (release != null) {
          chapter.date = release.text.trim();
        }

        entry.chapters.add(chapter);
        idx++;
      });
    }
    return entry;
  }

  @override
  List<LNPreview> parseSearchPreviews(String html) {
    final previews = <LNPreview>[];
    final document = parse(html);
    final container = document.querySelectorAll('div[class*="c-tabs-item__content"] div[class*="c-image-hover"]');
    if (container != null) {
      container.forEach((containerElement) {
        final anchor = containerElement.querySelector('a');
        final cover = containerElement.querySelector('a > img');
        if (anchor != null && cover != null) {
          final preview = LNPreview();
          preview.sourceId = this.id;
          preview.link = mkurl(anchor.attributes['href']);
          preview.name = anchor.attributes['title'];
          preview.coverURL = proxiedImage(mkurl(cover.attributes['src']));
          previews.add(preview);
        }
      });
    }
    return previews;
  }

  @override
  String makeReaderContent(String chapterHTML) {
    final document = parse(chapterHTML);
    print('parsed reader document...');
    final content = document.querySelector('div[class*="read-container"]');
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
