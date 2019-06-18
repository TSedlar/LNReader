import 'package:html/parser.dart';
import 'package:ln_reader/novel/struct/ln_chapter.dart';
import 'package:ln_reader/novel/struct/ln_download.dart';
import 'package:ln_reader/novel/struct/ln_entry.dart';
import 'package:ln_reader/novel/struct/ln_preview.dart';
import 'package:ln_reader/novel/struct/ln_source.dart';
import 'package:ln_reader/util/net/article_parser.dart';
import 'package:ln_reader/util/string_tool.dart';

//
class Hako extends LNSource {
  static final Map<String, String> _genreMapping = {
    'Action': '1',
    'Adult': '28',
    'Adventure': '2',
    'Chinese Novel': '39',
    'Comedy': '3',
    'Cooking': '43',
    'Drama': '4',
    'Ecchi': '5',
    'English Novel': '40',
    'Fantasy': '6',
    'Game': '45',
    'Gender Bender': '7',
    'Harem': '8',
    'Historical': '35',
    'Horror': '9',
    'Incest': '10',
    'Isekai': '30',
    'Josei': '33',
    'Korean Novel': '34',
    'Magic': '44',
    'Martial Arts': '37',
    'Mature': '27',
    'Mecha': '11',
    'Military': '36',
    'Mystery': '12',
    'Netorare': '32',
    'One shot': '38',
    'Otome Game': '46',
    'Psychological': '23',
    'Romance': '22',
    'School Life': '13',
    'Science Fiction': '14',
    'Seinen': '31',
    'Shoujo': '15',
    'Shoujo ai': '16',
    'Shounen': '26',
    'Shounen ai': '17',
    'Slice of Life': '18',
    'Sports': '19',
    'Super Power': '24',
    'Supernatural': '20',
    'Suspense': '25',
    'Tragedy': '21',
    'Web Novel': '29',
  };

  Hako()
      : super(
          id: 'hako',
          name: 'Hako',
          lang: 'VI',
          baseURL: 'https://ln.hako.re',
          logoAsset: 'assets/images/aggregators/hako.png',
          tabCategories: [
            'Mới nhất', // Latest/Updated
            'Phổ biến', // Popular
          ],
          // Sadly the searching on this site is quite weird
          // and does not enable searching by "OR", but only by "AND"
          multiGenre: false,
          genres: _genreMapping.keys.toList(),
        );

  @override
  Future<List<String>> fetchPreviews() async {
    return [
      await readFromView(mkurl('/chuong-moi-nhat/tat-ca')),
      await readFromView(mkurl('/hot-trong-thang/tat-ca')),
    ];
  }

  @override
  Future<String> search(String query, List<String> genres) {
    if (query != null) {
      return readFromView(mkurl('/tim-kiem-nang-cao?title=$query'));
    } else {
      final genreId = _genreMapping[genres.first];
      return readFromView(mkurl('/tim-kiem-nang-cao?selectgenres=$genreId'));
    }
  }

  @override
  Future<String> fetchEntry(LNPreview preview) {
    return readFromView(preview.link);
  }

  @override
  Map<String, List<LNPreview>> parsePreviews(List<String> html) {
    final upDocument = parse(html[0]);
    final popDocument = parse(html[1]);

    final updateList = <LNPreview>[];
    final popularList = <LNPreview>[];

    final popItems = popDocument.querySelectorAll('tbody tr:not(:first-child)');

    // Handle updated items
    updateList.addAll(_parseList(upDocument));

    // Handle popular parsing
    int idx = 0;
    popItems.forEach((popItem) {
      // Account for table header
      if (idx > 0) {
        final preview = LNPreview();

        preview.sourceId = this.id;

        final anchor = popItem.querySelector('div[class*="series-name"] > a');
        final imgDiv = popItem.querySelector('div[class*="img-in-ratio"]');

        if (anchor != null) {
          preview.link = mkurl(anchor.attributes['href']);
          preview.name = anchor.text.trim();
        }

        if (imgDiv != null) {
          try {
            preview.coverURL = mkurl(imgDiv.attributes['style']
                .split('background-image: url(\'')[1]
                .split('\')')[0]);
          } catch (err) {
            print('error parsing cover image');
          }
        }

        popularList.add(preview);
      }
      idx++;
    });

    return {
      // Updated
      tabCategories[0]: updateList,
      // Popular
      tabCategories[1]: popularList,
    };
  }

