import 'dart:async';
import 'package:html/parser.dart';
import 'package:ln_reader/novel/struct/ln_chapter.dart';
import 'package:ln_reader/novel/struct/ln_entry.dart';
import 'package:ln_reader/novel/struct/ln_preview.dart';
import 'package:ln_reader/novel/struct/ln_source.dart';
import 'package:ln_reader/util/string_normalizer.dart';

class NovelPlanet extends LNSource {
  NovelPlanet()
      : super(
          id: 'novel_planet',
          name: 'Novel Planet',
          baseURL: 'https://novelplanet.com/',
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
  Future<Map<String, List<LNPreview>>> parsePreviews() =>
      readFromView(this.baseURL).then((html) {
        if (html == null) {
          print('[parsePreviews] Failed to get previews for ${this.baseURL}');
          return null;
        } else {
          print('[parsePreviews] HTML read successfully');
          final document = parse(html);
          final returnData = {
            tabCategories[0]: _parseTable(document.querySelector('#tab-1')),
            tabCategories[1]: _parseTable(document.querySelector('#tab-2')),
            tabCategories[2]: _parseTable(document.querySelector('#tab-3')),
          };
          print('[parsePreviews] parsed return data successfully');
          return returnData;
        }
      });

  @override
  Future<List<LNPreview>> search(String query, List<String> genre) {
    final List<String> args = [];
    if (query != null) {
      args.add('name=' + query);
    }
    if (genre != null && genre.isNotEmpty) {
      args.add(genre.join(','));
    }
    args.add('order=mostpopular');
    final searchURL = mkurl('NovelList?' + args.join('&'));
    return readFromView(searchURL).then((html) {
      if (html == null) {
        print('Failed to get search previews for $searchURL');
        return null;
      } else {
        return _parseTable(parse(html));
      }
    });
  }

  @override
  Future<LNEntry> parseEntry(LNPreview preview) =>
      readFromView(preview.link).then((html) {
        if (html == null) {
          print('Failed to get entry for ${preview.link}');
          return null;
        } else {
          print('Retrieved preview html..');
          final document = parse(html);
          final details = document.querySelector(
            'div[class*="post-contentDetails"]',
          );
          if (details != null) {
            print('DETAILS VALID');
            final paragraphs = details.querySelectorAll('p');
            if (paragraphs.length >= 6) {
              print('6 PARAGRAPHS VALID');
              final elTitle = paragraphs[0].querySelector('a[class*="title"]');
              final elOtherNames = paragraphs[1].querySelectorAll('a[title]');
              final elGenres = paragraphs[2].querySelectorAll('a[title]');
              final elAuthors = paragraphs[3].querySelectorAll('a[title]');
              final elStatus = paragraphs[4].querySelector('a');
              final elTranslator = paragraphs[5].querySelector('a');
              final elDescription =
                  details.nextElementSibling.nextElementSibling;
              final elExtras = details.querySelectorAll(
                'div[class*="divReplaceP"] span[class*="infoLabel"]',
              );
              if (![
                elTitle,
                elOtherNames,
                elGenres,
                elAuthors,
                elStatus,
                elTranslator,
                elDescription,
                elExtras,
              ].contains(null)) {
                print('ARRAY ELEMENT VALID');
                final entry = LNEntry();
                entry.source = preview.source;
                entry.name = StringNormalizer.normalize(elTitle.text, true);
                entry.aliases.addAll(elOtherNames.map((n) => n.text));
                entry.genres.addAll(elGenres.map((g) => g.text));
                entry.authors.addAll(elAuthors.map((a) => a.text));
                entry.status = elStatus.text;
                entry.translator = elTranslator.text;
                entry.description = elDescription.text.trim();
                if (elExtras.length >= 2) {
                  final textNode0 = elExtras[0].parent.nodes.last;
                  final textNode1 = elExtras[1].parent.nodes.last;
                  if (textNode0 != null) {
                    entry.releaseDate =
                        StringNormalizer.normalize(textNode0.text, true)
                            .replaceAll('(', '')
                            .replaceAll(')', '');
                  }
                  if (textNode1 != null) {
                    entry.popularity = int.parse(
                      StringNormalizer.normalize(textNode1.text, true),
                    );
                  }
                }
                final elChapters = document.querySelectorAll(
                  'div[class*="rowChapter"] a[title]',
                );
                elChapters.forEach((elChapter) {
                  final chapter = LNChapter();
                  chapter.source = preview.source;
                  chapter.index = entry.chapters.length;
                  chapter.title =
                      StringNormalizer.normalize(elChapter.text, true);
                  chapter.link = mkurl(elChapter.attributes['href']);
                  final elNext = elChapter.nextElementSibling;
                  if (elNext.className.contains('date')) {
                    chapter.date = StringNormalizer.normalize(elNext.text, true)
                        .replaceAll('(', '')
                        .replaceAll(')', '');
                  }
                  entry.chapters.add(chapter);
                });
                return entry;
              } else {
                print('ARRAY ELEMENT NULL');
              }
            } else {
              print('6 PARAGRAPHS NULL');
            }
          } else {
            print('DETAILS NULL');
            print(html);
          }
          return null;
        }
      });

  @override
  Future<String> makeReaderContent(LNChapter chapter) =>
      readFromView(chapter.link).then((html) {
        if (html == null) {
          print('Failed to get readable content for ${chapter.link}');
          return null;
        } else {
          final document = parse(html);
          print('parsed reader document...');
          final content = document.querySelector('#divReadContent').innerHtml;
          print('parsed reader document content.......');
          print('normalizing document reader...');
          String normalized = StringNormalizer.normalize(content);
          print('normalized...');
          return normalized;
        }
      });

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
        preview.source = this;
        preview.name = elTitle.text;
        preview.link = mkurl(elTitle.attributes['href']);
        preview.coverURL = proxiedImage(mkurl(elCover.attributes['src']));
        if (debug) {
          print(preview.name);
        }
        if (elGenres != null) {
          elGenres.forEach((genre) => preview.genres.add(genre.text));
        }
        previews.add(preview);
      }
    });
    return previews;
  }
}
