import 'package:html/parser.dart';
import 'package:ln_reader/novel/struct/ln_chapter.dart';
import 'package:ln_reader/novel/struct/ln_download.dart';
import 'package:ln_reader/novel/struct/ln_entry.dart';
import 'package:ln_reader/novel/struct/ln_preview.dart';
import 'package:ln_reader/novel/struct/ln_source.dart';
import 'package:ln_reader/util/net/dom_tool.dart';
import 'package:ln_reader/util/string_tool.dart';

class SkyNovels extends LNSource {
  SkyNovels()
      : super(
          id: 'sky_novels',
          name: 'Sky Novels',
          lang: 'ES',
          baseURL: 'https://skynovels.net',
          logoAsset: 'assets/images/aggregators/sky_novels.png',
          tabCategories: [
            'Últimas', // Latest (Updated)
            'Top', // This is what the site references as popular
          ],
          // Sadly this source does not have searching by genre
          genres: [],
        );

  @override
  Future<List<String>> fetchPreviews() async {
    return [
      await readFromView(baseURL),
    ];
  }

  @override
  Future<String> search(String query, List<String> genres) {
    return readFromView(mkurl('/?s=transform'));
  }

  @override
  Future<String> fetchEntry(LNPreview preview) {
    return readFromView(preview.link);
  }

  @override
  Map<String, List<LNPreview>> parsePreviews(List<String> html) {
    final document = parse(html.first);

    final updatedList = <LNPreview>[];
    final popularList = <LNPreview>[];

    final slides = document.querySelectorAll('div[class*="slick-track"]');

    if (slides != null && slides.length >= 2) {
      updatedList.addAll(_parseSlide(slides[1]));
      popularList.addAll(_parseSlide(slides[0]));
    }

    return {
      tabCategories[0]: updatedList,
      tabCategories[1]: popularList,
    };
  }

  List<LNPreview> _parseSlide(slide) {
    final list = <LNPreview>[];

    final anchors = slide.querySelectorAll('div[class*="slick-slide"][id] a');

    anchors.forEach((anchor) {
      String title;
      try {
        title = anchor.attributes['data-original-title']
            .split(r'<strong>')[1]
            .split(r'</strong>')[0]
            .trim();
      } catch (err) {
        print('Error parsing title');
        title = null;
      }
      if (title != null) {
        final preview = LNPreview();

        final cover = anchor.querySelector('img');

        preview.sourceId = this.id;
        preview.link = mkurl(anchor.attributes['href']);
        preview.name = title;

        if (cover != null) {
          preview.coverURL = mkurl(cover.attributes['src']);
        }

        list.add(preview);
      }
    });

    return list;
  }

  @override
  List<LNPreview> parseSearchPreviews(String html) {
    final list = <LNPreview>[];
    final document = parse(html);

    final items = document.querySelectorAll('#main > div');

    items.forEach((item) {
      final cover = item.querySelector('div > a > img');
      final anchor = item.querySelector('div > h3 > a');
      final genres = item.querySelectorAll('div > p > span[class*="btn"]');

      if (anchor != null) {
        final preview = LNPreview();

        preview.sourceId = this.id;

        preview.link = anchor.attributes['href'];
        preview.name = anchor.text.trim();

        if (cover != null) {
          preview.coverURL = cover.attributes['src'];
        }

        genres.forEach((g) => preview.data['genres'].add(g.text.trim()));

        list.add(preview);
      }
    });

    return list;
  }

  @override
  LNEntry parseEntry(LNSource source, String html) {
    final document = parse(html);
    final entry = LNEntry();

    final activeStatusLabel = document.querySelector(
      'span[class*="n-txt-activa"]',
    );
    final pausedStatusLabel = document.querySelector(
      'span[class*="n-txt-pausada"]',
    );

    final timeIcon = document.querySelector('i[class*="fa-hourglass"]');
    final rank = document.querySelector(
      'div[class*="gdrts-rating-text"] > strong',
    );

    final description = document.querySelectorAll(
      'div[class*="descriptionNovel"] > p',
    );
    final divs = document.querySelectorAll('div, strong');
    final chapters = document.querySelectorAll(
      'div[class*="card-body"] a[rel="bookmark"]',
    );

    if (activeStatusLabel != null) {
      entry.status = StringTool.properFormat(activeStatusLabel.text.trim());
    }

    if (pausedStatusLabel != null) {
      entry.status = StringTool.properFormat(pausedStatusLabel.text.trim());
    }

    if (timeIcon != null) {
      entry.lastUpdated = timeIcon.parent.text.trim();
    }

    if (rank != null) {
      entry.ranking = rank.text.trim() + '/5';
    }

    if (description != null && description.isNotEmpty) {
      entry.description = description.first.text.trim();
    }

    // Sadly there are no specific classes or IDs, so we have to
    // manually filter things out.
    divs.forEach((div) {
      div.nodes.forEach((node) {
        try {
          // Only look at text nodes
          if (node.nodeType == 3) {
            final txt = node.text;
            final lower = txt.trim().toLowerCase();
            if (lower.contains('autor:')) {
              entry.authors.add(DomTool.next(node.parentNode).text.trim());
            } else if (lower.contains('traductor:')) {
              entry.translator = DomTool.next(node.parentNode).text.trim();
            } else if (lower.contains('títulos alternativos:')) {
              entry.aliases.add(DomTool.next(
                node.parentNode,
                skip: 2,
              ).text.trim());
            } else if (lower.contains('géneros:')) {
              final genreTexts =
                  DomTool.next(node.parentNode).text.trim().split(',');
              entry.genres.addAll(genreTexts.map((g) => g.trim()));
            }
          }
        } catch (err) {
          print('Error handling info..');
        }
      });
    });

    int idx = 0;
    chapters.forEach((chElement) {
      final chapter = LNChapter();
      chapter.sourceId = source.id;
      chapter.index = (chapters.length - idx);
      chapter.link = mkurl(chElement.attributes['href']);
      chapter.title = chElement.text.trim();
      // sky novels is in standard order, we need descending
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
}