  List<LNPreview> _parseList(document) {
    final list = <LNPreview>[];
    final upItems = document.querySelectorAll('article[class*="thumb-item"]');

    // Handle updated items
    upItems.forEach((upItem) {
      final preview = LNPreview();

      preview.sourceId = this.id;

      final anchor = upItem.querySelector('h5[class*="thumb_title"] > a');
      final coverImg = upItem.querySelector('a[class*="thumb_img"]');

      if (anchor != null) {
        preview.link = mkurl(anchor.attributes['href']);
        preview.name = anchor.text.trim();
      }

      if (coverImg != null) {
        try {
          preview.coverURL = mkurl(
            coverImg.attributes['style']
                .split('background: url(\'')[1]
                .split('\')')[0],
          );
        } catch (err) {
          print('err parsing cover image');
        }
      }

      list.add(preview);
    });
    return list;
  }

  @override
  List<LNPreview> parseSearchPreviews(String html) {
    final document = parse(html);
    return _parseList(document);
  }

  @override
  LNEntry parseEntry(LNSource source, String html) {
    final document = parse(html);
    final entry = LNEntry();

    final description = document.querySelector(
      'div[class*="summary-content"]',
    );
    final ranking = document.querySelector('span[class*="rating-avg-text"]');
    final infoItems = document.querySelectorAll(
      'main[class*="long-text"] div[class*="ln_info-item"]',
    );
    final volumes = document.querySelectorAll(
      'section[class*="volume-content"]',
    );

    entry.sourceId = source.id;

    if (description != null) {
      entry.description = description.text.trim();
    }

    if (ranking != null) {
      entry.ranking = ranking.text.trim() + '/5';
    }

    infoItems.forEach((infoItem) {
      final info = infoItem.querySelector('span[class*="ln_info-name"]');
      final data = infoItem.querySelector('span[class*="ln_info-value"]');
      if (info != null && data != null) {
        final infoKey = info.text.trim().toLowerCase();
        final dataValue = data.text.trim();
        if (infoKey.contains('lượt xem')) {
          entry.views = dataValue;
        } else if (infoKey.contains('tác giả')) {
          entry.authors.add(dataValue);
        } else if (infoKey.contains('tình trạng dịch')) {
          entry.status = dataValue;
        } else if (infoKey.contains('thể loại')) {
          entry.genres.addAll(dataValue.split(',').map((g) => g.trim()));
        }
      }
    });

    final allChapters = document.querySelectorAll('div[class*="chapter-name"]');

    print('chapter count -> ${allChapters.length}');

    int idx = 0;
    volumes.forEach((volElement) {
      final volumeName = volElement.querySelector(
        'header[class*="vol-header"] > span[class*="sect-title"]',
      );

      final chapters = volElement.querySelectorAll(
        'li > div[class*="chapter-name"] > a',
      );

      chapters.forEach((chElement) {
        final imgIcon = chElement.parent.querySelector(
          'i[class*="fa-picture-o"]',
        );

        // Only add if not an illustration page
        if (imgIcon == null) {
          final chapter = LNChapter();

          chapter.sourceId = source.id;
          chapter.index = (allChapters.length - idx);
          chapter.link = mkurl(chElement.attributes['href']);

          String title = chElement.text.trim();

          // Ensure we're not loading in the illustation chapter
          // Since we cannot display it.
          if (title.toLowerCase() != 'minh họa') {
            // Don't prepend volume if it's the only volume
            if (volumes.length > 1) {
              if (volumeName != null) {
                final volTxt = volumeName.text.trim();
                if (volTxt.contains(' - ')) {
                  title = volTxt.split(' - ')[0] + ': ' + title;
                } else {
                  title = volTxt + ': ' + title;
                }
              }
            }

            chapter.title = title;

            // Hako is in standard order, we need descending
            entry.chapters.insert(0, chapter);
          }
        }

        idx++;
      });
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
