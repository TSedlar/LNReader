import 'dart:async';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:ln_reader/novel/struct/ln_chapter.dart';
import 'package:ln_reader/novel/struct/ln_download.dart';
import 'package:ln_reader/novel/struct/ln_entry.dart';
import 'package:ln_reader/novel/struct/ln_preview.dart';
import 'package:ln_reader/novel/struct/ln_source.dart';
import 'package:ln_reader/util/net/webview_reader.dart';
import 'package:ln_reader/util/string_normalizer.dart';

class NovelPlanet extends LNSource {
  NovelPlanet()
      : super(
          id: 'novel_planet',
          name: 'Novel Planet',
          lang: 'EN',
          baseURL: 'https://novelplanet.com/',
          logoAsset: 'assets/images/aggregators/novel_planet.png',
          tabCategories: [
            'Updated',
            'New',
            'Popular',
          ],
          genres: [
            'Action',
            'Adult',
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
            'Lolicon',
            'Martial Arts',
            'Mature',
            'Mecha',
            'Mystery',
            'Psychological',
            'Romance',
            'School Life',
            'Sci-fi',
            'Seinen',
            'Shotacon',
            'Shoujo',
            'Shoujo Ai',
            'Shounen',
            'Shounen Ai',
            'Slice of Life',
            'Smut',
            'Sports',
            'Supernatural',
            'Tragedy',
            'Web Novel',
            'Wuxia',
            'Xianxia',
            'Xuanhaun',
            'Yaoi',
            'Yuri'
          ],
        );

  @override
  Future<String> fetchPreviews() {
    return readFromView(baseURL);
  }

  @override
  Map<String, List<LNPreview>> parsePreviews(String html) {
    print('[parsePreviews] parsing html...');
    // print(html); // debug...
    final document = parse(html);
    final returnData = {
      tabCategories[0]: _parseTable(document.querySelector('#tab-1')),
      tabCategories[1]: _parseTable(document.querySelector('#tab-2')),
      tabCategories[2]: _parseTable(document.querySelector('#tab-3')),
    };
    print('[parsePreviews] parsed return data successfully');
    return returnData;
  }

  @override
  Future<String> search(String query, List<String> genres) {
    final List<String> args = [];
    if (query != null) {
      args.add('name=' + query);
    }
    if (genres != null && genres.isNotEmpty) {
      args.add(genres.join(','));
    }
    args.add('order=mostpopular');
    final searchURL = mkurl('/NovelList?' + args.join('&'));
    return readFromView(searchURL);
  }

  @override
  List<LNPreview> parseSearchPreviews(String html) {
    return _parseTable(parse(html));
  }

  @override
  Future<String> fetchEntry(LNPreview preview) {
    return readFromView(preview.link);
  }

  @override
  LNEntry parseEntry(LNSource source, String html) {
    print('Retrieved preview html..');
    final document = parse(html);
    final details = document.querySelector(
      'div[class*="post-contentDetails"]',
    );
    if (details != null) {
      print('DETAILS VALID');
      final paragraphs = details.querySelectorAll('p');
      if (paragraphs.length >= 6 && !paragraphs.contains(null)) {
        print('6 PARAGRAPHS VALID');

        final elTitle = paragraphs[0].querySelector('a[class*="title"]');
        final elOtherNames = paragraphs[1].querySelectorAll('a[title]');
        final elGenres = paragraphs[2].querySelectorAll('a[title]');
        final elAuthors = paragraphs[3].querySelectorAll('a[title]');
        final elStatus = paragraphs[4].querySelector('a');
        final elTranslator = paragraphs[5].querySelector('a');
        final elDescription = details.nextElementSibling.nextElementSibling;
        final elExtras = details.querySelectorAll(
          'div[class*="divReplaceP"] span[class*="infoLabel"]',
        );

        final entry = LNEntry();

        entry.sourceId = source.id;

        if (elTitle != null) {
          entry.name = StringNormalizer.normalize(elTitle.text, true);
        }

        if (elOtherNames != null) {
          entry.aliases.addAll(elOtherNames.map((n) => n.text));
        }

        if (elGenres != null) {
          entry.genres.addAll(elGenres.map((g) => g.text));
        }

        if (elAuthors != null) {
          entry.authors.addAll(elAuthors.map((a) => a.text));
        }

        if (elStatus != null) {
          entry.status = elStatus.text;
        }

        if (elTranslator != null) {
          entry.translator = elTranslator.text;
        }

        if (elDescription != null) {
          entry.description = elDescription.text.trim();
        }

        if (elExtras != null && elExtras.length >= 2) {
          final textNode0 = elExtras[0].parent.nodes.last;
          final textNode1 = elExtras[1].parent.nodes.last;
          if (textNode0 != null) {
            entry.releaseDate = StringNormalizer.normalize(textNode0.text, true)
                .replaceAll('(', '')
                .replaceAll(')', '');
          }
          if (textNode1 != null) {
            entry.ranking = StringNormalizer.normalize(textNode1.text, true);
          }
        }

        final elChapters = document.querySelectorAll(
          'div[class*="rowChapter"] a[title]',
        );

        if (elChapters != null) {
          elChapters.forEach((elChapter) {
            final chapter = LNChapter();

            chapter.sourceId = source.id;
            chapter.index = entry.chapters.length;

            chapter.title = StringNormalizer.normalize(elChapter.text, true);

            chapter.link = mkurl(elChapter.attributes['href']);

            final elNext = elChapter.nextElementSibling;

            if (elNext != null && elNext.className.contains('date')) {
              chapter.date = StringNormalizer.normalize(elNext.text, true)
                  .replaceAll('(', '')
                  .replaceAll(')', '');
            }

            entry.chapters.add(chapter);
          });
        }
        return entry;
      } else {
        print('6 PARAGRAPHS NULL');
      }
    } else {
      print('DETAILS NULL');
      print(html);
    }
    return null;
  }

  @override
  String makeReaderContent(String chapterHTML) {
    final document = parse(chapterHTML);
    print('parsed reader document...');
    final content = document.querySelector('#divReadContent');
    if (content != null) {
      print('parsed reader document content.......');
      print('normalizing document reader...');
      String normalized = StringNormalizer.normalize(content.innerHtml);
      print('normalized...');
      return normalized;
    } else {
      return null;
    }
  }

  @override
  Future<LNDownload> handleNonTextDownload(
    LNPreview preview,
    LNChapter chapter,
  ) async {
    String lowTitle = chapter.title.toLowerCase();
    if (lowTitle.endsWith('.pdf')) {
      final html = await readFromView(chapter.link);
      if (html != null) {
        final document = parse(html);
        final pdfFrame = document.querySelector('#divReadContent iframe');
        String pdfURL = pdfFrame.attributes['src'];
        if (pdfURL.contains('drive.google.com')) {
          if (pdfURL.endsWith('/preview')) {
            pdfURL = pdfURL.substring(0, pdfURL.length - 7) + 'view';
          }
          String gdriveId =
              RegExp(r'/file/d/(.*)/[A-Za-z]').firstMatch(pdfURL)?.group(1);
          if (gdriveId != null) {
            pdfURL = 'https://drive.google.com/uc?id=$gdriveId&export=download';

            final res = await http.get(pdfURL, headers: {
              'User-Agent': WebviewReader.randomAgent(),
            });

            final download = LNDownload(type: LNDownloadType.PDF);

            download.pdfPath = download.fileFor(preview, chapter);
            await download.pdfPath.writeAsBytes(res.bodyBytes);

            return download;
          }
        } else {
          print('NovelPlanet only uses GDrive from what I know?');
          print('URL: $pdfURL');
        }
      }
    }
    return null;
  }

  List<LNPreview> _parseTable(dynamic parent, [bool debug = false]) {
    List<LNPreview> previews = [];
    if (parent == null) {
      return previews;
    }
    final articles = parent.querySelectorAll('article');
    if (debug) {
      print(articles);
    }
    articles.forEach((article) {
      final elTitle = article.querySelector(
        'div[class*="post-content"] a[class*="title"]',
      );
      final elCover = article.querySelector('div[class*="post-preview"] img');
      final elGenres = article.querySelectorAll(
        'div[class*="post-content"] a[title]',
      );
      if (elTitle != null && elCover != null) {
        final preview = LNPreview();

        preview.sourceId = this.id;
        preview.name = elTitle.text;
        preview.link = mkurl(elTitle.attributes['href']);
        preview.coverURL = proxiedImage(mkurl(elCover.attributes['src']));

        if (debug) {
          print(preview.name);
        }

        if (elGenres != null) {
          elGenres.forEach((genre) => preview.data['genres'].add(genre.text));
        }

        previews.add(preview);
      }
    });
    return previews;
  }
}
